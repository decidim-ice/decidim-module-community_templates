# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe GitSyncronizer do
      let(:git_mirror) { create(:git_mirror, :with_commit) }
      let(:git_instance) { git_mirror.open_git }
      let(:file_lock) { instance_double(FileLock) }
      let(:cache) { instance_double(SyncCache) }
      let(:logger) { instance_double(ActiveSupport::Logger) }
      let(:public_files_reloader) { instance_double(PublicFilesReloader) }
      let(:invalid_models_cleaner) { instance_double(InvalidModelsCleaner) }
      let(:apartment_strategy) { instance_double(SingleTenantStrategy) }
      let(:job_class) { class_double(ResetOrganizationJob) }

      before do
        # Mock GitCatalogNormalizer and ResetOrganization
        allow(GitCatalogNormalizer).to receive(:call).and_return({ ok: true })
        allow(ResetOrganization).to receive(:call).and_return({ ok: true })

        # Mock GitMirror.instance methods
        allow(GitMirror).to receive(:instance).and_return(git_mirror)
        allow(git_mirror).to receive(:pull!).and_return(true)
        allow(git_mirror).to receive(:last_commit).and_return("abc123")
        allow(git_mirror).to receive(:transaction).and_yield(git_instance)

        # Mock git instance methods to prevent network calls
        allow(git_instance).to receive(:pull).and_return(true)
        allow(git_instance).to receive(:add).and_return(true)
        allow(git_instance).to receive(:commit).and_return(true)
        allow(git_instance).to receive(:status).and_return(double("status", changed: [], added: [], deleted: [], untracked: []))
        allow(git_instance).to receive(:log).and_return(double("log", execute: [double("commit", message: "test commit")]))

        # Mock file lock
        allow(file_lock).to receive(:with_lock).and_yield(true)

        # Mock cache
        allow(cache).to receive(:last_commit).and_return(nil)
        allow(cache).to receive(:update_last_commit)

        # Mock logger
        allow(logger).to receive(:info)
        allow(logger).to receive(:error)

        # Mock service objects
        allow(public_files_reloader).to receive(:call)
        allow(invalid_models_cleaner).to receive(:call)
        allow(apartment_strategy).to receive(:each_tenant).and_yield

        # Mock job class
        allow(job_class).to receive(:perform_later)

        CommunityTemplates.configure do |config|
          config.git_settings[:url] = git_mirror.repo_url
          config.git_settings[:branch] = git_mirror.repo_branch
          config.git_settings[:username] = git_mirror.repo_username
          config.git_settings[:password] = git_mirror.repo_password
          config.git_settings[:author_name] = git_mirror.repo_author_name
          config.git_settings[:author_email] = git_mirror.repo_author_email
        end
      end

      describe "#call" do
        context "when git URL is not configured" do
          before do
            CommunityTemplates.configure do |config|
              config.git_settings[:url] = nil
            end
          end

          it "does not call GitCatalogNormalizer" do
            described_class.new(
              git_mirror: git_mirror,
              file_lock: file_lock,
              cache: cache,
              logger: logger,
              public_files_reloader: public_files_reloader,
              invalid_models_cleaner: invalid_models_cleaner,
              apartment_strategy: apartment_strategy,
              job_class: job_class
            ).call
            expect(GitCatalogNormalizer).not_to have_received(:call)
          end

          it "does not pull from remote" do
            described_class.new(
              git_mirror: git_mirror,
              file_lock: file_lock,
              cache: cache,
              logger: logger,
              public_files_reloader: public_files_reloader,
              invalid_models_cleaner: invalid_models_cleaner,
              apartment_strategy: apartment_strategy,
              job_class: job_class
            ).call
            expect(git_mirror).not_to have_received(:pull!)
          end

          it "does not call last_commit" do
            described_class.new(
              git_mirror: git_mirror,
              file_lock: file_lock,
              cache: cache,
              logger: logger,
              public_files_reloader: public_files_reloader,
              invalid_models_cleaner: invalid_models_cleaner,
              apartment_strategy: apartment_strategy,
              job_class: job_class
            ).call
            expect(git_mirror).not_to have_received(:last_commit)
          end
        end

        context "when file lock cannot be acquired" do
          before do
            allow(file_lock).to receive(:with_lock).and_yield(false)
          end

          it "logs that sync is already running" do
            described_class.new(
              git_mirror: git_mirror,
              file_lock: file_lock,
              cache: cache,
              logger: logger,
              public_files_reloader: public_files_reloader,
              invalid_models_cleaner: invalid_models_cleaner,
              apartment_strategy: apartment_strategy,
              job_class: job_class
            ).call
            expect(logger).to have_received(:info).with("GitSyncronizer already running, skipping")
          end

          it "does not perform sync" do
            described_class.new(
              git_mirror: git_mirror,
              file_lock: file_lock,
              cache: cache,
              logger: logger,
              public_files_reloader: public_files_reloader,
              invalid_models_cleaner: invalid_models_cleaner,
              apartment_strategy: apartment_strategy,
              job_class: job_class
            ).call
            expect(GitCatalogNormalizer).not_to have_received(:call)
          end
        end

        context "when there are untracked files" do
          before do
            allow(git_mirror).to receive(:pull!).and_raise(GitError, "catalog dirty, commit or stash changes to continue")
          end

          it "raises a GitError" do
            expect do
              described_class.new(
                git_mirror: git_mirror,
                file_lock: file_lock,
                cache: cache,
                logger: logger,
                public_files_reloader: public_files_reloader,
                invalid_models_cleaner: invalid_models_cleaner,
                apartment_strategy: apartment_strategy,
                job_class: job_class
              ).call
            end.to raise_error(GitError)
          end
        end

        context "when GitCatalogNormalizer returns invalid" do
          before do
            allow(GitCatalogNormalizer).to receive(:call).and_return({ invalid: "error message" })
          end

          it "logs error and does not sync" do
            described_class.new(
              git_mirror: git_mirror,
              file_lock: file_lock,
              cache: cache,
              logger: logger,
              public_files_reloader: public_files_reloader,
              invalid_models_cleaner: invalid_models_cleaner,
              apartment_strategy: apartment_strategy,
              job_class: job_class
            ).call
            expect(logger).to have_received(:error).with("Can not sync")
            expect(git_mirror).not_to have_received(:pull!)
          end
        end

        context "when there are no untracked files" do
          before do
            allow(GitTransaction).to receive(:perform).and_yield(git_instance)
            allow(git_instance).to receive(:status).and_return(
              double("status",
                     changed: [],
                     added: [],
                     deleted: [],
                     untracked: [])
            )
          end

          it "calls GitCatalogNormalizer" do
            described_class.new(
              git_mirror: git_mirror,
              file_lock: file_lock,
              cache: cache,
              logger: logger,
              public_files_reloader: public_files_reloader,
              invalid_models_cleaner: invalid_models_cleaner,
              apartment_strategy: apartment_strategy,
              job_class: job_class
            ).call
            expect(GitCatalogNormalizer).to have_received(:call)
          end

          it "calls invalid_models_cleaner" do
            described_class.new(
              git_mirror: git_mirror,
              file_lock: file_lock,
              cache: cache,
              logger: logger,
              public_files_reloader: public_files_reloader,
              invalid_models_cleaner: invalid_models_cleaner,
              apartment_strategy: apartment_strategy,
              job_class: job_class
            ).call
            expect(invalid_models_cleaner).to have_received(:call)
          end

          it "pulls from remote repository" do
            described_class.new(
              git_mirror: git_mirror,
              file_lock: file_lock,
              cache: cache,
              logger: logger,
              public_files_reloader: public_files_reloader,
              invalid_models_cleaner: invalid_models_cleaner,
              apartment_strategy: apartment_strategy,
              job_class: job_class
            ).call
            expect(git_mirror).to have_received(:pull!)
          end

          it "calls last_commit" do
            described_class.new(
              git_mirror: git_mirror,
              file_lock: file_lock,
              cache: cache,
              logger: logger,
              public_files_reloader: public_files_reloader,
              invalid_models_cleaner: invalid_models_cleaner,
              apartment_strategy: apartment_strategy,
              job_class: job_class
            ).call
            expect(git_mirror).to have_received(:last_commit)
          end

          context "when last commit changed" do
            before do
              allow(cache).to receive(:last_commit).and_return("old_commit")
              allow(git_mirror).to receive(:last_commit).and_return("new_commit")
            end

            it "reloads public files" do
              described_class.new(
                git_mirror: git_mirror,
                file_lock: file_lock,
                cache: cache,
                logger: logger,
                public_files_reloader: public_files_reloader,
                invalid_models_cleaner: invalid_models_cleaner,
                apartment_strategy: apartment_strategy,
                job_class: job_class
              ).call
              expect(public_files_reloader).to have_received(:call)
            end

            it "enqueues reset organization job" do
              described_class.new(
                git_mirror: git_mirror,
                file_lock: file_lock,
                cache: cache,
                logger: logger,
                public_files_reloader: public_files_reloader,
                invalid_models_cleaner: invalid_models_cleaner,
                apartment_strategy: apartment_strategy,
                job_class: job_class
              ).call
              expect(job_class).to have_received(:perform_later)
            end

            it "updates cache with new commit" do
              described_class.new(
                git_mirror: git_mirror,
                file_lock: file_lock,
                cache: cache,
                logger: logger,
                public_files_reloader: public_files_reloader,
                invalid_models_cleaner: invalid_models_cleaner,
                apartment_strategy: apartment_strategy,
                job_class: job_class
              ).call
              expect(cache).to have_received(:update_last_commit).with("new_commit")
            end
          end

          context "when last commit unchanged" do
            before do
              allow(cache).to receive(:last_commit).and_return("abc123")
              allow(git_mirror).to receive(:last_commit).and_return("abc123")
            end

            it "does not reload public files" do
              described_class.new(
                git_mirror: git_mirror,
                file_lock: file_lock,
                cache: cache,
                logger: logger,
                public_files_reloader: public_files_reloader,
                invalid_models_cleaner: invalid_models_cleaner,
                apartment_strategy: apartment_strategy,
                job_class: job_class
              ).call
              expect(public_files_reloader).not_to have_received(:call)
            end

            it "does not enqueue reset organization job" do
              described_class.new(
                git_mirror: git_mirror,
                file_lock: file_lock,
                cache: cache,
                logger: logger,
                public_files_reloader: public_files_reloader,
                invalid_models_cleaner: invalid_models_cleaner,
                apartment_strategy: apartment_strategy,
                job_class: job_class
              ).call
              expect(job_class).not_to have_received(:perform_later)
            end
          end

          it "does not create commit" do
            described_class.new(
              git_mirror: git_mirror,
              file_lock: file_lock,
              cache: cache,
              logger: logger,
              public_files_reloader: public_files_reloader,
              invalid_models_cleaner: invalid_models_cleaner,
              apartment_strategy: apartment_strategy,
              job_class: job_class
            ).call
            expect(git_instance).not_to have_received(:add)
            expect(git_instance).not_to have_received(:commit)
          end
        end

        context "with default dependencies (backward compatibility)" do
          before do
            allow(FileLock).to receive(:new).and_return(file_lock)
            allow(SyncCache).to receive(:new).and_return(cache)
            allow(PublicFilesReloader).to receive(:new).and_return(public_files_reloader)
            allow(InvalidModelsCleaner).to receive(:new).and_return(invalid_models_cleaner)
            allow(ApartmentStrategy).to receive(:for).and_return(apartment_strategy)
            allow(Rails.cache).to receive(:read).and_return(nil)
            allow(Rails.cache).to receive(:write)
            allow(Rails.logger).to receive(:info)
            allow(Rails.logger).to receive(:error)
            allow(Rails.public_path).to receive(:join).with("catalog").and_return(Pathname.new("/tmp/public/catalog"))
          end

          it "works with default dependencies" do
            expect { described_class.call }.not_to raise_error
          end
        end
      end
    end
  end
end

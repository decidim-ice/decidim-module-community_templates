# frozen_string_literal: true

namespace :decidim do
  namespace :community_templates do
    desc "Check catalog status - git state, credentials, template count, and normalization"
    task status: :environment do
      StatusChecker.new.call
    end
  end
end

class StatusChecker
  def initialize
    setup_logging
    @git_mirror = Decidim::CommunityTemplates::GitMirror.instance
  end

  def call
    return unless configured?

    status_data = {
      git_status: check_git_status,
      git_mode: check_git_mode,
      templates: check_template_count,
      normalization: check_normalization,
      demo: check_demo_status
    }

    print_summary(status_data)
    exit 1 unless status_data[:normalization][:healthy]
  end

  private

  attr_reader :git_mirror

  def setup_logging
    $stdout.sync = true
    $stderr.sync = true
    Rails.logger = ActiveSupport::Logger.new($stdout)
    Rails.logger.level = Logger::INFO
  end

  def configured?
    return true if git_mirror.configured?

    Rails.logger.error "Git mirror is not configured"
    false
  end

  def check_git_status
    return { initialized: false } unless git_repo_exists?

    git = git_mirror.open_git
    status = git.status
    has_changes = any_changes?(status)

    log_git_changes(status) if has_changes
    Rails.logger.info has_changes ? "Git repository has uncommitted changes" : "Git repository is clean (no pending commits)"

    { initialized: true, has_changes: has_changes }
  rescue StandardError => e
    Rails.logger.error "Error checking git status: #{e.message}"
    { initialized: true, error: e.message }
  end

  def git_repo_exists?
    git_mirror.catalog_path.exist? && git_mirror.catalog_path.join(".git").exist?
  end

  def any_changes?(status)
    status.changed.any? || status.added.any? || status.deleted.any? || status.untracked.any?
  end

  def log_git_changes(status)
    Rails.logger.warn "Git repository has uncommitted changes:"
    status.changed.each { |file, _| Rails.logger.warn "  modified: #{file}" }
    status.added.each { |file, _| Rails.logger.warn "  added: #{file}" }
    status.deleted.each { |file, _| Rails.logger.warn "  deleted: #{file}" }
    status.untracked.each { |file| Rails.logger.warn "  untracked: #{file}" }
  end

  def check_git_mode
    has_credentials = git_mirror.repo_username.present? || git_mirror.repo_password.present?
    mode = has_credentials ? "read/write" : "read only"
    Rails.logger.info "Catalog access: #{mode}#{has_credentials ? " enabled" : " (no credentials defined)"}"
    mode
  end

  def check_template_count
    count = git_mirror.catalog_path.exist? ? git_mirror.templates_count : 0
    Rails.logger.info "Templates available: #{count}"
    count
  end

  def check_normalization
    Rails.logger.info "Running catalog normalizer..."
    result = Decidim::CommunityTemplates::GitCatalogNormalizer.call
    healthy = result.has_key?(:ok)

    if healthy
      Rails.logger.info "Catalog normalization completed successfully"
    else
      Rails.logger.error "Catalog normalization failed: #{result[:invalid]}"
    end

    { healthy: healthy, status: healthy ? "healthy" : "unhealthy" }
  end

  def check_demo_status
    host = Decidim::CommunityTemplates.config.demo[:host]
    enabled = demo_enabled?(host)
    enabled ? "enabled (https://#{host})" : "disabled"
  end

  def demo_enabled?(host)
    if Decidim::CommunityTemplates.apartment_compat?
      Decidim::Apartment::DistributionKey.for_host(host).present?
    else
      Decidim::Organization.find_by(host: host).present?
    end
  end

  def print_summary(data)
    puts "\n#{"=" * 50}"
    puts "DECIDIM COMMUNITY TEMPLATES STATUS SUMMARY"
    puts "=" * 50
    printf format("%{label} %{status}\n", label: "Git:".ljust(20), status: data[:normalization][:status])
    printf format("%{label} %{mode}\n", label: "Git mode:".ljust(20), mode: data[:git_mode])
    printf format("%{label} %{count}\n", label: "Templates:".ljust(20), count: data[:templates])
    printf format("%{label} %{demo}\n", label: "Demo:".ljust(20), demo: data[:demo])
    puts "=" * 50
  end
end

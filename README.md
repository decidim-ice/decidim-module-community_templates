# Decidim::CommunityTemplates

[![[CI] Lint](https://github.com/decidim-ice/decidim-module-community_templates/actions/workflows/lint.yml/badge.svg)](https://github.com/decidim-ice/decidim-module-community_templates/actions/workflows/lint.yml)
[![[CI] Test](https://github.com/decidim-ice/decidim-module-community_templates/actions/workflows/test.yml/badge.svg)](https://github.com/decidim-ice/decidim-module-community_templates/actions/workflows/test.yml)
[![Maintainability](https://qlty.sh/gh/decidim-ice/projects/decidim-module-community_templates/maintainability.svg)](https://qlty.sh/gh/decidim-ice/projects/decidim-module-community_templates)
[![codecov](https://codecov.io/gh/decidim-ice/decidim-module-community_templates/graph/badge.svg?token=zDjnsb0GGe)](https://codecov.io/gh/decidim-ice/decidim-module-community_templates)
[![Gem Version](https://badge.fury.io/rb/decidim-community_templates.svg)](https://badge.fury.io/rb/decidim-community_templates)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "decidim-community_templates", github: "decidim-ice/decidim-module-community_templates"
```

Install dependencies:

```
bundle
bin/rails decidim:upgrade
bin/rails db:migrate
```

The module uses a Git repository to store and distribute templates. The repository acts as a catalog where templates are versioned, shared, and synchronized across Decidim instances.

**Read-only mode** (pull templates only):
- Set `TEMPLATE_GIT_URL` to your public repository URL
- The module will clone and periodically sync templates from the repository

**Write mode** (publish templates):
- Set `TEMPLATE_GIT_URL` to your repository URL
- Set `TEMPLATE_GIT_USERNAME` and `TEMPLATE_GIT_PASSWORD` with credentials that have write access
- Templates created in the admin interface will be automatically committed and pushed to the repository


### GitLab Setup

For GitLab repositories (public repository with project credentials):

1. Create a GitLab project access token:
   - Go to your GitLab project → Settings → Access Tokens
   - Create a token with `write_repository` scope
   - Copy the token value

2. Configure environment variables:

```bash
export TEMPLATE_GIT_URL="https://gitlab.com/your-org/your-template-catalog.git"
export TEMPLATE_GIT_BRANCH="main"
export TEMPLATE_GIT_USERNAME="your-username"
export TEMPLATE_GIT_PASSWORD="your-project-access-token"
export TEMPLATE_GIT_AUTHOR_NAME="Decidim Community Templates"
export TEMPLATE_GIT_AUTHOR_EMAIL="templates@example.org"
```

3. Restart your application. The module will:
   - Clone the repository if it doesn't exist
   - Normalize the repository structure (create `manifest.json` if needed)
   - Periodically sync templates from the remote repository

### Demo Tenant Setup

The demo tenant is a special organization used to preview and test templates before publishing them to the catalog.

Configure via environment variables:

```bash
export TEMPLATE_DEMO_HOST="demo.localhost"
export TEMPLATE_DEMO_NAME="Demo Organization"
export TEMPLATE_DEMO_DEFAULT_LOCALE="en"
export TEMPLATE_DEMO_PRIMARY_COLOR="#14342B"
export TEMPLATE_DEMO_SECONDARY_COLOR="#006482"
export TEMPLATE_DEMO_TERTIARY_COLOR="#F7E733"
```

Reset the demo organization (purges and recreates with imported templates):

```bash
bin/rails decidim:community_templates:reset_demo
```

Drop the demo organization:

```bash
bin/rails decidim:community_templates:drop_demo
```

The demo organization is automatically reset when templates are synced from the Git repository.

## Rake Tasks

| Task | Description |
|------|-------------|
| `rails decidim:community_templates:reset_demo` | Reset demo organizations - purge and recreate template demo organizations with imported templates |
| `rails decidim:community_templates:drop_demo` | Drop demo organization and all associated data |
| `rails decidim:community_templates:status` | Check catalog status - git state, credentials, template count, and normalization |
| `rails decidim:update` | Automatically install community_templates migrations |

## Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `TEMPLATE_GIT_URL` | Git repository URL for the template catalog | `""` | Yes (for read/write mode) |
| `TEMPLATE_GIT_BRANCH` | Git branch to use | `"main"` | No |
| `TEMPLATE_GIT_USERNAME` | Git username for write access | `""` | Yes (for write mode) |
| `TEMPLATE_GIT_PASSWORD` | Git password/token for write access | `""` | Yes (for write mode) |
| `TEMPLATE_GIT_AUTHOR_NAME` | Git commit author name | `"Decidim Community Templates"` | No |
| `TEMPLATE_GIT_AUTHOR_EMAIL` | Git commit author email | `"decidim-community-templates@example.org"` | No |
| `TEMPLATE_DEMO_HOST` | Hostname for the demo organization | `"demo.localhost"` | No |
| `TEMPLATE_DEMO_NAME` | Name of the demo organization | `"Demo Organization"` | No |
| `TEMPLATE_DEMO_DEFAULT_LOCALE` | Default locale for demo organization | `DECIDIM_DEFAULT_LOCALE` or `"en"` | No |
| `TEMPLATE_DEMO_PRIMARY_COLOR` | Primary color for demo organization | `"#14342B"` | No |
| `TEMPLATE_DEMO_SECONDARY_COLOR` | Secondary color for demo organization | `"#006482"` | No |
| `TEMPLATE_DEMO_TERTIARY_COLOR` | Tertiary color for demo organization | `"#F7E733"` | No |



## Supported Features

The module currently supports exporting and importing:

- **Participatory Processes**: Full process structure including metadata, dates, and configuration
- **Process Steps**: All step configurations and settings
- **Proposals**: Proposal states and proposals (in demo mode)
- **Component Settings**: Global settings, step-specific settings, and default step settings
- **Images**: Hero images, attachments, and editor images
- **Content Blocks**: Editor content blocks and page content
- **Surveys**: Survey components with questions and answer options

## Roadmap

The following features are planned for future releases:

- **Blogs and pages**: Blogs and pages component setup
- **Meetings**: Meeting components and agendas
- **Meetings Polls**: Poll components and voting configurations
- **Meetings Agendas**: Meeting agendas and agenda items


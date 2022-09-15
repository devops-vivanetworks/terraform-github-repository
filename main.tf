data "github_team" "team_ids" {
  for_each = var.repository_teams_permission
  slug     = each.key
}

resource "github_repository" "main" {
  name                        = var.name
  description                 = var.description
  homepage_url                = var.homepage_url
  private                     = var.private
  has_issues                  = var.has_issues
  has_wiki                    = var.has_wiki
  allow_merge_commit          = var.allow_merge_commit
  allow_squash_merge          = var.allow_squash_merge
  allow_rebase_merge          = var.allow_rebase_merge
  has_downloads               = var.has_downloads
  auto_init                   = var.auto_init
  gitignore_template          = var.gitignore_template
  license_template            = var.license_template
  default_branch              = var.default_branch
  archived                    = var.archived
  topics                      = var.topics
  delete_branch_on_merge      = var.delete_branch_on_merge
  squash_merge_commit_title   = var.squash_merge_commit_title
  squash_merge_commit_message = var.squash_merge_commit_message

  dynamic "template" {
    for_each = (var.template_repository != "") ? ["dummy"] : []
    content {
      owner      = var.template_owner
      repository = var.template_repository
    }
  }
}

resource "github_branch_protection" "main" {
  pattern                         = github_repository.main.default_branch
  repository_id                   = github_repository.main.node_id
  enforce_admins                  = var.enforce_admins
  require_conversation_resolution = var.require_conversation_resolution
  require_signed_commits          = var.require_signed_commits

  required_status_checks {
    strict   = var.force_pr_rebase
    contexts = var.status_checks_contexts
  }

  required_pull_request_reviews {
    dismiss_stale_reviews      = true
    require_code_owner_reviews = true
  }
}

resource "github_team_repository" "this" {
  for_each   = var.repository_teams_permission
  repository = github_repository.main.name
  team_id    = data.github_team.team_ids[each.key].id
  permission = each.value
}

resource "github_repository_collaborator" "this" {
  for_each   = var.repository_collaborators_permission
  repository = github_repository.main.name
  username   = each.key
  permission = each.value
}

resource "github_repository_autolink_reference" "this" {
  for_each            = var.github_repository_autolink_references
  repository          = github_repository.main.name
  key_prefix          = each.key
  target_url_template = each.value
}

resource "github_app_installation_repository" "this" {
  count              = length(var.github_app_installations)
  installation_id    = var.github_app_installations[count.index]
  repository         = github_repository.main.name
}

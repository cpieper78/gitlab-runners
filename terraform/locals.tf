locals {
  name = var.cluster_name

  default_tags = {
    "Project"   = var.cluster_name
    "ManagedBy" = "terraform"
    "Component" = "gitlab-runners"
  }

  tags = merge(local.default_tags, var.tags)

  runner_namespace            = "gitlab-runner"
  runner_service_account_name = "gitlab-runner"
}

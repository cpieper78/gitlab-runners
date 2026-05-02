resource "kubernetes_namespace_v1" "gitlab_runner" {
  metadata {
    name = local.runner_namespace
  }
}

resource "kubernetes_secret_v1" "gitlab_runner_token" {
  metadata {
    name      = "gitlab-runner-token"
    namespace = kubernetes_namespace_v1.gitlab_runner.metadata[0].name
  }

  data = {
    "runner-token" = var.gitlab_runner_token
  }

  type = "Opaque"
}

resource "helm_release" "gitlab_runner" {
  name       = "gitlab-runner"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab-runner"
  version    = var.gitlab_runner_chart_version
  namespace  = kubernetes_namespace_v1.gitlab_runner.metadata[0].name

  values = [
    templatefile("${path.module}/values/gitlab-runner.yaml.tftpl", {
      gitlab_url                     = var.gitlab_url
      runner_namespace               = local.runner_namespace
      runner_secret_name             = kubernetes_secret_v1.gitlab_runner_token.metadata[0].name
      service_account_name           = local.runner_service_account_name
      irsa_role_arn                  = module.runner_cache_irsa.iam_role_arn
      cache_bucket                   = aws_s3_bucket.runner_cache.bucket
      region                         = var.region
      concurrency                    = var.runner_concurrency
      session_server_hostname        = var.session_server_hostname
      session_server_timeout         = var.session_server_timeout
      session_server_source_cidrs    = var.session_server_source_cidrs
      session_server_certificate_arn = aws_acm_certificate_validation.session_server.certificate_arn
    })
  ]

  depends_on = [
    module.eks,
    helm_release.aws_load_balancer_controller,
    aws_acm_certificate_validation.session_server,
  ]
}

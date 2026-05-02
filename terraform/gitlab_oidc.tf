data "tls_certificate" "gitlab" {
  url = "${var.gitlab_url}/oauth/discovery/keys"
}

resource "aws_iam_openid_connect_provider" "gitlab" {
  url            = var.gitlab_url
  client_id_list = [var.gitlab_url]

  # Use the last cert in the chain (the CA root/intermediate) rather than the
  # leaf, which rotates frequently and would cause needless plan diffs and
  # transient OIDC failures.
  thumbprint_list = [
    data.tls_certificate.gitlab.certificates[length(data.tls_certificate.gitlab.certificates) - 1].sha1_fingerprint,
  ]

  tags = local.tags
}

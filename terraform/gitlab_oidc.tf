data "tls_certificate" "gitlab" {
  url = "${var.gitlab_url}/oauth/discovery/keys"
}

resource "aws_iam_openid_connect_provider" "gitlab" {
  url             = var.gitlab_url
  client_id_list  = [var.gitlab_url]
  thumbprint_list = [data.tls_certificate.gitlab.certificates[0].sha1_fingerprint]

  tags = local.tags
}

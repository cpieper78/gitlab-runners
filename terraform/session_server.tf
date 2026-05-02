resource "aws_acm_certificate" "session_server" {
  domain_name       = var.session_server_hostname
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

resource "aws_route53_record" "session_server_validation" {
  for_each = {
    for dvo in aws_acm_certificate.session_server.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "session_server" {
  certificate_arn         = aws_acm_certificate.session_server.arn
  validation_record_fqdns = [for r in aws_route53_record.session_server_validation : r.fqdn]
}

# The session_server NLB is provisioned by the gitlab-runner Helm chart's
# Service. Read the resulting Service back to discover the NLB's DNS name,
# then point the user-facing hostname at it via a CNAME (works for any
# subdomain and avoids brittle parsing of the NLB hostname into name+zone).
data "kubernetes_service_v1" "session_server" {
  metadata {
    name      = "${helm_release.gitlab_runner.name}-session-server"
    namespace = local.runner_namespace
  }

  depends_on = [helm_release.gitlab_runner]
}

locals {
  # helm_release waits for resources by default, but Service status.loadBalancer.ingress
  # population is asynchronous via the AWS Load Balancer Controller. Surface a clear
  # error if it isn't populated by apply-time so users know to re-run apply rather
  # than getting an opaque "invalid index" failure.
  session_server_lb_hostname = try(
    data.kubernetes_service_v1.session_server.status[0].load_balancer[0].ingress[0].hostname,
    null,
  )
}

resource "aws_route53_record" "session_server" {
  lifecycle {
    precondition {
      condition     = local.session_server_lb_hostname != null && local.session_server_lb_hostname != ""
      error_message = "session_server LoadBalancer Service has no ingress hostname yet. Wait ~60s for the AWS Load Balancer Controller to provision the NLB and re-run `terraform apply`."
    }
  }

  zone_id = var.route53_zone_id
  name    = var.session_server_hostname
  type    = "CNAME"
  ttl     = 60
  records = [local.session_server_lb_hostname]
}

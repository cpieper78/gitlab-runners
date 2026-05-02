resource "aws_security_group" "session_server" {
  name_prefix = "${local.name}-session-server-"
  description = "Ingress allow-list for the GitLab Runner session_server NLB. Attached to the NLB via the AWS Load Balancer Controller `aws-load-balancer-security-groups` annotation."
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.tags, {
    Name = "${local.name}-session-server"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "session_server" {
  for_each = toset(var.session_server_source_cidrs)

  security_group_id = aws_security_group.session_server.id
  description       = "GitLab.com egress to session_server"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443

  tags = local.tags
}

# AWS auto-creates an allow-all egress rule on every new security group.
# We rely on that default — adding an explicit aws_vpc_security_group_egress_rule
# with identical scope would collide with the implicit rule. Backend traffic
# (frontend SG → cluster SG on 8093/tcp) is managed separately by the AWS
# Load Balancer Controller's manage-backend-security-group-rules behavior.

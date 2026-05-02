output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "region" {
  description = "AWS region the cluster runs in."
  value       = var.region
}

output "update_kubeconfig_command" {
  description = "Run this to populate ~/.kube/config for the cluster."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}

output "runner_cache_bucket" {
  description = "Name of the S3 bucket used for the GitLab runner distributed cache."
  value       = aws_s3_bucket.runner_cache.bucket
}

output "session_server_url" {
  description = "Public HTTPS URL the runner advertises for the interactive web terminal."
  value       = "https://${var.session_server_hostname}"
}

output "session_server_security_group_id" {
  description = "ID of the security group attached to the session_server NLB; ingress is restricted to var.session_server_source_cidrs."
  value       = aws_security_group.session_server.id
}

output "gitlab_oidc_provider_arn" {
  description = "ARN of the GitLab OIDC IdP registered in AWS IAM."
  value       = aws_iam_openid_connect_provider.gitlab.arn
}

output "gitlab_ci_secrets_reader_role_arn" {
  description = "Set this as a CI/CD variable named AWS_SECRETS_ROLE_ARN in GitLab to let jobs assume it via id_tokens + secrets."
  value       = aws_iam_role.gitlab_ci_secrets_reader.arn
}

output "demo_secret_name" {
  description = "Name of the demo Secrets Manager secret (only when create_demo_secret = true)."
  value       = var.create_demo_secret ? aws_secretsmanager_secret.demo[0].name : null
}

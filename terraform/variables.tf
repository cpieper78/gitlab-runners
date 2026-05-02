variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name. Also used as a tag/name prefix."
  type        = string
  default     = "gitlab-runners"
}

variable "kubernetes_version" {
  description = "EKS control-plane Kubernetes version."
  type        = string
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_min_size" {
  description = "Minimum size for the managed node group."
  type        = number
  default     = 1
}

variable "node_desired_size" {
  description = "Desired size for the managed node group."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum size for the managed node group."
  type        = number
  default     = 4
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the EKS public API endpoint. Lock this down for production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "gitlab_url" {
  description = "Base URL of the GitLab instance the runners register against. Must match the iss/aud GitLab uses for OIDC tokens."
  type        = string
  default     = "https://gitlab.com"
}

variable "gitlab_runner_token" {
  description = "GitLab runner authentication token (glrt-...) issued in the GitLab UI."
  type        = string
  sensitive   = true
}

variable "gitlab_runner_chart_version" {
  description = "Pinned version of the gitlab/gitlab-runner Helm chart."
  type        = string
  default     = "0.66.0"
}

variable "runner_concurrency" {
  description = "Value for the runner's `concurrent` setting (max simultaneous jobs)."
  type        = number
  default     = 10
}

variable "cache_expiration_days" {
  description = "Lifecycle expiration (days) for objects in the S3 runner cache bucket."
  type        = number
  default     = 14
}

variable "session_server_hostname" {
  description = "Public DNS name for the runner session_server (e.g. runners.example.com). Must live in route53_zone_id."
  type        = string
}

variable "route53_zone_id" {
  description = "ID of the existing Route53 hosted zone that owns session_server_hostname."
  type        = string
}

variable "session_server_timeout" {
  description = "session_timeout (seconds) for the runner [session_server] block."
  type        = number
  default     = 1800
}

variable "session_server_source_cidrs" {
  description = "CIDRs permitted to reach the session_server NLB. Default 0.0.0.0/0; tighten to GitLab egress ranges in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "aws_load_balancer_controller_chart_version" {
  description = "Pinned version of the aws-load-balancer-controller Helm chart."
  type        = string
  default     = "1.8.1"
}

variable "gitlab_project_path" {
  description = "Full GitLab project path (e.g. mygroup/myrepo) used to scope the OIDC `sub` claim on the secrets-reader role."
  type        = string
}

variable "secrets_manager_secret_arns" {
  description = "Additional Secrets Manager ARNs the GitLab CI secrets-reader role can GetSecretValue on. The demo secret (if enabled) is added automatically."
  type        = list(string)
  default     = []
}

variable "create_demo_secret" {
  description = "When true, creates a sample Secrets Manager secret and grants the GitLab CI role access to it. Used by the example pipeline."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Extra tags merged with module defaults."
  type        = map(string)
  default     = {}
}

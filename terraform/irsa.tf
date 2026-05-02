data "aws_iam_policy_document" "runner_cache" {
  statement {
    sid    = "ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [aws_s3_bucket.runner_cache.arn]
  }

  statement {
    sid    = "ReadWriteObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.runner_cache.arn}/*"]
  }
}

resource "aws_iam_policy" "runner_cache" {
  name        = "${local.name}-runner-cache"
  description = "Allows the GitLab runner ServiceAccount to read/write the cache bucket."
  policy      = data.aws_iam_policy_document.runner_cache.json
  tags        = local.tags
}

module "runner_cache_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44"

  role_name = "${local.name}-runner-cache"

  role_policy_arns = {
    cache = aws_iam_policy.runner_cache.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.runner_namespace}:${local.runner_service_account_name}"]
    }
  }

  tags = local.tags
}

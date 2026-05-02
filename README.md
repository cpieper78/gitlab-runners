# gitlab-runners

Terraform that stands up an EKS cluster purpose-built for self-managed GitLab
runners registering against **GitLab.com SaaS**, with:

- VPC + EKS (managed node group) provisioned from `terraform-aws-modules/*`
- Distributed S3 runner cache, accessed by the runner pod via **IRSA** (no
  static AWS keys mounted into builds)
- `session_server` exposed publicly over HTTPS (NLB + ACM cert + Route53)
  so the GitLab UI's interactive web terminal works
- AWS Load Balancer Controller installed for the NLB+ACM annotations
- An AWS IAM **GitLab OIDC IdP** plus an IAM role GitLab CI jobs can assume
  via `id_tokens` + `secrets:` to fetch values from **AWS Secrets Manager**
  (no long-lived credentials in CI variables)
- A GitHub Actions workflow that runs `terraform fmt / validate / plan` on
  PRs (using GitHub OIDC; read-only IAM)
- A repo-root `.gitlab-ci.yml` that does the same on MRs (using GitLab OIDC)
- A demo `.gitlab-ci.yml` under `examples/` that exercises the cache, the
  matrix, the interactive web terminal, and the Secrets Manager flow

## Prerequisites

- An AWS account and credentials in your shell with permission to create
  IAM, VPC, EKS, S3, ACM, Route53, and Secrets Manager resources.
- A **Route53 hosted zone** you already own. The hostname you pick for
  `session_server_hostname` must live in this zone (e.g. zone
  `example.com` and hostname `runners.example.com`).
- A **GitLab runner authentication token** (`glrt-...`). Create one in
  GitLab UI → group/project/instance → Settings → CI/CD → Runners → "New
  runner". Note the runner's tag(s) — the demo pipeline expects `eks-runners`.
- A **GitLab project path** to scope the OIDC trust policy on the secrets-
  reader role (e.g. `mygroup/myrepo`).
- `terraform >= 1.6`, `aws-cli`, `kubectl`, `helm` installed locally.

## Bootstrap (state backend)

The repo ships with **local state** by default so `terraform apply` works
out of the box. To move to remote state on S3+DynamoDB:

1. Create the bucket and lock table once (replace names/regions):
   ```sh
   aws s3api create-bucket --bucket myorg-tfstate --region us-east-1
   aws s3api put-bucket-versioning --bucket myorg-tfstate \
     --versioning-configuration Status=Enabled
   aws dynamodb create-table --table-name myorg-tfstate-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST --region us-east-1
   ```
2. Uncomment the `backend "s3"` block in `terraform/backend.tf` and fill it.
3. `cd terraform && terraform init -migrate-state`.

## Apply

1. Copy the example tfvars and fill in the required values:
   ```sh
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # Edit terraform/terraform.tfvars
   ```
   Or set sensitive values via env:
   ```sh
   export TF_VAR_gitlab_runner_token=glrt-xxxxxxxx
   ```
2. Apply:
   ```sh
   cd terraform
   terraform init
   terraform apply
   ```
3. Configure kubectl from the `update_kubeconfig_command` output:
   ```sh
   $(terraform output -raw update_kubeconfig_command)
   kubectl -n gitlab-runner get pods
   ```

## Verifying the runner

- The runner pod logs should show
  `Registering runner... succeeded` and `Configuration loaded`.
- On gitlab.com the runner appears as **online** under the group/project
  it was registered against.
- Trigger a job tagged `eks-runners`; a build pod is scheduled in the
  cluster's `gitlab-runner` namespace.

## Verifying session_server

- The chart-created Service `gitlab-runner-session-server` is of type
  `LoadBalancer` and gets an NLB hostname populated by the AWS Load
  Balancer Controller.
- `dig +short <session_server_hostname>` resolves to that NLB.
- In the GitLab UI, run a job that pauses (e.g. `sleep 600`), then click
  **Debug** → an interactive web terminal opens into the build pod.

## Verifying AWS Secrets Manager integration

1. Apply with `create_demo_secret = true` to create a sample secret.
2. Copy the value of the `gitlab_ci_secrets_reader_role_arn` output and
   set it as a **CI/CD variable** named `AWS_SECRETS_ROLE_ARN` (masked) in
   the GitLab project at `var.gitlab_project_path`.
3. Copy `examples/gitlab-ci/.gitlab-ci.yml` into that project and push.
4. Run the `secret:fetch` job — it prints the length of the fetched value
   without echoing it.

## Pipelines shipped in this repo

| Path | What it does |
|---|---|
| `.github/workflows/terraform.yml` | On PRs: `fmt -check`, `init`, `validate`, `plan`. Auths via GitHub OIDC; needs repo secret `AWS_OIDC_ROLE_ARN`. |
| `.gitlab-ci.yml` (repo root) | Same lifecycle via GitLab OIDC if you mirror the repo to GitLab. Needs CI/CD variable `AWS_ROLE_ARN`. |
| `examples/gitlab-ci/.gitlab-ci.yml` | Exercises the runner end-to-end (cache, matrix, web-terminal sleep job, Secrets Manager fetch). Copy into a real GitLab project. |

`apply` is intentionally left manual — no auto-apply workflow ships in v1.

## Teardown

```sh
cd terraform
terraform destroy
```

`force_destroy` is **off** on the cache bucket, so empty it manually first
if it has objects:
```sh
aws s3 rm "s3://$(terraform output -raw runner_cache_bucket)" --recursive
```

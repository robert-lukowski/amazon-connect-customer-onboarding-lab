# Amazon Connect customer onboarding lab

Phase 1 provides a single-repository Terraform foundation for onboarding Amazon Connect customers into AWS DEV. It targets `eu-central-1`, looks up the existing Connect instance with alias `robert-support`, and includes the first customer, `demo-a`.

No AWS resources have been created by this repository. The workflows validate Terraform only; they do not authenticate to AWS, plan, apply, or destroy infrastructure.

## Phase 1 layout

```text
.github/workflows/       Terraform validation workflows
bootstrap/               S3 state-bucket design
customers/demo-a/        Business configuration for demo-a
modules/customer/        Reusable Amazon Connect customer module
scripts/                 Local validation helper
terraform/               DEV root module and partial S3 backend
```

The customer module currently manages:

- hours of operation;
- queues;
- routing profiles;
- security profiles;
- consistent names and tags.

Lambda, CloudWatch alarms, users, phone numbers, and complex contact flows are intentionally deferred.

## Configuration model

Business settings live in `customers/demo-a/customer.yaml`. Each collection is a map whose key is a stable logical identifier, such as `standard`, `support`, or `support_agents`. Terraform uses these keys with `for_each`, so changing a display name does not change the Terraform resource address.

Names use this convention:

```text
<customer-key>-<environment>-<configured-name>
```

For example, the `support` queue for `demo-a` is named `demo-a-dev-support`. Module validation rejects missing hours-of-operation references, missing queue references, invalid schedule values, and unsupported routing channels.

## Local validation

Terraform 1.10 or newer is required because the backend design uses native S3 lockfiles.

```powershell
.\scripts\validate.ps1
```

Equivalent commands are:

```powershell
terraform fmt -check -recursive
$env:TF_VAR_customer_key = "demo-a"
terraform -chdir=terraform init -backend=false -input=false
terraform -chdir=terraform validate
```

Initialization downloads the Terraform provider from the Terraform Registry but keeps the backend disabled and does not call AWS APIs.

## State design

`bootstrap` defines a private, encrypted S3 bucket with versioning enabled, deletion protection, and a policy that rejects non-TLS requests. The caller must provide a globally unique bucket name with an account-specific or GUID suffix. The customer root uses a partial S3 backend with encryption and native S3 state locking (`use_lockfile = true`). The bucket and key are intentionally not hard-coded together.

When AWS access and an OIDC role are approved in a later phase, initialize a customer with an explicit bucket and per-customer key:

```text
terraform -chdir=terraform init -reconfigure \
  -backend-config="bucket=<dev-state-bucket>" \
  -backend-config="key=customers/demo-a/dev/terraform.tfstate"
```

The next customer will use the same root and module with a different customer key, YAML path, and backend key. CAT and PROD state layouts and deployment logic are not part of Phase 1.

## GitHub Actions

`.github/workflows/validate.yml` calls `.github/workflows/reusable-terraform.yml` with only a customer key. The reusable workflow validates the key, derives `customers/<customer-key>/customer.yaml`, and runs `terraform fmt -check`, `terraform init -backend=false`, and `terraform validate` only.

The validation workflow has only `contents: read` permission. GitHub OIDC permissions and AWS authentication will be introduced later in a separate deployment job; Phase 1 does not configure AWS credentials or create IAM resources.

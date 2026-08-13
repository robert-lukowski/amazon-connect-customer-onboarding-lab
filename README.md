# Amazon Connect customer onboarding lab

This lab provides a single-repository Terraform foundation for onboarding Amazon Connect customers into AWS DEV. It targets `eu-central-1`, looks up the existing Connect instance with alias `robert-support`, and includes the first customer, `demo-a`.

Phase 2 adds a practical GitHub Actions deployment POC. The manual workflow authenticates to AWS through GitHub OIDC, plans `demo-a`, and applies it to DEV. No destroy workflow is provided.

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

The DEV customer deployment initializes with this bucket and a per-customer key:

```text
terraform -chdir=terraform init -reconfigure \
  -backend-config="bucket=amazon-connect-tfstate-854010287302-eu-central-1" \
  -backend-config="key=customers/demo-a/dev/terraform.tfstate"
```

The next customer will use the same root and module with a different customer key, YAML path, and backend key. CAT and PROD remain out of scope.

## GitHub Actions

`.github/workflows/validate.yml` calls `.github/workflows/reusable-terraform.yml` with only a customer key. The reusable workflow validates the key, derives `customers/<customer-key>/customer.yaml`, and runs `terraform fmt -check`, `terraform init -backend=false`, and `terraform validate` only.

The validation workflow has only `contents: read` permission. The separate manual deployment workflow has `contents: read` and `id-token: write`, exchanges its GitHub token for short-lived AWS credentials, and can assume its DEV role only from the repository's `main` branch.

## Deploy demo-a from GitHub Actions

1. Bootstrap the DEV state bucket and GitHub role once from an authorized local AWS session:

   ```powershell
   terraform -chdir=bootstrap init
   terraform -chdir=bootstrap apply -auto-approve `
     -var="state_bucket_name=amazon-connect-tfstate-854010287302-eu-central-1"
   ```

2. Merge the deployment workflow into `main`. Its OIDC trust intentionally rejects other branches.
3. In GitHub, open **Actions**, select **Deploy customer to DEV**, choose **Run workflow** on `main`, select `demo-a`, and run it.
4. Review the workflow's Terraform plan and apply output. A successful plan automatically proceeds to `terraform apply -auto-approve`; customer deployment is not run locally.

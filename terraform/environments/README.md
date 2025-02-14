# Managing Terraform and Terragrunt Across Multiple AWS Accounts

This guide provides best practices for configuring Terraform and Terragrunt to work with separate AWS accounts for local and CI/CD pipeline execution. The goal is to ensure secure, consistent workflows without relying on local AWS profiles or long-lived credentials.

## Overview

Terraform and Terragrunt can leverage IAM roles, AWS SSO, and dynamic configuration to support both local and pipeline execution. These approaches ensure:

- Secure handling of credentials.
- Standardized role assumptions.
- Compatibility with local development and CI/CD pipelines.

---

## AWS Providers and Accounts

### Example Configuration with AWS SSO

AWS SSO simplifies managing user access to multiple accounts and roles:

```hcl
provider "aws" {
  region         = "us-east-1"
  sso_start_url  = "https://your-sso-url.awsapps.com/start"
  sso_region     = "us-east-1"
  sso_account_id = "123456789012"
  sso_role_name  = "RoleName"
}
```

### Dynamic Role Assumption

To switch between production and non-production accounts dynamically:

```hcl
locals {
  env      = terraform.workspace
  role_arn = local.env == "production" ? "arn:aws:iam::PROD_ACCOUNT_ID:role/RoleName" :
             local.env == "nonprod"   ? "arn:aws:iam::NONPROD_ACCOUNT_ID:role/RoleName" :
                                        "arn:aws:iam::PLAYGROUND_ACCOUNT_ID:role/RoleName"
}

provider "aws" {
  region = "us-east-1"
  assume_role {
    role_arn     = local.role_arn
    session_name = "execution-session"
  }
}
```

This configuration assumes roles based on the Terraform workspace (e.g., `production` or `non-production`).

---

## Pipeline Execution

### Using IAM Roles in Pipelines

For secure execution in CI/CD pipelines:

1. **Assign IAM Roles**:
   - Attach an IAM role to the pipeline runner with permissions to assume the target roles.

2. **Leverage OpenID Connect (OIDC)**:
   - Use OIDC to assume roles dynamically without storing keys.

Example pipeline script:

```yaml
deploy:
  script:
    - export AWS_ROLE_ARN="arn:aws:iam::TARGET_ACCOUNT_ID:role/RoleName"
    - export AWS_WEB_IDENTITY_TOKEN_FILE=$CI_JOB_JWT_FILE
    - terraform apply
```

---

## Local Development

### Standardizing Local Setup

Enforce consistent local development workflows:

1. **Use AWS SSO**:
   - Authenticate locally with:
  
     ```sh
     aws sso login
     aws configure sso
     ```

2. **Wrapper Script**:
   - Create a script for local execution:

     ```bash
     # assume_role.sh
     export AWS_PROFILE=my-sso-profile
     terragrunt plan
     ```

### Conditional Logic for Local and Pipeline Execution

Differentiate between local and pipeline execution using environment variables:

```hcl
locals {
  is_ci    = length(get_env("CI", "")) > 0
  role_arn = local.is_ci ? "arn:aws:iam::TARGET_ACCOUNT_ID:role/CIRole" : "arn:aws:iam::TARGET_ACCOUNT_ID:role/DeveloperRole"
}

provider "aws" {
  region = "us-east-1"
  assume_role {
    role_arn     = local.role_arn
    session_name = local.is_ci ? "ci-session" : "local-session"
  }
}
```

---

## Security Considerations

1. **Avoid Long-Lived Credentials**:
   - Use IAM roles, SSO, or short-lived credentials in pipelines.

2. **Secure Secrets**:
   - Store sensitive information in AWS Secrets Manager or HashiCorp Vault.

3. **Audit Access**:
   - Regularly audit IAM roles and permissions.

---

## Summary

- Use AWS SSO for local development.
- Use IAM roles with dynamic role assumption for CI/CD pipelines.
- Standardize workflows with scripts and conditional logic.

This approach ensures secure, scalable, and consistent Terraform and Terragrunt execution across environments.
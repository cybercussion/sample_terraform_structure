# Terraform

* Terraform: A tool for defining and provisioning infrastructure as code, enabling you to create, manage, and update resources in a declarative and repeatable way.
* Terragrunt: A wrapper for Terraform that simplifies managing complex infrastructure setups by promoting DRY principles, automating workflows, and handling environment-specific configurations and dependencies.

Terraform interacts directly with provider APIs to create and manage resources, offering flexibility, speed, and multi-cloud support, while CloudFormation relies on AWS's orchestration engine, which can suffer from limitations like slow updates, fewer customization options, and challenges handling complex dependencies.

**Brief key differences with this approach**:

* Cloudformation drift detection less comprehensive.  Terraform actively detects and reconciles drift.
* Cloudformation fails stack updates and rollback.  Terraform errors are granular showing exactly what failed and allows for partial retries
* Cloudformation can re-use resources but takes up front planning.  Terraform allows for fine-grain control enabling updates without resource replacement.
* Cloudformation lacks state management.  Terraform maintains a explicit state file offering a better control over changes.
* Both serve as infrastructure as code (IaC)

## Rough layout based on some of our infrastructure

Generic layout, subject to change.

```plaintext
terraform/
├── modules/
│   ├── s3_cloudfront/           # Module for SPA hosting (S3, CloudFront, OAI)
│   ├── route53/                 # Module for DNS management
│   └── rds/                     # Module for RDS Serverless
├── environments/
│   ├── nonprod/
│   │   ├── dev/
│   │   │   ├── sp-web-app/      # SPA resources for nonprod/dev
│   │   │   │   └── terragrunt.hcl
│   │   │   ├── route53/         # Route53 for nonprod/dev
│   │   │   │   └── terragrunt.hcl
│   │   │   ├── services/        # Services for nonprod/dev
│   │   │   │   ├── nodejs/
│   │   │   │   │   └── terragrunt.hcl
│   │   │   │   ├── java/
│   │   │   │       └── terragrunt.hcl
│   │   ├── stage/               # Same structure for stage
│   │   │   └── ...
│   │   ├── perf/                # Same structure for perf
│   │       └── ...
│   ├── prod/
│   │   ├── dryrun/              # Same structure for prod/dryrun
│   │   │   └── ...
│   │   ├── prod/                # Same structure for prod/prod
│   │       └── ...
├── terragrunt.hcl               # Global configuration for shared settings
```

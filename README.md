# Terraform Structure Demo

This is a sample structure using Terraform/Terragrunt to deal with creating, managing and destroying multiple environments.
This is not meant to directly be a huge mono repo for DevOps but could also be broke up per project.

## Getting Started

### For MacOS Terminal or iTerm2

Consider instaling https://brew.sh

`brew install asdf`

`asdf install`

Will install terraform and terragrunt.

## Demos in this repo

### Setup

Set your S3 state bucket in `root.hcl`
Set any common variables in `common.hcl`
Set any and lower level settings in subdirectories `terragrunt.hcl` files.

`cd terraform/environments/nonprod/dev/`

- `ecs-fargate-demo`
- `sqs-lambda-demo`
- `webapp-spa-demo`
- `shared/gitlab-ci` AWS EKS Fargate Gitlab Runner
- `shared/notifications/cw_alerts` CloudWatch Alerts to Google Chat
- `shared/rds/` AWS Aurora RDS Database

[Terragrunt](https://terragrunt.gruntwork.io/docs/reference/cli-options/) allows you to `cd` into these directories and either run one folder or use `run-all` at a parent level to capture all below it.

- `terragrunt run-all validate`
- `terragrunt run-all plan`
- `terragrunt run-all apply`
- `terragrunt run-all destroy`
- `terragrunt validate-inputs`

## What are Terraform Modules

Terraform modules are reusable, self-contained configurations that encapsulate infrastructure components, allowing you to organize and manage your Terraform code more efficiently.  They are structured with a main.tf for resources, variables.tf for inputs, outputs.tf for outputs, and optional files like providers.tf for provider configurations. Terraform's syntax, called HashiCorp Configuration Language (HCL), is a declarative language designed for defining infrastructure as code, using blocks, arguments, and expressions to describe desired resources and configurations.

Terraform has [providers](https://registry.terraform.io/browse/providers?product_intent=terraform) which interact with upstream APIs.  As mentioned this is different than Cloudformation since Terraform is multi-cloud centric or Cloud-agnostic.  This would support hybrid infrastructure/deployments.  So you can even use pre-created modules supplied by the registry to fast track your design, community support, maintenance etc.

## What is the Environments Folder?

The `environments/` folder in Terragrunt acts as the [stack](https://terragrunt.gruntwork.io/docs/features/stacks/#the-run-all-command) orchestration layer, containing `terragrunt.hcl` files that define environment-specific configurations (e.g., dev, stage, prod). It manages **inputs, backend settings, and dependencies**, ensuring Terraform modules are deployed consistently across different environments.

### Terragrunt why?

Using Terragrunt over plain Terraform provides several key advantages, particularly for managing complex infrastructure:

1. **📌 DRY (Don't Repeat Yourself)**  
   - Terragrunt allows you to reuse common configurations like **backend settings, provider configurations, and variables** across environments.  
   - Reduces duplication and ensures consistency.

2. **🌍 Environment-Specific Configurations**  
   - Separate `terragrunt.hcl` files for **each environment** (e.g., dev, stage, prod).  
   - Makes it easier to manage variations **without duplicating module logic**.

3. **🔗 Dependency Management**  
   - Define **dependencies between modules** to enforce correct execution order.  
   - Ensures Terraform resources deploy in **the right sequence** when modules rely on each other.

4. **⚙️ Automation and Orchestration**  
   - Use **`terragrunt run-all`** to execute Terraform commands across multiple modules simultaneously.  
   - Simplifies operations like `apply`, `plan`, and `destroy` for **multi-module deployments**.

5. **☁️ Simplified S3 State Management**  
   - Automates **remote state storage** (e.g., S3) and **locking** (e.g., DynamoDB).  
   - Eliminates the need to manually configure backend settings in each module.

6. **🚨 Error Prevention & Safety Features**  
   - Use **`prevent_destroy`** to avoid accidental resource deletions.  
   - Automates **backend configuration**, reducing misconfiguration risks.  
7. **📦 Module Sourcing & Versioning** – Easily pull Terraform modules from **Git, S3, or local paths**.  
8. **🌐 Remote Execution Support** – Enables running Terraform remotely, useful for **CI/CD pipelines**.  
9. **📊 Dynamic Configuration with Locals** – Avoids hardcoding by using **locals in `terragrunt.hcl`**.  
10. **🔑 Flexible Secret Management** – Supports secure handling of sensitive inputs.  
11. **🚀 Multi-Environment Scalability** – Helps manage **multiple environments efficiently**.  
12. **👥 Improved Collaboration** – Standardizes state management and enforces **modular practices**.  

# Python Scripts

Quick way to access terraform/terragrunt commands without needing to `cd` into directories.

## Usage

`python terraform/scripts/<file.py> -a <account> -e <environment> -f <folder> -c <command> [--run-all] [--dry-run] [--log-level <level>]`

| Flag               | Description                                        | Example                     |
|--------------------|----------------------------------------------------|-----------------------------|
| `-a` / `--account` | Target account (e.g., `nonprod`, `prod`)           | `-a nonprod`                |
| `-e` / `--env`     | Target environment folder                          | `-e dev`                    |
| `-f` / `--folder`  | Optional: Specific module/folder inside env        | `-f sqs-lambda-demo`        |
| `-c` / `--command` | Terraform command (`init`, `plan`, `apply`, `destroy`)| `-c plan`                |
| `--run-all`        | Use `terragrunt run-all` instead of single run     | `--run-all`                 |
| `--dry-run`        | Show what would run, but don't execute             | `--dry-run`                 |
| `--log-level`      | Log level (`info`, `debug`, `trace`, `warn`, `error`)| `--log-level error`       |

## SQS Lambda Demo

```shell
python terraform/scripts/tg.py -a nonprod -e dev -f sqs-lambda-demo -c plan --run-all

👉 Running: terragrunt run-all plan in terraform/environments/nonprod/dev/sqs-lambda-demo
23:07:26.849 INFO   The stack at . will be processed in the following order for command plan:
Group 1
- Module ./dynamodb
- Module ./sqs

Group 2
- Module ./role

Group 3
- Module ./lambda_task
- Module ./lambda_task_runner

Group 4
- Module ./api_gateway
```

## ECS Fargate Demo

```shell
python terraform/scripts/tg.py -a nonprod -e dev -f ecs-fargate-demo -c plan --run-all;

👉 Running: terragrunt --terragrunt-log-level=info run-all plan in terraform_structure/terraform/environments/nonprod/dev/ecs-fargate-demo
23:39:47.557 INFO   The stack at . will be processed in the following order for command plan:
Group 1
- Module ./cluster
- Module ./security_group
- Module ./services/service-a/codedeploy_role
- Module ./services/service-a/ecr
- Module ./services/service-a/task_execution_role
- Module ./services/service-a/task_role

Group 2
- Module ./alb
- Module ./services/service-a/task_definition

Group 3
- Module ./services/service-a/route53
- Module ./services/service-a/security_group
- Module ./services/service-a/target_group

Group 4
- Module ./services/service-a/ecs_service

Group 5
- Module ./services/service-a/codedeploy
```

## WebApp Single Page Demo

Frameworks like VueJS, Angular 2+ etc for serverless (Cloudfront/S3)

```shell
python terraform/scripts/tg.py -a nonprod -e dev -f webapp-spa-demo -c plan --run-all

👉 Running: terragrunt --terragrunt-log-level=info run-all plan in terraform_structure/terraform/environments/nonprod/dev/webapp-spa-demo
23:40:53.048 INFO   The stack at . will be processed in the following order for command plan:
Group 1
- Module ./s3_cloudfront

Group 2
- Module ./route53
```

## Shared

### RDS

```shell
python terraform/scripts/tg.py -a nonprod -e shared -f rds -c plan --run-all
```

### CodeBuild Github Runner

AWS now allows you to run a CodeBuild runner to execute Github Actions in AWS.

```shell
python terraform/scripts/tg.py -a nonprod -e shared -f codebuild-github-runner -c plan --run-all
```

### Codebuild Gitlab Runner

AWS now allows you to run a CodeBuild runner to execute Github Actions in AWS.

```shell
python terraform/scripts/tg.py -a nonprod -e shared -f codebuild-gitlab-runner -c plan --run-all
```

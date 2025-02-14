# ECS-Fargate Demo

**Tip**: Have Docker installed/Running for initial setup.

Terragrunt tip for cleaning up things after building/redesigning.

```shell
find . -type d -name ".terragrunt-cache" -exec rm -rf {} +
find . -type f -name ".terraform.lock.hcl" -exec rm -f {} +
# OR
find ./ -type d -name ".terragrunt-cache" -exec rm -rf {} + -o -type f -name ".terraform.lock.hcl" -exec rm -f {} +
```

Apple Silicon macs, watch your builds/pulls **--platform linux/amd64**

```bash
docker build --platform linux/amd64 -t my-app .
docker pull --platform linux/amd64 nginx
```

```bash
docker pull --platform linux/amd64 nginx:latest
docker tag nginx:latest <YOURACCOUNTID>.dkr.ecr.us-west-2.amazonaws.com/ecs-fargate-demo-service-a-dev:latest
```

## Key Components and Their Relationships

### 1. **`common.hcl` (Global Configuration)**

- Defines global variables like `aws_region`, `account_id`, `environment`, `service_name`, and `port`.
- Provides common tags and health check configurations shared across services.

### 2. **ALB (`alb/`)**

- Configures the **Application Load Balancer (ALB)**.
- Defines listeners, target groups (blue/green), and routes traffic to the ECS service.

### 3. **ECS Cluster (`cluster/`)**

- Defines the **ECS Cluster** where your ECS services will be deployed.
- Includes VPC, subnets, and networking configurations.

### 4. **Security Groups (`securitygroup/`)**

- Defines the **security groups** for the ECS services and ALB.
- Ensures the appropriate network traffic flow between the services, ALB, and other resources.

### 5. **Services (`services/service-a/`)**

This folder contains the configuration for the individual service, such as "service-a".

- **`codedeploy/`**: Defines the **CodeDeploy configuration** for handling deployment to ECS.
- **`codedeploy_role/`**: Creates the **IAM role for CodeDeploy**.
- **`ecs_service/`**: Sets up the **ECS service**, including the task definition, load balancer, and other configurations.
- **`ecr/`**: Manages the **Amazon Elastic Container Registry (ECR)** for storing and versioning container images.
- **`task_execution_role/`**: Defines the **IAM role for ECS task execution** with permissions for interacting with AWS services.
- **`route53/`**: Configures **Route 53 DNS records** for the ECS service.
- **`security_group/`**: Defines security group settings specifically for the service.
- **`task_definition/`**: Sets up the **ECS task definition**, including container settings, ports, environment variables, and health checks.
- **`task_role/`**: Configures the **IAM role for ECS tasks**, granting permissions to interact with other AWS resources (e.g., S3, DynamoDB, etc.).

| Deployment Type  | Description | Traffic Flow | Load Balancer | Deployment Controller | Rollback Capability |
|-----------------|-------------|--------------|---------------|----------------------|----------------------|
| **Rolling**     | Gradually replaces old tasks with new ones. | Directly shifts all traffic to the new version. | Single Target Group (Blue) | Default ECS Service Controller | Slow rollback (must redeploy the old version) |
| **Blue/Green**  | Deploys new tasks in a separate target group, then switches traffic. | All traffic switches from Blue (old) to Green (new). | Two Target Groups (Blue & Green) | CodeDeploy | Fast rollback (switch back to the previous target group) |
| **Canary**      | Gradually shifts traffic from old to new version over time. | Starts with a small percentage (e.g., 10%) and increases gradually. | Two Target Groups (Blue & Green) | ECS Service (with ALB Weighted Routing) | Medium-speed rollback (reduce new version traffic back to 0%) |

See: common.hcl for key/values

Make sure you get your ports on the same page (task-def/Dockerfile) for your services.

`EXPOSE 80` and `port = "80"` or NodeJS, `EXPOSE 3000` and `port = "3000"`

## ALB Listener Rule Management

This table explains when Terraform manages ALB listener rules vs. when AWS CodeDeploy handles them.

| **Deployment Type** | **CodeDeploy Used?** | **Terraform Manages Listener Rules?** | **Expected Behavior** |
|--------------------|---------------------|---------------------------------|------------------------|
| **Rolling**       | ❌ No               | ✅ Yes (`manage_listener_rules = true`) | Terraform creates listener rules |
| **Canary**        | ❌ No               | ✅ Yes (`manage_listener_rules = true`) | Terraform creates listener rules with Canary weights |
| **Blue/Green**    | ✅ Yes              | ❌ No (`manage_listener_rules = false`) | CodeDeploy manages listener rules |

## Dependencies and Interactions

1. **Common Configuration (`common.hcl`)**: This file is read by each service to ensure consistent settings (e.g., `environment`, `service_name`, `port`, `health_check_path`).

2. **ALB & ECS Integration**: 
   - **ECS service** uses the ALB for traffic routing.
   - **ECS Task Definition** is linked to the ALB through `load_balancer` and `container_port`.

3. **CodeDeploy Integration**:
   - **CodeDeploy** works with ECS and the target groups (blue/green deployment) to deploy updated versions of your service.
   - **Codedeploy Role** is used by ECS for deploying services to the target groups.

4. **Security Groups**:
   - Security groups are applied to both the ALB and ECS services to control traffic between them.

5. **IAM Roles**:
   - **ECS Task Role** provides permissions to tasks running in ECS.
   - **Execution Role** is used to grant ECS tasks permissions to access AWS resources.
   - **CodeDeploy Role** is used for deploying the application to ECS.

### Key Components

1. **Route 53**:
   - **Maps** domain names to the **ALB**.
   - Ensures traffic is routed correctly to the ECS service.

2. **ALB (Application Load Balancer)**: 
   - **Handles incoming traffic** on HTTP/HTTPS.
   - Routes traffic to appropriate **ECS service** based on listener rules.

3. **ECS Cluster**:
   - **Hosts ECS tasks** (services like `service-a`).
   - Configured with a **VPC** and **subnets** to manage networking.

4. **ECS Service (e.g., `service-a`)**:
   - **Represents a service** that runs within ECS, using a **task definition**.
   - Defines **health checks** and **container specifications** (e.g., port mappings).

5. **Target Groups (Blue/Green Deployment)**:
   - **Manage routing** for blue/green deployments.
   - **Monitors target health** to ensure that traffic is routed to healthy services.

6. **Task Definitions**:
   - Defines **containers**, **ports**, and **task settings** for ECS services.
   - **Configures container image** (e.g., `nginx:latest`), ports, environment variables, etc.

7. **CodeDeploy**:
   - **Handles rolling deployments** using ECS and the target groups.
   - **Updates ECS tasks** with new revisions during deployment.

8. **Security Groups**:
   - **Control network traffic** between the ALB, ECS service, and other components.

### How It Works:

1. **Route 53** maps the domain to the **ALB**.
2. **ALB** listens for traffic on specified ports (80, 443) and forwards requests to **ECS service** (e.g., `service-a`).
3. The **ECS service** is configured via the **ECS Task Definition**, which defines the container, port mapping, health checks, and environment variables.
4. **CodeDeploy** enables **rolling updates**, ensuring zero downtime for deployments to the ECS service.
5. **Security Groups** control access between the components, ensuring that only allowed traffic can flow between the ALB and ECS services.

### Visual

```text
+-------------------------------+
|    Internet / Client          |
|   (HTTP Request on Port 80)   |
|   or HTTPS Request on Port 443|
+---------------+---------------+
                |
                v
    +-----------------------------+                        **Edit: `terragrunt.hcl` under `alb`**
    | Application Load Balancer   |                         (Configure ALB listeners on 80 and 443)
    +-----------------------------+
                |   
                v
    +-----------------------------+                        **Edit: `service_security_group/terragrunt.hcl`**
    |   Security Group (ALB SG)   |                          (Allow inbound traffic on Port 80 and 443)
    +-----------------------------+
                | 
                v
    +-----------------------------+                        **Edit: `target_group/terragrunt.hcl`**
    |      Target Group (TG)      |                           (Configure target group to forward traffic to ECS)
    +-----------------------------+
                | 
                v
    +-----------------------------+                        **Edit: `task_definition/terragrunt.hcl`**
    |  ECS Task Definition        |                           (Define container port as 80 or 3000 in task definition)
    |  (Container Port 80 or 3000)|  
    +-----------------------------+
                | 
                v
    +-----------------------------+                        **Edit: `Dockerfile`**
    |     Running Docker Container|                           (Ensure Docker container exposes the correct port with `EXPOSE`)
    | (Nginx on Port 80 or Node.js|
    |      on Port 3000)          |
    +-----------------------------+
```


## Coping with Failure

Terraform/Terragrunt will let you iterate over failure.

However say, you forget to set the placeholder image to true, but you reference the ECR Url vs something else.

```bash
aws ecs update-service --cluster <your-cluster-name> --service <your-service-name> --force-new-deployment
```

### Task definitions

```bash
aws ecs list-task-definitions --family-prefix service-a --sort DESC
```

```bash
LATEST_TASK_DEF=$(aws ecs list-task-definitions --family-prefix service-a --sort DESC --query "taskDefinitionArns[0]" --output text)
aws deploy create-deployment \
   --application-name dev-service-a-cd-application \
   --deployment-group-name dev-service-a-cd-deployment-group \
   --deployment-config-name CodeDeployDefault.ECSAllAtOnce \
   --revision revisionType=AppSpecContent,appSpecContent='{
      "version": "0.0",
      "Resources": [
         {
         "TargetService": {
            "Type": "AWS::ECS::Service",
            "Properties": {
               "TaskDefinition": "'"$LATEST_TASK_DEF"'",
               "LoadBalancerInfo": {
               "ContainerName": "service-a",
               "ContainerPort": 80
               }
            }
         }
         }
      ]
   }'
```

```bash
aws ecs describe-services --cluster dev-fargate-cluster --services service-a
```

Test Scale up

```bash
aws application-autoscaling describe-scalable-targets \
  --service-namespace ecs
{
    "ScalableTargets": [
        {
            "ServiceNamespace": "ecs",
            "ResourceId": "service/dev-fargate-cluster/service-a",
            "ScalableDimension": "ecs:service:DesiredCount",
            "MinCapacity": 1,
            "MaxCapacity": 5,
            "RoleARN": "arn:aws:iam::<YOURACCOUNTID>:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService",
            "CreationTime": "2025-02-22T17:03:05.766000-07:00",
            "SuspendedState": {
                "DynamicScalingInSuspended": false,
                "DynamicScalingOutSuspended": false,
                "ScheduledScalingSuspended": false
            },
            "ScalableTargetARN": "arn:aws:application-autoscaling:<YOURREGION>:<YOURACCOUNTID>:scalable-target/0ec5f8373e861c394ca7a9d0114e974c0ab2"
        }
    ]
}
# Rev one up
aws ecs update-service \
  --cluster dev-fargate-cluster \
  --service service-a \
  --desired-count 2
```

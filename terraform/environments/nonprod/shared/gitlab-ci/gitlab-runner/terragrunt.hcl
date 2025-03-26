include {
  path = find_in_parent_folders("root.hcl")
}

# Load common configuration
locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
  base_module_path = "${find_in_parent_folders("root.hcl")}/../modules"
}

terraform {
  source = "${local.base_module_path}/gitlab-runner"
}

# Dependency on the EKS module
dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name              = "mock-cluster"
    cluster_endpoint          = "https://mock-endpoint"
    cluster_ca_certificate    = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN5RENDQWJDZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeU1ERXhOVEV5TURVeE1Gb1hEVE15TURFeE1qRXlNRFV4TUZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTTJoCnRkbXQ1TmZYWmJYVGJPRjJwWUxZbVVNMWVPZkZQZ3ZldmJ5bUFZYTVKcVo5NDd3Yk4yNHZkVk5PbVNkWm0zR1QKcEUvUkFGK0JpZWswWGwvM2VmZE9zcVBvU3k2K0RUWHdIMjJIYzFNc3B5K1ZKWjVQOHlGQ2t1Q2JnVldkbzJJRQpZYWxIbTZydXFYT1pFYzBhUDVjUjNVQ2h0RjZXTDZwVzAvMGxXZnBYRzVvS0M4YmtUVU5wZkh3RlQrdWd4WUxICkNjU0U4S1p6UEZkNnprYUdyTlRmT1I2ZnJXMWpYa0RwU0I5YXJOaGpJZ1pZeEhNc3ZzL2ZhcXB4QmxZVTZ3dVQKUVZCU0RxK1U3TzVxd2lFNzZQU2VOUHAzaGJsUVJtMWx0NkpkSzNiMUJXK2RHK3ZzTnhkY0VhZkZ2K0RLUUxLYgpxZUZpWS9lVjdVVUNBd0VBQWFOQ01FQXdEZ1lEVlIwUEFRSC9CQVFEQWdLa01BOEdBMVVkRXdFQi93UUZNQU1CCkFmOHdIUVlEVlIwT0JCWUVGR21tb0RzL3RnT2JLMVdpQk1YWUJjVVA2bEZJTUEwR0NTcUdTSWIzRFFFQkN3VUEKQTRJQkFRQTJHaHJ3MGd4YUZ4cVNNekY0WmoxNVlXYXFTRzZKcXI5VlZaVHJkV0pzaVZ4M0ZxVGZiaTRKQ1NNaQpGYzZvOVBZK1FJN09QWXF6ay9LMmJWQnpOYzZ5THRPVlFZQmZKK0JIRlRaWGtOQjFwWGVaVTFhdkR4RDl0WkxICnJFY2x0YUxQTTNLY0xRNVU0TzZIWStKcXZ4MjVEYUNxS3VxNUlHa3AvSFVmL1BSUFZyN3hHQXJlb1N4YUt3VXEKK1hzMzZVUmVpVktnWkZFYzFtd0RkR0tCN0hkbXFsRnFLYW5SU3B1QXgxQVJPcEd2UGxCNVNSOUlEdHJNY0dVRQpVQ2hKcW9PZnNodmVPZEdOeitCWnhUb0xCVjNqL0NLRFpKQ2V5THhYcHFCdmxGNjVCK0RxQlJKUXNYY0I1T0VvCnhRVk9GSnNZY1BUeHR5SHdQbkd4WlhQegotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0t"
    cluster_token             = "mock-token"
    
    fargate_profiles          = [
      {
        name                  = "gitlab-runner"
        pod_execution_role_arn = "arn:aws:iam::123456789012:role/mock-fargate-pod-role"
        selectors             = [
          { namespace = "gitlab-runner" }
        ]
      }
    ]
  }
}

# Dependency on the pod role
dependency "pod_role" {
  config_path = "../pod-role"

  mock_outputs = {
    role_arn  = "arn:aws:iam::123456789012:role/mock-pod-role"
    role_name = "mock-pod-role"
  }
}

inputs = {
  admin_users = local.common.admin_users
  # Cluster configuration
  cluster_name           = dependency.eks.outputs.cluster_name
  cluster_endpoint       = dependency.eks.outputs.cluster_endpoint
  cluster_ca_certificate = dependency.eks.outputs.cluster_ca_certificate
  cluster_token          = dependency.eks.outputs.cluster_token

  # Fargate profiles
  fargate_profiles = [
    for profile in dependency.eks.outputs.fargate_profiles : {
      name                   = profile.name
      pod_execution_role_arn = profile.pod_execution_role_arn
      selectors              = profile.selectors
    }
  ]

  # GitLab configuration
  gitlab_url         = "https://gitlab.com"
  registration_token = run_cmd(
    "aws", 
    "secretsmanager", 
    "get-secret-value", 
    "--secret-id", 
    "GitLabRegistrationToken", 
    "--query", 
    "SecretString", 
    "--output", 
    "text"
  )
  runner_token = run_cmd(
    "aws", 
    "secretsmanager", 
    "get-secret-value", 
    "--secret-id", 
    "GitLabRunnerToken", 
    "--query", 
    "SecretString", 
    "--output", 
    "text"
  )

  # Runner-specific configuration
  runner_tag_list = ["fargate", local.common.environment]
  runners_name    = "nonprod-runner"

  # Common tags
  tags = local.common.tags
}
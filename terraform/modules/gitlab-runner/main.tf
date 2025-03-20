terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.11.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.7.1"
    }
  }
  backend "s3" {}
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Create Kubernetes namespace for GitLab Runner
# resource "kubernetes_namespace" "gitlab_runner" {
#   metadata {
#     name = var.namespace
#   }
# }

# Create the values.yaml for GitLab Runner Helm release
# resource "local_file" "runners_config" {
#   content  = templatefile("${path.module}/runners.config.tmpl", {
#     gitlab_url         = var.gitlab_url
#     registration_token = var.registration_token
#     namespace          = var.namespace
#     runners_name       = var.runners_name
#   })
#   filename = "${path.module}/runners.config"
# }

# Create Role for secret creation in the default namespace
resource "kubernetes_role" "gitlab_runner_resource_manager_default" {
  metadata {
    name      = "gitlab-runner-resource-manager-default"
    namespace = var.namespace
  }

  rule {
    api_groups = [""]
    resources  = ["secrets", "configmaps", "pods"]
    verbs      = ["create", "get", "list", "watch", "delete", "update", "patch"]
  }
}

resource "kubernetes_role_binding" "gitlab_runner_resource_manager_binding_default" {
  metadata {
    name      = "gitlab-runner-resource-manager-binding-default"
    namespace = var.namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.gitlab_runner_resource_manager_default.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = "gitlab-runner"
    namespace = var.namespace  # This should be where your service account is created
  }
}

# Deploy GitLab Runner using Helm
resource "helm_release" "gitlab_runner" {
  name             = var.runner_release_name
  repository       = "https://charts.gitlab.io"
  chart            = "gitlab-runner"
  version          = var.chart_version
  namespace        = "default" #kubernetes_namespace.gitlab_runner.metadata[0].name
  create_namespace = false

  #values = [local_file.runners_config.content]
  # set {
  #   name  = "runners.kubernetes.tolerations"
  #   value = jsonencode([{
  #     key      = "eks.amazonaws.com/compute-type"
  #     operator = "Equal"
  #     value    = "fargate"
  #     effect   = "NoSchedule"
  #   }])
  # }
  set {
    name  = "runners.kubernetes.tolerations"
    value = yamlencode([{
      key      = "eks.amazonaws.com/compute-type"
      operator = "Equal"
      value    = "fargate"
      effect   = "NoSchedule"
    }])
  }

  set {
    name  = "gitlabUrl"
    value = var.gitlab_url
  }

  set_sensitive {
    name  = "runnerRegistrationToken"
    value = var.registration_token
  }

  set {
    name  = "runners.kubernetes.namespace"
    value = var.namespace
  }

  # Let Helm manage RBAC and ServiceAccount
  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "gitlab-runner"
  }
  set {
    name  = "runners.kubernetes.tags"
    value = "fargate"
  }

  set {
    name  = "runners.tags"
    value = "fargate" # Add your desired tags as a comma-separated string
  }
  # Be very careful with the below TOML - no extra spaces
  set {
    name  = "runners.config"
    value = <<-EOT
concurrent = 5
check_interval = 0

[[runners]]
  name = "${var.runners_name}"
  executor = "kubernetes"
  kubernetes_namespace = "${var.namespace}"
  kubernetes_service_account = "${var.namespace}"
  tags = ["fargate"]
  run_untagged = false
  [runners.kubernetes]
    image = "alpine:latest"
    poll_timeout = 600
EOT
  }

  dynamic "set" {
    for_each = var.additional_helm_values
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    #kubernetes_namespace.gitlab_runner,
    kubernetes_role.gitlab_runner_resource_manager_default,
    kubernetes_role_binding.gitlab_runner_resource_manager_binding_default
  ]
}
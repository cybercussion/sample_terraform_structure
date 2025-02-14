output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate"
  value       = module.eks.cluster_certificate_authority_data  # Corrected here
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_token" {
  description = "Token for authenticating with the EKS cluster"
  value       = data.aws_eks_cluster_auth.cluster.token
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubeconfig details for the EKS cluster"
  value = {
    endpoint              = module.eks.cluster_endpoint
    certificate_authority = module.eks.cluster_certificate_authority_data
    # https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest#output_cluster_certificate_authority_data
  }
}

output "fargate_profiles" {
  description = "Fargate profiles created"
  value       = var.fargate_profiles
}
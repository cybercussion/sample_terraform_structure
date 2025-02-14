# Gitlab Runner Registration Token

## Summary: VPC, Subnet, Routing Table, and NAT Gateway for GitLab Runner on EKS Fargate

## 1. Overview

GitLab Runner on EKS Fargate requires a networking setup to:

- **Pull images and dependencies** from the internet (e.g., Docker Hub, package registries).
- **Push build artifacts** to GitLab or other endpoints.

This setup ensures:

- The Runner can access the internet via a NAT Gateway.
- Security by keeping the Runner in private subnets with no direct public exposure.

---

## 2. Components and Their Roles

### VPC

- **Purpose:** A logically isolated network for EKS and other AWS resources.
- **CIDR Block:** `10.0.0.0/16` (adjust as needed).
- **Why Needed:** Provides networking isolation for your resources, ensuring private communication within the cluster.

---

### Subnets

- **Private Subnets:**
  - **CIDR Blocks:** `10.0.1.0/24`, `10.0.2.0/24` (adjust based on your VPC CIDR).
  - **Characteristics:**
    - No direct public IP assignment.
    - Associated with a route table pointing to the NAT Gateway.
  - **Purpose:** Hosts EKS Fargate pods securely.

---

### NAT Gateway

- **Purpose:** Provides outbound internet access for private subnets.
- **Location:** Placed in a public subnet.
- **Elastic IP:** Allocated to the NAT Gateway for internet access.
- **Why Needed:** Ensures Fargate pods in private subnets can access external resources without being publicly exposed.

---

### Public Subnet

- **CIDR Block:** e.g., `10.0.3.0/24`.
- **Characteristics:**
  - Directly routable to the internet via an Internet Gateway.
  - Hosts the NAT Gateway.
- **Purpose:** Ensures the NAT Gateway can send and receive traffic from the internet.

---

### Route Tables

1. **Private Subnet Route Table:**
   - Routes all internet-bound traffic (`0.0.0.0/0`) to the NAT Gateway.
2. **Public Subnet Route Table:**
   - Routes all internet-bound traffic (`0.0.0.0/0`) to the Internet Gateway.

---

## 3. Why Public Internet Access is Needed

- **GitLab Runner Needs:**
  - Pulling images from Docker Hub and other registries.
  - Downloading dependencies for CI/CD jobs.
  - Communicating with GitLab for job status updates and artifact uploads.
- **Fargate Pods in Private Subnets:** 
  - The NAT Gateway provides secure outbound internet access for private pods without exposing them directly to the internet.

---

## 4. Example Architecture Diagram

```plaintext
VPC: 10.0.0.0/16
├── Public Subnet (10.0.3.0/24)
│   └── NAT Gateway
│       └── Internet Gateway
├── Private Subnet 1 (10.0.1.0/24)
│   └── EKS Fargate Pods
├── Private Subnet 2 (10.0.2.0/24)
    └── EKS Fargate Pods
```

If using a VPC MANUAL w/ public IP this can cost $3.60 or so a month.

## Manual Setup

`sh setup_nat_gateway.sh`

## Manual Tear down

`sh teardown_nat_gateway.sh`

Verify your IAM at least has:

```json
{
  "Effect": "Allow",
  "Action": [
    "ec2:ReleaseAddress",
    "ec2:DeleteNatGateway",
    "ec2:DisassociateAddress"
  ],
  "Resource": "*"
}
```


## Retrieving a GitLab Runner Registration Token

I went to my main project, then located Build -> Runners
Created a Group Runner, should get a token.

## Additional Resources

- [GitLab Runners Documentation](https://docs.gitlab.com/runner/)
- [CI/CD Variables in GitLab](https://docs.gitlab.com/ee/ci/variables/)
- [GitLab SaaS Pricing and Features](https://about.gitlab.com/pricing/)

## Set it in AWS Secrets Manager

`aws secretsmanager create-secret --name GitLabRegistrationToken --secret-string "your-registration-token"`

`aws secretsmanager create-secret --name GitLabRunnerToken --secret-string "your-runner-token"`

If you have a more complicated setup, consider naming your tokens accordingly.

## Add cluster local

`aws eks --region us-west-2 update-kubeconfig --name nonprod-eks-cluster`

if accessble you can then query nodes and pods with kubectl

## Debugging and connecting local

Role based access to the cluster required editing the IAM and adding Access Policies for

- AmazonEKSAdminPolicy
- AmazonEKSClusterAdminPolicy

Make sure you do this with new cluser
`aws eks update-kubeconfig --name nonprod-eks-cluster --region us-west-2`

`aws eks list-fargate-profiles --cluster-name nonprod-eks-cluster --region us-west-2`

`kubectl get events -A`

Logging might be disabled by default
`kubectl create configmap aws-logging --from-literal=logRetentionInDays=7 -n gitlab-runner`

Get Logs from gitlab runner
`kubectl logs gitlab-runner-5cb4c7dfcb-z2mp7 -n gitlab-runner;`

Debug TOML Format of config for gitlab runner
`kubectl exec -n gitlab-runner gitlab-runner-5cb4c7dfcb-z2mp7 -- cat /configmaps/config.template.toml`

`kubectl describe configmap gitlab-runner -n gitlab-runner`

Last 5mins of logs
`kubectl logs -n gitlab-runner -l app=gitlab-runner --since=5m`

## Get into the runner pod

`kubectl exec -it -n gitlab-runner $(kubectl get pod -n gitlab-runner -l app=gitlab-runner -o jsonpath='{.items[0].metadata.name}') -- bash`

Deal with issue related to dns in coredns

```shell
kubectl patch deployment coredns -n kube-system --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/tolerations/-",
    "value": {
      "key": "eks.amazonaws.com/compute-type",
      "operator": "Equal",
      "value": "fargate",
      "effect": "NoSchedule"
    }
  }
]'
```

`kubectl get roles,rolebindings -n default`

`aws eks describe-fargate-profile --cluster-name nonprod-eks-cluster --fargate-profile-name kube-system`

`kubectl get pods -n default`

`kubectl delete pod runner-t2dfygo-project-30022322-concurrent-0z8cnh -n default`
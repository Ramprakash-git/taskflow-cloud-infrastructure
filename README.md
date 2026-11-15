# TaskFlow Infrastructure

Terraform configuration for the AWS infrastructure of the TaskFlow application.

## Infrastructure Design

The infrastructure is built on AWS using a VPC spanning two Availability Zones, with public and private subnets.

### Networking
- Custom VPC.
- Two public and two private subnets across two Availability Zones.
- Internet Gateway for public internet connectivity.
- NAT Gateways for outbound internet access from private subnets.
- Route tables and subnet associations.
- Security groups to control network traffic.

### Container Infrastructure
- Amazon EKS cluster for running the application.
- Managed node group using EC2 instances.
- Amazon ECR repository for backend container images.
- AWS Load Balancer Controller installed through Helm.
- Kubernetes resources deployed in the `taskflow` namespace.

### Frontend Hosting
- Amazon S3 bucket for hosting frontend build files.
- Amazon CloudFront for content delivery.
- Origin Access Control (OAC) for securing access to the S3 origin.

### Backend Networking
- Application Load Balancer provisioned through the AWS Load Balancer Controller.
- CloudFront configured as the intended entry point for frontend and backend traffic.
- Path-based routing using `/api/*` for backend requests.

### CI/CD Infrastructure
- GitHub Actions authentication through AWS IAM and OpenID Connect (OIDC).
- Separate IAM roles for backend CI, backend CD, and frontend CD.
- Backend CI permissions for pushing images to ECR.
- Backend CD permissions for deploying resources to the EKS `taskflow` namespace.
- Frontend CD permissions for uploading files to S3 and invalidating CloudFront distributions.

### Security
- IAM roles and policies following workload-specific permissions.
- Private subnets for application infrastructure.
- Security groups controlling communication between infrastructure components.
- S3 Origin Access Control for private frontend bucket access.
- GitHub OIDC authentication without long-lived AWS access keys.
variable "eks_admin_arn" {
  description = "IAM ARN permitted to access EKS cluster"
  type        = string
}

variable "alb_origin_domain" {
  description = "Domain Name of the alb origin"
  type        = string
}
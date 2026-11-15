resource "helm_release" "controller_installation" {
  name       = "aws-load-balancer-ontroller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "3.6.2"

  set = [
    {
      name  = "serviceAccount.create"
      value = "true"
    },

    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },

    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.lb_controller.arn
    },

    {
      name  = "clusterName"
      value = aws_eks_cluster.main.name
    },

    {
      name  = "vpcId"
      value = aws_vpc.main.id
    }
  ]
}
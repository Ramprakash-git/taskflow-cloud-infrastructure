resource "aws_eks_cluster" "main" {
  name     = "eks-cluster-main"
  version  = "1.35"
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]

    subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "vpccni" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "vpc-cni"
  service_account_role_arn = aws_iam_role.vpc_cni.arn
}

resource "aws_eks_addon" "kubeproxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
}

resource "aws_launch_template" "eks_node_template" {
  name = "taskflow-backend-node"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  vpc_security_group_ids = [
    aws_security_group.eks_node_sg.id,
    aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  ]
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "main-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  instance_types  = ["c7i-flex.large"]

  launch_template {
    id      = aws_launch_template.eks_node_template.id
    version = aws_launch_template.eks_node_template.latest_version
  }

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }
}

resource "aws_eks_access_entry" "helm_access" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.eks_admin_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "helm_access" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.eks_admin_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.helm_access]
}

resource "aws_eks_access_entry" "github_actions_cdb" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.github_actions_cdb.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_actions_cdb" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
  principal_arn = aws_iam_role.github_actions_cdb.arn

  access_scope {
    type       = "namespace"
    namespaces = ["taskflow"]
  }

  depends_on = [aws_eks_access_entry.github_actions_cdb]
}

resource "aws_eks_access_entry" "github_actions_k8s_cd" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.github_actions_k8s_cd.arn
  type          = "STANDARD"

  kubernetes_groups = ["github-actions-kube-system"]
}

resource "aws_eks_access_policy_association" "github_actions_k8s_cd" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
  principal_arn = aws_iam_role.github_actions_k8s_cd.arn

  access_scope {
    type       = "namespace"
    namespaces = ["taskflow"]
  }

  depends_on = [aws_eks_access_entry.github_actions_k8s_cd]
}
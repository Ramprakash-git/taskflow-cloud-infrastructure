data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "eks" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks" {
  name               = "eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks.json
}

resource "aws_iam_role_policy_attachment" "eks" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "eks_nodes" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_nodes" {
  name               = "ec2_node_role"
  assume_role_policy = data.aws_iam_policy_document.eks_nodes.json
}

resource "aws_iam_role_policy_attachment" "workernode" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "ecrpull" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

data "aws_iam_policy_document" "vpc_cni" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpc_cni" {
  name               = "vpc-cni-role"
  assume_role_policy = data.aws_iam_policy_document.vpc_cni.json
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

data "aws_iam_policy_document" "lb_controller" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lb_controller" {
  name               = "controller-role"
  assume_role_policy = data.aws_iam_policy_document.lb_controller.json
}

resource "aws_iam_policy" "lb_controller" {
  name   = "lb_controller_policy"
  policy = file("lb_controller_policy.json")
}

resource "aws_iam_role_policy_attachment" "lb_controller" {
  role       = aws_iam_role.lb_controller.name
  policy_arn = aws_iam_policy.lb_controller.arn
}

data "aws_iam_policy_document" "backend_pod" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:taskflow:taskflow-backend"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "get_secrets" {
  statement {
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]

    resources = [aws_db_instance.postgres_db.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_role" "backend_pod" {
  name               = "backend-pod-role"
  assume_role_policy = data.aws_iam_policy_document.backend_pod.json
}

resource "aws_iam_policy" "get_secrets" {
  name   = "get-secrets-policy"
  policy = data.aws_iam_policy_document.get_secrets.json
}

resource "aws_iam_role_policy_attachment" "backend_pod" {
  role       = aws_iam_role.backend_pod.name
  policy_arn = aws_iam_policy.get_secrets.arn
}

data "aws_iam_policy_document" "github_actions_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:Ramprakash-git@304885229/taskflow-backend@1456259740:ref:refs/heads/master"]
    }
  }
}

data "aws_iam_policy_document" "github_actions_cib_permissions_policy" {
  statement {
    sid       = "ECRAuthentication"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "ECRImagePush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage"
    ]
    resources = [aws_ecr_repository.taskflow_repo.arn]
  }
}

resource "aws_iam_role" "github_actions_cib" {
  name               = "github-actions-cib-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust_policy.json
}

resource "aws_iam_policy" "github_actions_cib" {
  name   = "github-actions-cib-policy"
  policy = data.aws_iam_policy_document.github_actions_cib_permissions_policy.json
}

resource "aws_iam_role_policy_attachment" "github_actions_cib" {
  role       = aws_iam_role.github_actions_cib.name
  policy_arn = aws_iam_policy.github_actions_cib.arn
}

data "aws_iam_policy_document" "github_actions_cdb_permissions_policy" {
  statement {
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = [aws_eks_cluster.main.arn]
  }
}

resource "aws_iam_policy" "github_actions_cdb" {
  name   = "backend-cd-policy"
  policy = data.aws_iam_policy_document.github_actions_cdb_permissions_policy.json
}

resource "aws_iam_role" "github_actions_cdb" {
  name               = "backend-cd-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "github_actions_cdb" {
  role       = aws_iam_role.github_actions_cdb.name
  policy_arn = aws_iam_policy.github_actions_cdb.arn
}

data "aws_iam_policy_document" "github_actions_cdf_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:Ramprakash-git@304885229/taskflow-frontend@1430669413:ref:refs/heads/master"]
    }
  }
}

data "aws_iam_policy_document" "github_actions_cdf_permission_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.main.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.main.arn}/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.main.arn]
  }
}

resource "aws_iam_role" "github_actions_cdf" {
  name               = "frontend-cd-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_cdf_trust_policy.json
}

resource "aws_iam_policy" "github_actions_cdf" {
  name   = "frontend-cd-policy"
  policy = data.aws_iam_policy_document.github_actions_cdf_permission_policy.json
}

resource "aws_iam_role_policy_attachment" "github_actions_cdf" {
  role       = aws_iam_role.github_actions_cdf.name
  policy_arn = aws_iam_policy.github_actions_cdf.arn
}

data "aws_iam_policy_document" "github_actions_k8s_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:Ramprakash-git@304885229/taskflow-kubernetes@1458773049:ref:refs/heads/master"]
    }
  }
}

data "aws_iam_policy_document" "github_actions_k8s_permission_policy" {
  statement {
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = [aws_eks_cluster.main.arn]
  }
}

resource "aws_iam_role" "github_actions_k8s_cd" {
  name               = "github-actions-k8s-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_k8s_trust_policy.json
}

resource "aws_iam_policy" "github_actions_k8s_cd" {
  name   = "github-actions-k8s-policy"
  policy = data.aws_iam_policy_document.github_actions_k8s_permission_policy.json
}

resource "aws_iam_role_policy_attachment" "github_actions_k8s_cd" {
  role       = aws_iam_role.github_actions_k8s_cd.name
  policy_arn = aws_iam_policy.github_actions_k8s_cd.arn
}

data "aws_iam_policy_document" "cluster_autoscaler_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }
  }
}

data "aws_iam_policy_document" "cluster_autoscaler_permission_policy" {

  statement {
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/taskflow-eks"
      values   = ["owned"]
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  name               = "taskflow-cluster-autoscaler-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_trust_policy.json
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name   = "taskflow-cluster-autoscaler-policy"
  policy = data.aws_iam_policy_document.cluster_autoscaler_permission_policy.json
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}


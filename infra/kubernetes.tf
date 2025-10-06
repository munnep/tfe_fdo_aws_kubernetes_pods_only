resource "aws_iam_role" "k8s-cluster" {
  name = "${var.tag_prefix}-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "k8s-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.k8s-cluster.name
}

resource "aws_iam_role_policy_attachment" "k8s-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.k8s-cluster.name
}

resource "aws_iam_role" "k8s-node" {
  name = "${var.tag_prefix}-node"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "k8s-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.k8s-node.name
}

resource "aws_iam_role_policy_attachment" "k8s-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.k8s-node.name
}

resource "aws_iam_role_policy_attachment" "k8s-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.k8s-node.name
}

resource "aws_iam_role_policy_attachment" "k8s-AmazonS3FullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.k8s-node.name
}

resource "aws_iam_role_policy_attachment" "k8s-AmazonEKSComputePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
  role       = aws_iam_role.k8s-node.name
}

resource "aws_iam_role_policy_attachment" "k8s-AmazonEKSLoadBalancingPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
  role       = aws_iam_role.k8s-node.name
}


resource "aws_iam_role_policy_attachment" "k8s-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.k8s-node.name
}

resource "aws_eks_cluster" "k8s" {
  name     = "${var.tag_prefix}-cluster"
  version  = "1.31"
  role_arn = aws_iam_role.k8s-cluster.arn

  vpc_config {
    subnet_ids = [aws_subnet.public1.id, aws_subnet.public2.id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.k8s-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.k8s-AmazonEKSVPCResourceController,
  ]
}

resource "aws_eks_addon" "example" {
  cluster_name = aws_eks_cluster.k8s.name
  addon_name   = "vpc-cni"

  configuration_values = jsonencode({
    "enableNetworkPolicy" = "true"
  })
}


resource "aws_launch_template" "k8-nodes" {
  name = "k8-nodes"

  # Instance Metadata Settings
  metadata_options {
    http_tokens                 = "required" # Can be "optional" or "required"
    http_put_response_hop_limit = 2          # Optional, default is 1
    http_endpoint               = "enabled"  # Can be "enabled" or "disabled"
    http_protocol_ipv6          = "disabled" # Can be "enabled" or "disabled"
    instance_metadata_tags      = "disabled" # Can be "enabled" or "disabled"
  }
}



resource "aws_eks_node_group" "k8s" {
  cluster_name    = aws_eks_cluster.k8s.name
  node_group_name = "${var.tag_prefix}-cluster"
  node_role_arn   = aws_iam_role.k8s-node.arn
  subnet_ids      = [aws_subnet.public1.id, aws_subnet.public2.id]
  instance_types  = ["c5.2xlarge"]

  scaling_config {
    desired_size = var.k8s_desired_size
    max_size     = var.k8s_max_size
    min_size     = var.k8s_min_size
  }

  launch_template {
    id      = aws_launch_template.k8-nodes.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [launch_template]
  }


  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.k8s-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.k8s-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.k8s-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.k8s-AmazonS3FullAccess,
  ]
}

resource "aws_iam_role_policy_attachment" "loadbalancer_cluster" {
  policy_arn = aws_iam_policy.nlb_k8s_policy.arn
  role       = aws_iam_role.k8s-cluster.name
}

resource "aws_iam_role_policy_attachment" "loadbalancer_node" {
  policy_arn = aws_iam_policy.nlb_k8s_policy.arn
  role       = aws_iam_role.k8s-node.name
}


resource "aws_iam_policy" "nlb_k8s_policy" {
  name        = "nlb-k8s-policy"
  description = "IAM policy for Kubernetes to manage Network Load Balancers"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeListeners"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:DescribeSubnets",
          "ec2:DescribeNetworkInterfaces",
          "ec2:AttachNetworkInterface",
          "ec2:DeleteNetworkInterface"
        ],
        Resource = "*"
      }
    ]
  })
}

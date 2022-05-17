locals {
 policy_arn_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"
}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "managed_ng_assume_role_policy" {
  statement {
    sid     = "EKSWorkerAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [ "ec2.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "managed_ng" {
  name                  = "${var.cluster_id}-${local.managed_node_group["node_group_name"]}"
  description           = "EKS Managed Node group IAM Role"
  assume_role_policy    = data.aws_iam_policy_document.managed_ng_assume_role_policy.json
  path                  = var.iam_role_path
  permissions_boundary  = var.iam_role_permissions_boundary
  force_detach_policies = true

  tags = var.tags
}

resource "aws_iam_instance_profile" "managed_ng" {
  role = aws_iam_role.managed_ng.name
  name = "${var.cluster_id}-${local.managed_node_group["node_group_name"]}"
  path = var.iam_role_path

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# TODO - fix at next breaking change
# tflint-ignore: terraform_naming_convention
resource "aws_iam_role_policy_attachment" "managed_ng_AmazonEKSWorkerNodePolicy" {
  policy_arn = "${local.policy_arn_prefix}/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.managed_ng.name
}

# TODO - fix at next breaking change
# tflint-ignore: terraform_naming_convention
resource "aws_iam_role_policy_attachment" "managed_ng_AmazonEKS_CNI_Policy" {
  policy_arn = "${local.policy_arn_prefix}/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.managed_ng.name
}

# TODO - fix at next breaking change
# tflint-ignore: terraform_naming_convention
resource "aws_iam_role_policy_attachment" "managed_ng_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "${local.policy_arn_prefix}/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.managed_ng.name
}

# TODO - fix at next breaking change
# tflint-ignore: terraform_naming_convention
resource "aws_iam_role_policy_attachment" "managed_ng_AmazonSSMManagedInstanceCore" {
  policy_arn = "${local.policy_arn_prefix}/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.managed_ng.name
}

resource "aws_iam_role_policy_attachment" "managed_ng" {
  for_each   = local.eks_worker_policies
  policy_arn = each.key
  role       = aws_iam_role.managed_ng.name
}

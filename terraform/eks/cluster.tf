resource "aws_eks_cluster" "togglemaster_eks" {
  name     = "togglemaster-eks"
  version  = "1.36"
  role_arn = data.aws_iam_role.lab_role.arn

  vpc_config {
    subnet_ids              = data.aws_subnets.default.ids
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }
}
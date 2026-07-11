resource "aws_eks_node_group" "togglemaster_ng" {
  cluster_name    = aws_eks_cluster.togglemaster_eks.name
  node_group_name = "togglemaster-ng"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = data.aws_subnets.default.ids

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]
  disk_size      = 20

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    environment = "academy"
    project     = "togglemaster"
  }

  tags = {
    Project     = "ToggleMaster"
    Environment = "Academy"
  }

  depends_on = [
    aws_eks_cluster.togglemaster_eks
  ]
}
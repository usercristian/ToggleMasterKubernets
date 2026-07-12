resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.togglemaster_eks.name
  addon_name                  = "vpc-cni"
  addon_version               = "v1.21.2-eksbuild.2"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.togglemaster_eks.name
  addon_name                  = "kube-proxy"
  addon_version               = "v1.36.0-eksbuild.7"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.togglemaster_eks.name
  addon_name                  = "coredns"
  addon_version               = "v1.14.2-eksbuild.4"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.togglemaster_ng]
}

resource "aws_eks_addon" "metrics_server" {
  cluster_name                = aws_eks_cluster.togglemaster_eks.name
  addon_name                  = "metrics-server"
  addon_version               = "v0.8.1-eksbuild.11"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.togglemaster_ng]
}

resource "aws_eks_addon" "eks_node_monitoring_agent" {
  cluster_name                = aws_eks_cluster.togglemaster_eks.name
  addon_name                  = "eks-node-monitoring-agent"
  addon_version               = "v1.6.6-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.togglemaster_ng]
}
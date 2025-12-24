module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.19.1"

  cluster_name    = local.cluster_name
  cluster_version = "1.30"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets

  # 允許透過網際網路管理叢集 (kubectl 可直接從電腦連線)
  # 如果你使用 GitHub Actions 或外部的部署工具，通常需要開啟此選項才能將程式碼派送到叢集內。
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
    # AL2 (Amazon Linux 2)  x86_64 架構
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1 # 平時維持 1 台運作
    }
  }
}


###
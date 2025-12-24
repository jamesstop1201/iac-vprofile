# 1. 設定 K8s 連線方式，讓 Terraform 能操作 EKS 內部資源
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}
# 2. 指定 AWS 部署地區
provider "aws" {
  region = var.region
}
# 3. 自動獲取當前區域所有可用的可用區 (AZ) 名單
data "aws_availability_zones" "available" {}
# "aws_availability_zones": 這是外掛程式（Provider）提供的一個功能，專門用來查詢 AZ。


# 4. 統一管理叢集名稱，確保全專案一致
locals {
  cluster_name = var.clusterName
}

##
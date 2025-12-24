module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "vprofile-eks"

# CIDR（Classless Inter-Domain Routing）是用來定義 IP 位址範圍 的一種縮寫格式 。在您的專案中，它決定了網路空間的大小。
  cidr = "172.20.0.0/16"

  # Availability Zones
  # data.aws_availability_zones.available.names: 這是從 AWS 獲取的可用區名稱清單（例如：["us-east-1a", "us-east-1b", "us-east-1c"]）。
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["172.20.1.0/24", "172.20.2.0/24", "172.20.3.0/24"]
  public_subnets  = ["172.20.4.0/24", "172.20.5.0/24", "172.20.6.0/24"]

# VPC 進階網路設定
  enable_nat_gateway   = true   # 讓私有子網路能上網 (下載更新/套件)
  single_nat_gateway   = true   # 只蓋一個 NAT 以節省成本 (適合測試環境)
  enable_dns_hostnames = true   # 讓 VPC 內的資源擁有 DNS 名稱 (K8s 需要)


# shared: 宣告子網歸屬，讓多個 K8s 元件可共用。
# role/elb = 1: 標記為 外網入口，ELB 產生的導航點。
# role/internal-elb = 1: 標記為 內部通道，Internal ELB 產生的導航點。

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

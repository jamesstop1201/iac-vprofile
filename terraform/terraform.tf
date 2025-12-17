terraform {
  # 需要與哪些外部服務進行交互
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.25.0"
    }
# 用於生成隨機值，例如生成資源名稱的後綴，以確保唯一性。
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
# 創建 TLS/SSL 憑證或SSH 密鑰對等資源。
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }
# 生成 Cloud-Init 配置檔案，這些檔案通常用於在 EC2 實例首次啟動時執行自定義腳本（例如配置 EKS Worker Nodes）。
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3.2"
    }
# 用於在 EKS 叢集創建完成後，部署 Kubernetes 資源，例如 Pods、Deployments、Services 或 Ingress 資源。
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
  }

# 後端狀態管理
  backend "s3" {
    bucket = "vprofileactions1201"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }

  required_version = "~> 1.6.3"
}
##
##
##

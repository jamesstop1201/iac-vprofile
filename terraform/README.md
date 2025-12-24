* **`~>`** 符號被稱為 悲觀約束操作符 (Pessimistic Constraint Operator) 。它主要用於版本控制，確保在升級套件時既能獲得更新，又不會因為重大版本更動（Breaking Changes）而導致基礎設施崩潰。


* source = "hashicorp/aws" 指的是該 Provider（供應商軟體包）在 Terraform Registry 上的官方路徑 。


# Terraform EKS 專案編寫邏輯

這份架構遵循「環境規範 > 網路底層 > 運算核心 > 認證輸出」的順序進行編排。

---

## 第一階段：環境規範與變數 (Setup)
**目標：定義「用什麼工具」以及「環境參數」。**

* **`terraform.tf`**
    * 宣告所需的 **Required Providers** (如 `aws`, `kubernetes`, `random` 等) 。
    * 設定版本約束（如 `~> 5.25.0`）以確保環境穩定 。
    * 配置 **Backend "s3"**，將狀態檔存放於雲端進行協作管理 。
* **`variables.tf`**
    * 定義全域變數，如 `region` (預設 `us-east-1`) 。
    * 定義 `clusterName` (預設 `vprofile-eks`)，增加代碼的靈活性與重用性 。

---

## 第二階段：網路地基 (Networking)
**目標：建立一個符合 Kubernetes 需求的網路空間。**

* **`vpc.tf`**
    * 建立 VPC 並劃分 **Public Subnets** 與 **Private Subnets** 。
    * **關鍵細節**：在子網加上專屬標籤（如 `kubernetes.io/role/elb`），這能讓 K8s 之後自動識別在哪裡建立負載均衡器 。
    * **順序邏輯**：必須先有 VPC 網路，後續的 EKS 才能安放 。

---

## 第三階段：集群主體 (Core Cluster)
**目標：啟動 K8s 控制面 (Master) 與工作節點 (Worker Nodes)。**

* **`eks-cluster.tf`**
    * 引用 `vpc.tf` 產出的 `vpc_id` 和 `subnet_ids` 。
    * 定義 **EKS Managed Node Groups**，設定節點的執行個體類型（如 `t3.small`）與縮放數量（Min/Max/Desired） 。
    * **順序邏輯**：控制面啟動完成後，工作節點才會自動加入集群。

---

## 第四階段：驗證與連線輸出 (Access & Output)
**目標：授權 Terraform 管理集群並顯示連線資訊。**

* **`main.tf`**
    * 配置 **Kubernetes Provider**，透過解碼後的集群憑證 (`cluster_ca_certificate`) 與端點 (`host`) 建立連線 。
    * 這讓 Terraform 具備在集群內部部署 Kubernetes 資源的能力。
* **`outputs.tf`**
    * 定義要顯示在終端機的資訊，如 `cluster_endpoint` 和 `cluster_name` 。
    * 這些資訊用於確認部署成功，並供外部工具（如 `kubectl`）連線使用。

---

## 編寫流程總結
**`terraform.tf` (規範)** → **`vpc.tf` (空間)** → **`eks-cluster.tf` (主體)** → **`main.tf` / `outputs.tf` (連接)**



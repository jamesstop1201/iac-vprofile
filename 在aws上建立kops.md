# 手動建立 kops Instance 步驟指南

## 一、 AWS 基礎資源設定

### 1. 建立 EC2 Instance
* **名稱 (Name Tag)**: `kops`
* **動作**: 在 AWS 控制台啟動一個新的執行個體，作為管理主機。

### 2. 建立 Key Pair
* **名稱**: 自訂 (例如 `kops-key`)
* **金鑰類型**: `RSA`
* **私鑰檔案格式**: `.pem`

### 3. 建立安全群組 (Security Group)
* **名稱**: `kops-sg`
* **傳入規則 (Inbound Rules)**:
    * **類型**: `SSH`
    * **通訊協定**: `TCP`
    * **埠號**: `22`
    * **來源**: `My IP` (僅允許您目前的網路環境連線，確保安全性)
---

<div style="page-break-after: always;"></div>

## 二、 IAM 使用者與權限管理

### 4. 建立 IAM 使用者
* **使用者名稱**: `kopsadmin`
* **設定權限**: 選擇 **"Attach policies directly"** (直接連接政策)。
* **權限策略**: 勾選 `AdministratorAccess`。
    * > **為何需要此權限？**
    * > 因為 `kops` 在自動化部署 Kubernetes 叢集時，需要完整的權限來建立與管理多項 AWS 資源，包括 EC2 執行個體、Auto Scaling Groups、VPC 網路設定、S3 儲存桶、Route53 域名記錄以及 IAM Roles 等。

### 5. 建立存取金鑰 (Access Key)
* **路徑**: 進入 `kopsadmin` 使用者頁面 -> **Security credentials** (安全憑證) 頁籤。
* **動作**: 點擊 **Create access key**。
* **使用案例**: 選擇 **Command Line Interface (CLI)**。
* **結果**: 建立後請務必下載或記錄 `Access Key ID` 與 `Secret Access Key`，後續在 CLI 設定時會用到。

---

## 三、 環境配置與工具安裝 (Terminal 操作)

### 6. 系統初始化與更新
使用 SSH 登入 Instance 後，執行以下指令：
```bash
# 切換為 root 權限
sudo -i 

# 更新系統套件清單
apt update
```

### 7. 安裝與設定 AWS CLI
在 Instance 中安裝 AWS 命令列工具，並配置先前建立的 `kopsadmin` 憑證：
```bash
# 使用 snap 安裝 AWS CLI
snap install aws-cli --classic

# 設定認證資訊
aws configure
# 請依照提示輸入以下資訊：
# AWS Access Key ID [None]: (輸入 kopsadmin 的 Access Key)
# AWS Secret Access Key [None]: (輸入 kopsadmin 的 Secret Key)
# Default region name [None]: (例如 ap-northeast-1)
# Default output format [None]: json
```

### 8. 產生 SSH Key
此金鑰將用於 kops 建立叢集時，自動派送至 Master 與 Worker 節點以供後續登入：

```bash
# 執行產生金鑰指令
ssh-keygen

# 提示儲存路徑與密碼時，直接按 Enter 即可（預設存於 ~/.ssh/id_rsa）
```

### 9. 安裝 kops
下載 kops 二進位檔案並設定為可執行：

```bash
# 自動抓取最新版本並下載 kops 二進位檔
curl -Lo kops [https://github.com/kubernetes/kops/releases/download/$(curl](https://github.com/kubernetes/kops/releases/download/$(curl) -s [https://api.github.com/repos/kubernetes/kops/releases/latest](https://api.github.com/repos/kubernetes/kops/releases/latest) | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64

# 賦予執行權限
chmod +x kops

# 將 kops 移動至系統執行路徑，以便在任何地方呼叫
sudo mv kops /usr/local/bin/kops
```

### 10. 安裝 kubectl
下載 Kubernetes 的命令列管理工具：

```bash
# 下載最新穩定版 kubectl 執行檔
curl -LO "[https://dl.k8s.io/release/$(curl](https://dl.k8s.io/release/$(curl) -L -s [https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl](https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl)"

# 使用 install 指令設定權限、擁有者並安裝至 /usr/local/bin
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

## 四、 安裝完成檢查

完成上述步驟後，請執行以下指令驗證工具是否已正確安裝且可以正常執行：

```bash
# 檢查 kops 版本
kops version

# 檢查 kubectl 用戶端版本
kubectl version --client
```

### 五、 建立與更新 kops 叢集

#### 1. 建立叢集配置 (Create Cluster)
使用此指令定義叢集的名稱、狀態儲存庫、可用區以及節點規格：

```bash
kops create cluster \
  --name=kubevpro.hkhinfoteck.xyz \
  --state=s3://kubrvpro89 \
  --zones=us-east-1a,us-east-1b \
  --node-count=2 \
  --node-size=t3.small \
  --control-plane-size=t3.medium \
  --dns-zone=kubevpro.hkhinfoteck.xyz \
  --node-volume-size=12 \
  --control-plane-volume-size=12 \
  --ssh-public-key ~/.ssh/id_ed25519.pub
```

#### 2. 執行並部署叢集 (Update Cluster)
確認配置無誤後，執行以下指令正式在 AWS 上建立資源：

```Bash

kops update cluster \
  --name=kubevpro.hkhinfoteck.xyz \
  --state=s3://kubrvpro89 \
  --yes \
  --admin
```
---

### 指令參數說明：
* **`--name`**: 叢集的完整域名名稱。
* **`--state`**: 存放叢集狀態的 S3 儲存桶路徑。
* **`--zones`**: 指定部署的 AWS 可用區（如 `us-east-1a`,`us-east-1b`）。
* **`--node-count`**: Worker 節點的數量（此處設為 2）。
* **`--node-size`**: Worker 節點的實例類型（`t3.small`）。
* **`--control-plane-size`**: 控制平面（Master）節點的實例類型（`t3.medium`）。
* **`--dns-zone`**: 用於叢集服務發現的 DNS 區域。
* **`--ssh-public-key`**: 指定登入節點所使用的 SSH 公鑰路徑。
* **`--yes`**: 確認執行所有變更。
* **`--admin`**: 自動將管理員憑證加入到當前的 `kubeconfig` 中。

## 六、 建立與更新 kops 叢集
### 11. 建立 S3 Bucket (kops 狀態儲存庫)
kops 需要一個 S3 儲存桶來存放叢集的配置與狀態資訊（State Store）。

* **儲存體類型**: `General purpose`
* **設定名稱**: 例如 `kubrvpro89` (名稱需全球唯一)。
* **設定步驟**:
    1. 進入 S3 控制台，點擊 **Create bucket**。
    2. 輸入 **Bucket name**。
    3. 其他選項保持預設值，直接拉到最下方點擊 **Create bucket**。

---

### 12. 設定 Route 53 託管區域
#### 什麼是 Route 53？
Amazon Route 53 是一項具備高可用性與擴展性的雲端 **網域名稱系統 (DNS)** 網路服務。它的主要作用是將人類可讀的網址（如 `example.com`）翻譯成電腦連接所需的 IP 地址（如 `192.0.2.1`）。在 kops 中，Route 53 用於管理叢集內部節點的通訊以及外部服務的存取路徑。

#### 設定步驟：
如果你在 GoDaddy 已有自己的 Domain，請依照以下步驟在 AWS 建立子網域託管：

1. **建立 Hosted Zone**:
    * 進入 Route 53 控制台，點擊 **Create hosted zone**。
    * **Domain name**: 設定一個子網域名稱，例如 `kubevpro.yourdomain.com` (將 `yourdomain.com` 替換為你在 GoDaddy 購買的域名)。
    * **Type**: 選擇 `Public hosted zone`。
    * 點擊 **Create hosted zone**。

2. **後續動作 (重要)**:
    * 創建完成後，AWS 會提供 4 組 **NS (Name Server)** 紀錄。
    * 你需要回到 GoDaddy 的管理介面，將這 4 組 NS 紀錄新增到你的域名設定中，完成 DNS 授權轉移。
---
### DNS 子網域委派手冊：GoDaddy 轉接 Route 53

本文件說明如何將 GoDaddy 管理的父網域委派給 AWS Route 53，以便 kOps 自動管理 Kubernetes 叢集紀錄。

---

## 💡 為什麼要委派？
因為 Kubernetes 叢集的 DNS 紀錄（如 `api.kubevpro...`）由 kOps 在 **AWS Route 53** 自動建立。若不設定委派，**GoDaddy** 就無法指引流量找到這些位於 AWS 的關鍵 IP。

---

## 🛠 設定步驟

### Step 1：AWS Route 53 建立託管區域
1. **建立 Hosted Zone**：名稱設為 `kubevpro.hkinfoteck.xyz`。
2. **獲取 NS 紀錄**：建立後，AWS 會自動產生 **4 組 Name Servers (NS)**（例如 `ns-xxx.awsdns-xx.com`）。
3. **功能**：這 4 個 Server 將成為該子網域的權威 DNS，負責未來所有的 API 與 Master 紀錄。

### Step 2：GoDaddy 設定 DNS 委派
1. **進入管理介面**：登入 GoDaddy，進入父網域 `hkinfoteck.xyz` 的 DNS 管理。
2. **新增 NS 紀錄**（需重複 4 次，對應 AWS 的 4 組 Server）：
   * **Type (類型)**: `NS`
   * **Name (名稱)**: `kubevpro`
   * **Value (數值)**: 填入 Route 53 提供的 Name Server 位址。
3. **儲存並等待**：等待 DNS 傳播（通常 5-30 分鐘）。

---

## 🔍 解析流程圖解



1. **查詢請求**：訪問 `api.kubevpro.hkinfoteck.xyz`。
2. **父域回應**：GoDaddy 告知查詢者：「請去問 AWS Route 53，它們負責 `kubevpro`」。
3. **子域回應**：Route 53 回傳由 kOps 建立的 Master Node 真實 IP。
4. **解析成功**：`kubectl` 順利連線至叢集 API。

---

## ✅ 完成標準
- **GoDaddy**：已存在 4 筆指向 AWS 的 `kubevpro` NS 紀錄。
- **Route 53**：Hosted Zone 已建立並包含 kOps 產生的 A 紀錄。
- **連線測試**：`api.kubevpro.hkinfoteck.xyz` 可被正確解析。

### 七、 叢集狀態驗證 (Validate Cluster)
---
在執行完部署指令後，通常需要等待 **5 - 10 分鐘** 讓 AWS 實例啟動。請執行以下指令來確認叢集的所有節點（Master & Nodes）是否都已進入 `Ready` 狀態。

#### 驗證指令
```bash
kops validate cluster \
  --name=kubevpro.hkhinfoteck.xyz \
  --state=s3://kubrvpro89
```

### 八、 刪除 kops 叢集 (Delete Cluster)

為了節省成本，當叢集使用完畢後，應確實執行刪除指令。這將會移除該叢集在 AWS 上建立的所有資源（包含 VPC、EC2、ELB 等）。

#### 1. 預覽刪除 (Preview Delete)
先執行此指令確認即將被刪除的資源列表，此步驟**不會**實際動作：
```bash
kops delete cluster \
  --name=kubevpro.hkhinfoteck.xyz \
  --state=s3://kubrvpro89
  --yes
```
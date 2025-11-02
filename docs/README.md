
## Note Triển Khai FastAPI lên Azure AKS bằng DevOps

Quy trình này mô tả cách sử dụng Terraform để tạo cơ sở hạ tầng (Infrastructure as Code), Docker để đóng gói ứng dụng, và GitHub Actions cho CI/CD (Tích hợp liên tục/Triển khai liên tục).

### Phần 1: Chuẩn Bị Công Cụ (Prerequisites)

Để bắt đầu, bạn cần đảm bảo các công cụ sau đã được cài đặt trên hệ thống của mình:

| Công cụ | Mục đích | Hướng dẫn kiểm tra | Nguồn |
| :--- | :--- | :--- | :--- |
| **Python** | Ngôn ngữ lập trình cho FastAPI. | `python --version` | |
| **Docker** | Đóng gói ứng dụng thành container. | `docker --version` | |
| **Azure CLI (az)** | Giao diện dòng lệnh để quản lý tài nguyên Azure. | `az --version` | |
| **Terraform** | Công cụ IaC (Infrastructure as Code) để định nghĩa tài nguyên Azure. | `terraform --version` | |
| **Tài khoản Azure** | Cần có tài khoản Microsoft Azure (lần đầu sử dụng có thể được cấp $200 miễn phí). | | |

**Lưu ý cho người dùng Windows:** Nếu bạn đang dùng Windows, bạn nên cài đặt WSL (Windows Subsystem for Linux) để sử dụng dòng lệnh Ubuntu, giúp việc chạy các lệnh DevOps được thuận tiện hơn.

#### Hướng dẫn Code (Kết nối Azure)
Sau khi cài Azure CLI, bạn cần đăng nhập vào tài khoản Azure của mình:
```bash
az login
```
Lệnh này sẽ mở trình duyệt để bạn xác thực tài khoản. Sau khi đăng nhập thành công, bạn có thể kiểm tra kết nối.

***

### Phần 2: Cấu Trúc Dự Án và FastAPI Cơ Bản

Tạo một cấu trúc thư mục tiêu chuẩn cho dự án DevOps, bao gồm:

*   `app/main.py` (Mã nguồn FastAPI)
*   `infrastructure/terraform` (Code Terraform)
*   `infrastructure/kubernetes` (File cấu hình K8s)
*   `Dockerfile`
*   `.github/workflows` (File GitHub Actions)

#### Hướng dẫn Code (FastAPI)

1.  **Cài đặt Fast API và Uvicorn:**
    ```bash
    pip install fastapi uvicorn
    ```
    (Bạn nên kích hoạt môi trường ảo trước: `source venv/bin/activate`).
2.  **Tạo `app/main.py`:** Đây là ứng dụng Hello World đơn giản.
    ```python
    from fastapi import FastAPI
    app = FastAPI()

    @app.get("/")
    def read_root():
        # Trả về thông điệp đơn giản
        return {"Hello": "DevOps World"} #
    ```

***

### Phần 3: Docker Hóa Ứng Dụng

Tạo file `Dockerfile` để đóng gói ứng dụng FastAPI, cho phép nó chạy trên mọi môi trường, bao gồm cả Kubernetes.

#### Hướng dẫn Code (`Dockerfile`)

```dockerfile
# Sử dụng base image Python slim
FROM python:3.10-slim-buster #

# Đặt thư mục làm việc trong container
WORKDIR /app #

# Sao chép và cài đặt các dependencies (giả định dùng requirements.txt)
# (Các nguồn sử dụng lệnh RUN pip installation configuration)

# Sao chép tất cả các file từ thư mục hiện tại vào container
COPY . /app #

# Lệnh chạy ứng dụng sử dụng Uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"] #
```
Lưu ý: `app.main:app` chỉ ra rằng ứng dụng FastAPI (`app`) nằm trong module `main` trong thư mục `app`.

***

### Phần 4: Định Nghĩa Cơ Sở Hạ Tầng bằng Terraform

Trong thư mục `infrastructure/terraform`, bạn tạo file `main.tf`. File này định nghĩa các tài nguyên cốt lõi cần thiết trên Azure.

Các tài nguyên chính bao gồm:
1.  **Azure Resource Group (Nhóm Tài Nguyên)**: Nhóm chứa tất cả các tài nguyên.
2.  **Azure Container Registry (ACR)**: Nơi lưu trữ Docker Images.
3.  **Azure Kubernetes Service (AKS) Cluster**: Cụm Kubernetes để chạy ứng dụng.

#### Hướng dẫn Code (`main.tf` - Tổng hợp Cấu trúc)
```t
# Định nghĩa Provider (azurerm)
provider "azurerm" {
    features {} #
    # subscription_id = "<YOUR_SUBSCRIPTION_ID>" # Định nghĩa ID đăng ký
}

# 1. Resource Group
resource "azurerm_resource_group" "fast_api_rg" {
    name     = "fast-api-Resource-Group" #
    location = "East US" # Tùy chọn vị trí
}

# 2. Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
    name                = "fastapicr12345" # Tên phải là duy nhất (unique name)
    resource_group_name = azurerm_resource_group.fast_api_rg.name #
    location            = azurerm_resource_group.fast_api_rg.location #
    sku                 = "Basic" #
    admin_enabled       = true # Cho phép quản trị viên
}

# 3. Azure Kubernetes Service (AKS) Cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
    name                = "fast-api-aks-cluster" #
    location            = azurerm_resource_group.fast_api_rg.location #
    resource_group_name = azurerm_resource_group.fast_api_rg.name #
    dns_prefix          = "fast-api" #

    default_node_pool {
        name            = "default" #
        node_count      = 2 # Số lượng node
        vm_size         = "Standard_DS2_v2" # Kích thước máy ảo
    }
    identity {
        type = "SystemAssigned" #
    }
    # Thêm cấu hình cấp quyền (Role Assignment) để AKS có thể pull image từ ACR
    # ...
}
```

***

### Phần 5: Triển Khai Cơ Sở Hạ Tầng lên Azure

Sau khi định nghĩa `main.tf`, bạn sử dụng Terraform để tạo các tài nguyên trên Azure.

#### Hướng dẫn Code (Lệnh Terraform)
Trong thư mục chứa `main.tf` (`infrastructure/terraform`):

1.  **Khởi tạo Terraform:** Tải xuống các plugin cần thiết.
    ```bash
    terraform init #
    ```
2.  **Áp dụng cấu hình:** Tạo các tài nguyên (Resource Group, ACR, AKS) trên Azure. Lệnh `-auto-approve` bỏ qua bước xác nhận thủ công.
    ```bash
    terraform apply -auto-approve #
    ```
Quá trình này sẽ mất một khoảng thời gian để Azure tạo các tài nguyên. Sau khi hoàn thành, bạn có thể thấy các tài nguyên đã được tạo trong dashboard Azure.

***

### Phần 6: Xây Dựng và Đẩy (Push) Docker Image

Sau khi có ACR, bạn cần xây dựng Docker image của ứng dụng FastAPI và đẩy nó vào ACR để Kubernetes có thể truy cập.

#### Hướng dẫn Code (Docker & ACR)

1.  **Đăng nhập vào ACR:** Sử dụng Azure CLI để đăng nhập vào Container Registry (thay `<ACR_NAME>` bằng tên bạn đã định nghĩa trong Terraform, ví dụ `fastapicr12345`).
    ```bash
    az acr login --name <ACR_NAME> #
    ```
2.  **Xây dựng Image:** Chạy lệnh này trong thư mục gốc của dự án (nơi có `Dockerfile`).
    ```bash
    # Sử dụng tên ACR làm tiền tố cho tag
    docker build -t <ACR_NAME>.azurecr.io/fastapi-app:latest . #
    ```
3.  **Đẩy Image lên ACR:**
    ```bash
    docker push <ACR_NAME>.azurecr.io/fastapi-app:latest #
    ```

***

### Phần 7: Cấu Hình Kubernetes (K8s)

Để AKS Cluster chạy ứng dụng, bạn cần cung cấp hai file YAML: `deployment.yaml` (để chạy container) và `service.yaml` (để expose ứng dụng).

#### Hướng dẫn Code (Kết nối Kubectl)

Trước hết, lấy thông tin xác thực để Kubectl có thể quản lý AKS Cluster vừa tạo:
```bash
az aks get-credentials --resource-group fast-api-Resource-Group --name fast-api-aks-cluster #
```

#### Hướng dẫn Code (Triển khai K8s)

1.  **Tạo `deployment.yaml` (trong `infrastructure/kubernetes`):**
    File này định nghĩa Image cần sử dụng và cổng hoạt động (Port 80).
    *(Lưu ý: Nội dung YAML chi tiết được tham khảo từ cấu trúc K8s thông thường, vì nguồn chỉ nhắc đến việc copy/paste file này).*
    ```yaml
    # Deployment YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: fast-api-deployment
    spec:
      replicas: 2
      template:
        spec:
          containers:
          - name: fast-api-container
            image: <ACR_NAME>.azurecr.io/fastapi-app:latest # Image từ ACR
            ports:
            - containerPort: 80 #
    # ...
    ```

2.  **Tạo `service.yaml` (trong `infrastructure/kubernetes`):**
    File này định nghĩa Service để công khai ứng dụng ra bên ngoài, sử dụng loại `LoadBalancer` để nhận được một IP công khai.
    ```yaml
    # Service YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: fast-api-service #
    spec:
      type: LoadBalancer # Cấp External IP
      ports:
      - port: 80 #
        targetPort: 80
      # ...
    ```

3.  **Áp dụng các file YAML:**
    ```bash
    # Triển khai Deployment
    kubectl apply -f deployment.yaml #

    # Triển khai Service
    kubectl apply -f service.yaml #
    ```
4.  **Kiểm tra External IP:** Chờ vài phút để LoadBalancer được cấp IP công khai.
    ```bash
    kubectl get svc #
    ```
Khi có IP, bạn truy cập địa chỉ đó trên trình duyệt để thấy ứng dụng FastAPI đang chạy.

***

### Phần 8: Thiết Lập CI/CD với GitHub Actions

Mục tiêu là tự động hóa các bước (xây dựng Docker Image, Push lên ACR, và Deploy lên K8s) mỗi khi có thay đổi code được push lên GitHub.

#### Hướng dẫn Code (Thiết lập Secret)

GitHub Actions cần quyền truy cập vào Azure. Chúng ta sử dụng Azure Service Principal (SPN) để tạo thông tin xác thực (Client ID, Secret Key, Tenant ID).

1.  **Tạo Service Principal (SPN):** Bạn cần chạy lệnh `az ad sp create-for-rbac` trong Azure CLI. Lệnh này nên chỉ định quyền Contributor và Scope là Subscription ID hoặc Resource Group của bạn.
    *(Lệnh này có thể phức tạp và phải đảm bảo cú pháp chính xác)*.

2.  **Lưu Secret trên GitHub:**
    *   Truy cập **Settings** của Repository trên GitHub > **Secrets** > **Actions**.
    *   Tạo Secret mới (ví dụ: `AZURE_CREDENTIALS` hoặc tên biến tùy chọn khác).
    *   Dán chuỗi JSON kết quả từ lệnh tạo SPN vào giá trị của Secret này.

#### Hướng dẫn Code (Workflow YAML)

Tạo file `deploy.yaml` trong thư mục `.github/workflows/`. Workflow này sẽ thực hiện: đăng nhập Azure, build Docker image, push image lên ACR, và cập nhật Deployment trên AKS.

```yaml
# Cấu trúc cơ bản của file GitHub Actions deploy.yaml
name: Deploy Fast API to AKS

on:
  push:
    branches:
      - main # Chạy khi push lên nhánh main

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      # 1. Checkout code
      - uses: actions/checkout@v3

      # 2. Đăng nhập vào Azure
      - uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }} # Sử dụng Secret đã tạo
      
      # 3. Xây dựng và đẩy Docker Image
      - name: Build and push image to ACR
        uses: azure/docker-login@v1
        # ... cấu hình ACR
      - run: docker build -t <ACR_NAME>.azurecr.io/fastapi-app:latest . #
      - run: docker push <ACR_NAME>.azurecr.io/fastapi-app:latest #

      # 4. Thiết lập Kubectl và Deploy lên AKS
      - uses: azure/aks-set-context@v1
        with:
          # Cấu hình cụm AKS (Sử dụng Resource Group và Cluster Name)
          resource-group: fast-api-Resource-Group 
          cluster-name: fast-api-aks-cluster
      
      # 5. Áp dụng cấu hình K8s (deployment.yaml và service.yaml)
      - run: kubectl apply -f infrastructure/kubernetes/deployment.yaml #
      - run: kubectl apply -f infrastructure/kubernetes/service.yaml #
      # ... (Có thể cần lệnh restart hoặc kiểm tra trạng thái)
```
Sau khi push cấu hình này lên GitHub, GitHub Actions sẽ tự động chạy và triển khai ứng dụng của bạn.
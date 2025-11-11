# 1. Base Image
FROM python:3.10-slim-buster

# Thiết lập biến môi trường để pip không lưu cache (giúp giảm kích thước image)
ENV PIP_NO_CACHE_DIR=1

# Thiết lập thư mục làm việc trong container
WORKDIR /app

# Thêm env
ENV PINECONE_API_KEY="{{PINECONE_API_KEY}}"
ENV GOOGLE_API_KEY="{{GOOGLE_API_KEY}}"

# --- CÀI ĐẶT CÁC PHỤ THUỘC (DEPENDENCIES) ---

# 2. Sao chép các tệp cấu hình cần thiết để cài đặt dependencies
# pyproject.toml chứa danh sách dependencies và cấu hình build
COPY pyproject.toml .
# setup.cfg (Nếu có, nó chứa thông tin gói như find_packages)
COPY setup.cfg . 

# 3. Cài đặt Gói nội bộ và TẤT CẢ Dependencies
# Lệnh 'pip install -e .' đọc pyproject.toml để biết cần cài đặt những thư viện nào.
# Nó cài đặt gói nội bộ 'analytics-chatbot' dưới dạng editable.
RUN pip install -e .

# --- SAO CHÉP MÃ NGUỒN CÒN LẠI ---

# 4. Sao chép toàn bộ mã nguồn của dự án
# Bạn nên đảm bảo có file .dockerignore để loại trừ các file không cần thiết
COPY backend /app/backend
COPY main.py /app/

# --- CẤU HÌNH KHỞI ĐỘNG (Cho FastAPI/Uvicorn) ---

# 5. Mở cổng mà ứng dụng lắng nghe
EXPOSE 8000

# 6. Lệnh chạy Uvicorn
# Thay thế 'main:app' bằng module và tên app object thực tế của bạn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
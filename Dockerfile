FROM python:3.10-slim-buster

# Thiết lập biến môi trường để pip không lưu cache
ENV PIP_NO_CACHE_DIR=1

WORKDIR /app

# Sử dụng ARG để nhận các giá trị từ lúc build
ARG PINECONE_API_KEY
ARG GOOGLE_API_KEY
ENV PINECONE_API_KEY=${PINECONE_API_KEY}
ENV GOOGLE_API_KEY=${GOOGLE_API_KEY}

# Sao chép các file cấu hình
COPY pyproject.toml .
COPY setup.cfg .

# Cài đặt dependencies
RUN pip install -e .

# Sao chép mã nguồn
COPY backend /app/backend
COPY main.py /app/

# Mở cổng và chạy Uvicorn
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

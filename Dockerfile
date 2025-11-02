FROM python:3.11-slim

WORKDIR /app

COPY requirement.txt .

RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirement.txt

COPY . .

RUN ls -la /app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
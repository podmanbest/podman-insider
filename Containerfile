# Stage 1: Builder
FROM python:3.11-slim AS builder
WORKDIR /build
COPY app/requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Runtime (Rootless)
FROM python:3.11-slim

# 1. Buat user non-root dengan UID spesifik (misal 1001)
# Ini mencegah masalah permission di volume mount
RUN groupadd -r appuser -g 1001 && \
    useradd -r -g appuser -u 1001 -m -s /sbin/nologin appuser

# 2. Salin library dari builder
COPY --from=builder /root/.local /root/.local
# 3. Salin kode aplikasi
COPY --chown=appuser:appuser app/ /app/
COPY --chown=appuser:appuser config/ /app/config/

# 4. Setup Env
ENV PATH=/root/.local/bin:$PATH
USER appuser
WORKDIR /app

# Gunakan port tinggi
EXPOSE 8080
CMD ["python", "main.py"]

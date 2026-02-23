# Implementasi Praktis (Isi File)

Berikut adalah contoh isi file penting agar proyek ini bisa langsung dijalankan dan didaur ulang.

## A. Containerfile (Rootless Optimized)

```dockerfile

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
```

## B. Makefile (Otomasi)

File ini membuat developer tidak perlu menghafal perintah Podman.

```makefile

# Variable

APP_NAME = my-awesome-app
IMAGE_TAG = localhost/$(APP_NAME):dev
POD_NAME = dev-pod
CONTAINER_NAME = $(APP_NAME)-ctr

.PHONY: build run stop gen-k8s help

help: ## Tampilkan bantuan
@echo "Available commands:"
@grep -E '^[a-zA-Z_-]+:._?## ._$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.\*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build image rootless
podman build -t $(IMAGE_TAG) -f Containerfile .

run: build ## Jalankan pod dan container (Simulasi K8s)
@echo "Membuat Pod..."
@podman pod exists $(POD_NAME) || podman pod create --name $(POD_NAME) -p 8080:8080
@echo "Menjalankan Container..."
@podman run -d --pod $(POD_NAME) --name $(CONTAINER_NAME) --restart on-failure $(IMAGE_TAG)
@echo "Aplikasi berjalan di http://localhost:8080"

stop: ## Hapus pod dan container
-podman rm -f $(CONTAINER_NAME)
-podman pod rm -f $(POD_NAME)

logs: ## Lihat logs container
podman logs -f $(CONTAINER_NAME)

gen-k8s: ## Generate YAML K8s dari state Podman saat ini
@echo "Generating K8s Manifests..."
podman generate kube $(POD_NAME) | tee deploy/k8s/base/deployment.yaml
@echo "Manifest disimpan di deploy/k8s/base/deployment.yaml"
@echo "Silakan edit file tersebut dan pisahkan Service jika perlu."
```

## C. deploy/k8s/base/kustomization.yaml

File ini menginstruksikan Kustomize untuk membaca file yang kita generate.

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
# Resources mengarah ke file hasil generate Podman

resources:
  - deployment.yaml

# Common labels untuk semua resource
commonLabels:
app: my-awesome-app
env: base
```

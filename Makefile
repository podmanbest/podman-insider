# Variable — Aplikasi
APP_NAME = my-awesome-app
IMAGE_TAG = localhost/$(APP_NAME):dev
POD_NAME = dev-pod
CONTAINER_NAME = $(APP_NAME)-ctr

# Variable — Docs (contoh praktek: panduan Markdown di container)
DOCS_APP_NAME = podman-rootless-k8s-docs
DOCS_IMAGE_TAG = localhost/$(DOCS_APP_NAME):dev
DOCS_POD_NAME = docs-pod
DOCS_CONTAINER_NAME = $(DOCS_APP_NAME)-ctr

.PHONY: build run stop gen-k8s help build-docs run-docs stop-docs gen-k8s-docs logs logs-docs

help: ## Tampilkan bantuan
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# --- Aplikasi (app) ---
build: ## Build image aplikasi rootless
	podman build -t $(IMAGE_TAG) -f Containerfile .

run: build ## Jalankan pod dan container aplikasi (Simulasi K8s)
	@echo "Membuat Pod..."
	@podman pod exists $(POD_NAME) || podman pod create --name $(POD_NAME) -p 8080:8080
	@echo "Menjalankan Container..."
	@podman run -d --pod $(POD_NAME) --name $(CONTAINER_NAME) --restart on-failure $(IMAGE_TAG)
	@echo "Aplikasi berjalan di http://localhost:8080"

stop: ## Hapus pod dan container aplikasi
	-podman rm -f $(CONTAINER_NAME)
	-podman pod rm -f $(POD_NAME)

logs: ## Lihat logs container aplikasi
	podman logs -f $(CONTAINER_NAME)

gen-k8s: ## Generate YAML K8s dari pod aplikasi saat ini
	@echo "Generating K8s Manifests (app)..."
	podman generate kube $(POD_NAME) | tee deploy/k8s/base/deployment.yaml
	@echo "Manifest disimpan di deploy/k8s/base/deployment.yaml"
	@echo "Silakan edit file tersebut dan pisahkan Service jika perlu."

# --- Docs (contoh praktek: panduan di container) ---
build-docs: ## Build image yang berisi panduan Markdown (rootless)
	podman build -t $(DOCS_IMAGE_TAG) -f Containerfile.docs .

run-docs: build-docs ## Jalankan pod + container docs; akses http://localhost:8080
	@echo "Membuat Pod docs..."
	@podman pod exists $(DOCS_POD_NAME) || podman pod create --name $(DOCS_POD_NAME) -p 8080:8080
	@echo "Menjalankan Container docs..."
	@podman run -d --pod $(DOCS_POD_NAME) --name $(DOCS_CONTAINER_NAME) --restart on-failure $(DOCS_IMAGE_TAG)
	@echo "Panduan tersedia di http://localhost:8080 (indeks: /index.html, docs: /docs/)"

stop-docs: ## Hentikan pod dan container docs
	-podman rm -f $(DOCS_CONTAINER_NAME)
	-podman pod rm -f $(DOCS_POD_NAME)

logs-docs: ## Lihat logs container docs
	podman logs -f $(DOCS_CONTAINER_NAME)

gen-k8s-docs: ## Generate YAML K8s dari pod docs (untuk deploy ke cluster)
	@echo "Generating K8s Manifests (docs)..."
	@mkdir -p deploy/k8s/base
	podman generate kube $(DOCS_POD_NAME) | tee deploy/k8s/base/docs-deployment.yaml
	@echo "Manifest disimpan di deploy/k8s/base/docs-deployment.yaml"

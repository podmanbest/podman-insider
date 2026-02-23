# Variable
APP_NAME = my-awesome-app
IMAGE_TAG = localhost/$(APP_NAME):dev
POD_NAME = dev-pod
CONTAINER_NAME = $(APP_NAME)-ctr

.PHONY: build run stop gen-k8s help

help: ## Tampilkan bantuan
    @echo "Available commands:"
    @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

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

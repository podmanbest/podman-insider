## Pohon Direktori Proyek

Struktur yang ada di repo (tanpa phantom):

```
podman-rootless-k8s/
├── app/                       # Source Code Aplikasi
│   ├── main.py
│   ├── requirements.txt
│   └── ...
├── config/                    # Konfigurasi Non-Kode
│   ├── app.conf
│   └── logging.conf
├── docs/                      # Panduan Markdown (Zero to Hero)
│   ├── README.md
│   ├── Prasyarat.md
│   ├── Direktori.md
│   ├── Implementasi.md
│   ├── Workflow.md
│   ├── Portabilitas.md
│   └── Troubleshooting.md
├── deploy/
│   └── k8s/
│       ├── base/              # YAML Dasar (hasil podman generate kube)
│       │   └── kustomization.yaml
│       │   # deployment.yaml / docs-deployment.yaml di-generate (make gen-k8s / gen-k8s-docs)
│       └── overlays/          # Opsional: Kustomize per environment
│           └── dev/
│               └── kustomization.yaml
├── Containerfile              # Build aplikasi (Best Practice Rootless)
├── Containerfile.docs         # Contoh praktek: serve docs di container (rootless)
├── Makefile                   # build, run, stop, gen-k8s + build-docs, run-docs, gen-k8s-docs
├── configs.sh                # Opsional: konfigurasi engine host (containers.conf, registries.conf)
├── index-docs.html            # Indeks untuk server docs (Containerfile.docs)
├── .gitignore
└── README.md
```

## Penjelasan Komponen Kunci

### 1. Containerfile (Bukan Dockerfile)

Meskipun sama isinya, menggunakan nama Containerfile adalah standar native Podman. Ini menegaskan komitmen kita pada toolchain yang lebih aman.

Best Practice isi Containerfile:

- Gunakan specific user ID (UID) agar permission host dan container sinkron.
- Copy config dari folder config/.
- Set WORKDIR ke direktori yang aman.

### 2. deploy/k8s/base/ (Sumber Kebenaran YAML)

Di sinilah kita menyimpan manifest dasar.

- Workflow: Jalankan aplikasi lokal dengan `make run` (atau `make run-docs` untuk contoh docs). Setelah sukses, jalankan `make gen-k8s` atau `make gen-k8s-docs` untuk menulis deployment.yaml / docs-deployment.yaml ke folder ini.
- File deployment hasil generate di-gitignore; yang di-commit adalah kustomization.yaml. Agar perubahan struktur K8s tetap bisa di-version control, edit YAML hasil generate lalu commit jika perlu.

### 3. deploy/k8s/overlays/ (Opsional — Penskalaan Lingkungan)

Jika ada overlay (misalnya `overlays/dev/`), Kustomize dipakai untuk perbedaan environment tanpa mengubah base.

- Dev: Misalnya pakai image localhost/my-app:dev dan replica 1.
- Staging/Prod: Pakai image dari registry (GHCR/DockerHub) dan replica lebih.

### 4. Makefile (The Glue)

Ini adalah "Hero Tool" untuk developer. Dengan Makefile, kita menyembunyikan kompleksitas perintah Podman panjang menjadi perintah pendek.

- **Aplikasi:** `make build`, `make run`, `make stop`, `make gen-k8s`
- **Docs (contoh praktek):** `make build-docs`, `make run-docs`, `make stop-docs`, `make gen-k8s-docs` — menjalankan panduan Markdown di container rootless, lalu generate manifest K8s dari pod docs.

### 5. Containerfile.docs (Contoh Praktek)

Containerfile kedua ini mengemas folder `docs/` plus `README.md` dan `ToDo.md` ke dalam image yang dijalankan dengan user non-root (UID 1001) dan port 8080. Berguna untuk memvalidasi alur Podman → Kubernetes tanpa perlu aplikasi custom: build → run → generate kube → refine YAML → deploy ke cluster.

## Pohon Direktori Proyek

```
podman-insider/
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # Pipeline GitHub Actions / GitLab CI
├── app/                       # Source Code Aplikasi
│   ├── main.py
│   ├── requirements.txt
│   └── ...
├── config/                    # Konfigurasi Non-Kode
│   ├── app.conf
│   └── logging.conf
├── deploy/                    # ARTIFAK DEPLOYMENT (Penting untuk K8s)
│   ├── k8s/
│   │   ├── base/              # YAML Dasar (Hasil generate Podman / Template)
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   └── kustomization.yaml
│   │   └── overlays/          # Konfigurasi per Environment (Kustomize)
│   │       ├── dev/
│   │       │   └── kustomization.yaml
│   │       └── staging/
│   │           └── kustomization.yaml
│   └── scripts/               # Script Otomasi Lokal (Podman Helper)
│       ├── build.sh
│       ├── local-run.sh       # Script untuk simulasi Pod & Container
│       └── gen-manifest.sh    # Script wrapper untuk 'podman generate kube'
├── Containerfile              # EKUIVALEN DOCKERFILE (Best Practice Rootless)
├── Makefile                   # Jembatan Perintah (Shortcut)
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

- Workflow: Anda menjalankan aplikasi secara lokal menggunakan deploy/scripts/local-run.sh. Jika sudah sukses, jalankan make gen-k8s untuk memperbarui file di folder ini secara otomatis.
- Kenapa dikeluarkan? Agar Anda bisa melakukan version control (Git) terhadap perubahan struktur K8s.

### 3. deploy/k8s/overlays/ (Penskalaan Lingkungan)

Kita menggunakan Kustomize (bawaan kubectl) untuk menangani perbedaan environment tanpa mengubah file dasar.

- Dev: Mungkin pakai image localhost/my-app:dev dan replica 1.
- Staging/Prod: Pakai image dari Registry (GHCR/DockerHub) dan replica 3.

### 4. Makefile (The Glue)

Ini adalah "Hero Tool" untuk developer. Dengan Makefile, kita menyembunyikan kompleksitas perintah Podman panjang menjadi perintah pendek.

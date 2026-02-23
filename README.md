# podman-insider

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

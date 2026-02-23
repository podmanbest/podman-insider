# Checklist / Todo List praktis untuk menerapkan strategi "Podman Rootless to Kubernetes" secara terstruktur

Panduan lengkap dan urutan baca: [README](README.md). Untuk alur workflow (Setup → Build → Pod → Generate → Deploy), lihat [Workflow](docs/Workflow.md).

---

## 🚀 Phase 1: Inisiasi & Struktur Proyek

```
podman-rootless-k8s/
├── app/                       # Source Code Aplikasi
│   ├── main.py
│   ├── requirements.txt
│   └── ...
├── config/                    # Konfigurasi Non-Kode (app.conf, logging.conf)
├── docs/                      # Panduan Markdown (serve via make run-docs)
├── deploy/k8s/
│   ├── base/                  # YAML dasar (kustomization.yaml; deployment di-generate)
│   └── overlays/dev/          # Opsional: overlay Kustomize untuk env dev
├── Containerfile
├── Containerfile.docs
├── Makefile
├── .gitignore
└── README.md
```

Fokus: Menyiapkan pondasi yang bersih.

- Pastikan Lingkungan Rootless Siap
  - Jalankan podman ps untuk memastikan tidak butuh sudo.
  - Cek /etc/subuid dan /etc/subgid (mapping user sudah ada).
- Buat Struktur Folder
  - Buat folder root proyek (misal: my-app).
  - Buat subfolder: app/, config/, deploy/k8s/base/. Overlay (deploy/k8s/overlays/dev/) bisa ditambah nanti jika perlu.
- Inisialisasi Git
  - Jalankan git init.
  - Buat .gitignore (abaikan **pycache**, .env, folder build lokal).

## 🐳 Phase 2: Containerization (Rootless Friendly)

Fokus: Membuat Containerfile yang aman dan portabel.

- Tulis Containerfile (Dockerfile)
  - Gunakan Multi-stage build (Builder & Runtime).
  - Di tahap Runtime: Buat user non-root (contoh: appuser UID 1000).
  - Set USER appuser.
  - Gunakan port > 1024 (misal: 8080 atau 3000) di EXPOSE.
  - Copy file aplikasi dengan permission yang benar (COPY --chown=appuser:appuser ...).

## ⚙️ Phase 3: Otomasi Lokal (Makefile)

Fokus: Memudahkan hidup developer dengan perintah pendek.

- Buat Makefile
  - Tambah target build: podman build -t localhost/app:dev .
  - Tambah target run:
    - Buat Pod (podman pod create -p 8080:8080).
    - Jalankan Container di dalam Pod (--pod my-pod).
  - Tambah target stop: Untuk membersihkan pod dan container.
  - Tambah target logs: Untuk melihat stdout.
- Uji Coba Build Lokal
  - Jalankan make build.
  - Pastikan tidak ada error permission.

## 🧪 Phase 4: Validasi Lokal (Simulation)

Fokus: Memastikan aplikasi berjalan persis seperti di K8s.

- Jalankan Aplikasi
  1. Jalankan make run.
  2. Cek status: podman pod ps dan podman ps.

- Test Fungsionalitas
  1. Lakukan curl http://localhost:8080 (sesuai port).
  2. Pastikan aplikasi bisa menulis ke filesystem jika perlu (test permission volume).

- Cek Keamanan
  1. Verifikasi container berjalan sebagai user non-root: podman exec -it <container_id> id.
  2. Output harus menampilkan UID bukan 0 (root).

## 🧩 Phase 5: Generate & Prepare K8s Manifests

Fokus: Mengubah state lokal menjadi kode K8s (YAML).

- Generate YAML
  1. Jalankan target make gen-k8s (perintah: podman generate kube my-pod > deploy/k8s/base/deployment.yaml).
- Refine YAML
  1. Buka file deployment.yaml hasil generate.
  2. Pisahkan Resource: Pisahkan kind: Service dan kind: Deployment ke file terpisah jika perlu (opsional, tapi disarankan untuk clean code).
  3. Hapus metadata spesifik lokal yang tidak perlu di K8s.
- Setup Kustomize
  1. Buat deploy/k8s/base/kustomization.yaml.
  2. List resource yang ada di folder tersebut.
- Buat Environment Overlay (opsional)
  1. Jika ada overlay dev: buat deploy/k8s/overlays/dev/kustomization.yaml yang mereferensi base.
  2. Tambah patch untuk image tag (mis. localhost/app:dev) jika perlu.

## 🚢 Phase 6: Deployment & CI/CD Integration

Fokus: Mendaratkan kode ke Kluster.

- Registry Setup
  1. (Opsional untuk local cluster) Jika pakai cluster nyata, push image ke registry.
  2. Jika ada overlay staging/prod, update agar menunjuk ke image registry.
- Deploy ke Kubernetes
  1. Jalankan: kubectl apply -k deploy/k8s/base (atau kubectl apply -k deploy/k8s/overlays/dev jika overlay dev sudah ada).
  2. Cek Pod: kubectl get pods.
  3. Cek Logs: kubectl logs -f <pod_name>.
- Final Verification
  1. Port-forward: kubectl port-forward svc/app 8080:8080.
  2. Akses via browser/curl lagi.
  3. Konfirmasi aplikasi berjalan dengan user non-root di K8s (cek via kubectl exec).

## ✅ Phase 7: Maintenance

Fokus: Siklus hidup berkelanjutan.

- Dokumentasikan perintah make di README.md.
- Update script CI/CD (GitHub Actions/GitLab CI) untuk menjalankan podman build dalam pipeline.
- Tambahkan Liveness/Readiness probe ke YAML manual (karena generate kube tidak bisa menebak logika app).

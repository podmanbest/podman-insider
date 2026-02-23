## Alur Kerja (Workflow) DevOps dengan Struktur Ini

### Level 1: The Setup (Nol Root)

Pastikan Podman terinstal dan dikonfigurasi untuk rootless. Ini dasar utamanya.

1. Cek Konfigurasi User Namespace:

   Pastikan file /etc/subuid dan /etc/subgid sudah dikonfigurasi agar user Anda bisa memetakan ID user container ke ID user host.

   ```bash
    # Biasanya otomatis saat instalasi, cek saja:
    cat /etc/subuid
    # Output contoh: devuser:100000:65536
   ```

2. Verifikasi Rootless:
   Jalankan perintah ini. Jika tidak butuh sudo, Anda siap.
   ```bash
   podman ps
   ```

### Level 2: The "K8s-Ready" Build (Membangun Image)

Di sinilah kebanyakan orang salah. Mereka membuat image yang butuh root di lokal, lalu bingung saat masuk K8s karena Security Context menolaknya.

#### Best Practice Containerfile untuk K8s & Rootless:

- Gunakan Multi-stage build.
- Tentukan user non-root eksplisit.
- Jangan gunakan port < 1024 (karena butuh root). Gunakan port > 1024 (misal 8080, 3000).

  ```Containerfile
  # Stage 1: Build

  FROM golang:1.21-alpine AS builder
  WORKDIR /app
  COPY . .
  RUN go build -o myapp

  # Stage 2: Run (Rootless ready)

  FROM alpine:latest

  # 1. Buat user non-root

  RUN addgroup -S appgroup && adduser -S appuser -G appgroup

  # 2. Install dependensi jika perlu (contoh: ca-certificates)

  RUN apk --no-cache add ca-certificates

  # 3. Copy binary dari builder

  COPY --from=builder /app/myapp /app/myapp

  # 4. PENTING: Ganti ke user non-root

  USER appuser
  WORKDIR /app

  # 5. Expose port > 1024 agar bisa binding di rootless mode

  EXPOSE 8080

  CMD ["./myapp"]
  ```

  #### Build dengan Podman:

  ```bash
  podman build -t localhost/my-k8s-app:v1 .
  ```

  Catatan: Tag localhost/ memastikan image tidak terpush ke registry publik tidak sengaja.

### Level 3: The "Pod" Concept (Simulasi K8s di Lokal)

Kubernetes tidak menjalankan container langsung, ia menjalankan Pods. Podman juga mendukung konsep Pod. Ini adalah kunci agar migration-nya 99% tanpa ubah kode.

Jangan jalankan container terpisah. Kelompokkan mereka dalam satu Pod.

1. Buat Pod Kosong:
   Ini analog dengan membuat definisi Pod di K8s.
   ```bash
    podman pod create --name my-hero-pod -p 8080:8080
   ```
   Jalankan Container di dalam Pod:
   ```bash
    podman run -d --pod my-hero-pod --name myapp-container localhost/my-k8s-app:v1
   ```
   Testing:
   ```bash
    curl http://localhost:8080
   ```

### Level 4: The Magic (Generate K8s YAML)

Ini adalah fitur "Hero" dari Podman. Alih-alih menulis YAML manual dari nol, kita generate dari status runtime Podman lokal yang sudah kita pastikan berjalan sukses.

```bash
podman generate kube my-hero-pod > my-k8s-deployment.yaml
```

Apa yang dihasilkan?

File YAML tersebut berisi:

- Service: Mengatur load balancing dan port (mengambil dari pod create -p).
- Deployment: Mengatur replika dan container spec.
- Containers: Menyertakan semua volume mapping, environment variables, dan flags yang Anda gunakan saat menjalankan podman run.

### Level 5: Refinement (Opsional tapi Disarankan)

Buka file my-k8s-deployment.yaml yang baru dibuat. Anda akan melihat Podman sudah mengerjakan 80% pekerjaan.

Sesuaikan sedikit untuk Best Practice K8s:

    1.  Security Context: Pastikan runAsUser dan fsGroup sesuai dengan appuser (UID 1000 atau sesuai Containerfile) yang Anda buat di Level 2. Jika Podman rootless Anda sudah benar, generated YAML ini akan aman.
    2.  Liveness/Readiness Probes: Tambahkan ini manual karena Podman tidak tahu logika kesehatan aplikasi internal Anda.

    Contoh bagian spec yang mungkin perlu Anda cek:

      ```yaml
      spec:
      containers:
        - name: myapp-container
          image: localhost/my-k8s-app:v1
          securityContext:
          runAsNonRoot: true
          runAsUser: 1000 # Pastikan ini selaras dengan Containerfile
      ```

### Level 6: Deployment (Daur Ulang ke K8s)

Sekarang file YAML Anda siap digunakan di kluster Kubernetes (Minikube, Kind, atau prod cluster).

```bash
# Jika image di push ke registry (Internal/External), update dulu image tag di YAML
kubectl apply -f my-k8s-deployment.yaml
```

### Ringkasan DevOps Workflow yang "Reusable"

- Develop: Tulis kode dan Dockerfile (dengan user non-root).
- Test Local: podman pod create & podman run (Rootless).
- Verify: Pastikan aplikasi berjalan di port > 1024 tanpa error permission.
- Generate: podman generate kube -> Hasilkan YAML.
- Commit: Masukkan YAML ke Git Repo.
- Deploy: Pipeline CI/CD Anda tinggal menerapkan YAML tersebut ke K8s.

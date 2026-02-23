# Portabilitas: Podman (lokal) vs Kubernetes (cluster)

Dokumen ini merangkum apa yang **langsung terbawa** dari Podman rootless ke Kubernetes dan apa yang **biasanya perlu disesuaikan**, agar manifest hasil `podman generate kube` siap dipakai di cluster.

---

## Yang langsung terbawa oleh `podman generate kube`

Dengan konfigurasi rootless yang benar (user non-root di image, port > 1024), perintah `podman generate kube <pod>` menghasilkan YAML yang sudah selaras dengan praktik aman K8s:

| Aspek | Keterangan |
|-------|------------|
| **Pod / container spec** | Definisi container (image, command, args) dari pod Anda. |
| **Environment variables** | Semua `-e` / `--env` dari `podman run` masuk ke manifest. |
| **Volume mounts** | Volume yang Anda mount ke pod/container tercermin di YAML. |
| **Port** | Port yang di-expose lewat `pod create -p` atau `run -p` menjadi Service port dan container port. |
| **Security context** | Jika container berjalan sebagai user non-root di Podman, output generate kube akan memuat `runAsUser` / `runAsNonRoot` yang selaras. |

Prinsip: **apa yang jalan di Podman rootless, strukturnya bisa langsung dipakai di K8s** — yang perlu disesuaikan terutama metadata dan konvensi (resource name, namespace, image registry, probes).

---

## Yang biasanya perlu ditambah atau disesuaikan

| Aspek | Tindakan |
|-------|----------|
| **Pisah resource** | `podman generate kube` bisa menghasilkan Service dan Pod/Deployment dalam satu file. Untuk kebersihan dan Kustomize, pisahkan ke `service.yaml` dan `deployment.yaml` (atau `statefulset.yaml` jika relevan). |
| **Image** | Tag `localhost/...` hanya untuk lokal. Untuk cluster: push image ke registry (GHCR, Docker Hub, Quay, dll.) dan ganti image di manifest atau lewat overlay Kustomize per environment. |
| **Liveness / Readiness probes** | Podman tidak mengetahui logika kesehatan aplikasi. Tambahkan `livenessProbe` dan `readinessProbe` secara manual di spec container. |
| **runAsUser / fsGroup** | Pastikan UID/GID sama dengan user di Containerfile (mis. 1001). Jika belum ada di generated YAML, tambahkan di `securityContext` container atau pod. |
| **Resource requests/limits** | Generate kube tidak mengisi `resources`. Tambah `requests` dan `limits` sesuai kebutuhan. |
| **Namespace / labels** | Sesuaikan namespace dan label (mis. `env: dev/staging/prod`) lewat Kustomize overlay atau edit manual. |

---

## Ringkasan: Podman (lokal) vs Kubernetes (cluster)

| Aspek | Podman (lokal rootless) | Kubernetes (cluster) |
|-------|-------------------------|------------------------|
| **Network** | Port mapping host:container (`-p 8080:8080`) | Service + Pod port; akses via ClusterIP/NodePort/LoadBalancer |
| **Volume** | Bind mount atau named volume | PersistentVolumeClaim / ConfigMap / emptyDir, dll. |
| **Env** | `-e` / `--env` / `--env-file` | `env` / `envFrom` di spec container |
| **User** | User non-root di Containerfile; Podman memetakan UID | `securityContext.runAsUser` / `runAsNonRoot`; selaras jika sama dengan image |
| **Port** | Port > 1024 agar binding tanpa root | Sama; hindari port < 1024 untuk konsistensi |
| **Orchestration** | Pod = grup container; `pod create` + `run --pod` | Pod = unit deploy; Deployment/StatefulSet mengelola replika |

Dengan memastikan image rootless (USER non-root, port > 1024) dan menjalankan workload dalam **pod** di Podman, hasil `podman generate kube` bisa didaur ulang ke Kubernetes dengan sedikit refinement (image registry, probes, resources, pemisahan file). Lihat [Workflow](Workflow.md) Level 4–6 dan [Troubleshooting](Troubleshooting.md) untuk detail penerapan.

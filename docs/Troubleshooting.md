# Troubleshooting

Masalah umum saat menjalankan Podman rootless, mengenerate manifest K8s, dan mendeploy ke Kubernetes.

---

## Rootless

### Port &lt; 1024: gagal bind / permission denied

**Gejala:** Container atau pod gagal start dengan error terkait binding port (mis. 80, 443).

**Penyebab:** Di mode rootless, user biasa tidak bisa bind ke port privileged (&lt; 1024).

**Solusi:**

- Gunakan port &gt; 1024 di aplikasi dan Containerfile (mis. 8080, 8443). **Ini juga yang disarankan untuk K8s.**
- Jika memang harus pakai 80/443 di host, gunakan reverse proxy (Caddy, Nginx) yang listen di 8080/8443 dan di-forward dari 80/443 (konfigurasi di host, bisa butuh root/capabilities).

### Permission denied pada volume / bind mount

**Gejala:** Aplikasi di container tidak bisa menulis ke direktori yang di-mount dari host.

**Penyebab:** Ownership di host tidak cocok dengan UID/GID user di container (rootless memetakan UID).

**Solusi:**

- Pastikan `/etc/subuid` dan `/etc/subgid` terkonfigurasi untuk user Anda. Lihat [Prasyarat](Prasyarat.md).
- Atur ownership direktori host agar sesuai dengan UID yang dipakai di container (mis. `chown 1001:1001 /path/to/data` jika container pakai UID 1001).
- Di Containerfile, gunakan `COPY --chown=appuser:appuser` dan pastikan `USER appuser` dengan UID yang konsisten.

---

## Generate kube

### Output satu file gabung (Service + Pod/Deployment)

**Gejala:** Satu file YAML berisi banyak resource; ingin dipisah untuk Kustomize atau readability.

**Solusi:**

- Buka file hasil `podman generate kube`. Copy blok `kind: Service` ke `deployment.yaml` (atau `service.yaml` terpisah) dan blok Deployment/Pod ke file lain. Sesuaikan `deploy/k8s/base/kustomization.yaml` agar merujuk ke kedua file.
- Atau gunakan tool seperti `yq` / script untuk memecah multi-document YAML ke file per resource.

### Manifest tidak apply: nama resource / namespace

**Gejala:** `kubectl apply -f ...` gagal (nama sudah dipakai, namespace tidak ada, dll.).

**Solusi:**

- Pastikan nama resource dan namespace konsisten. Generated YAML mungkin memakai nama pod lokal; bisa diganti ke nama yang lebih generik (mis. `my-app`).
- Buat namespace dulu jika perlu: `kubectl create namespace <nama>`.
- Untuk Kustomize, set `namespace` di `kustomization.yaml` atau overlay.

---

## Kubernetes

### Pod SecurityStandards (restricted): runAsNonRoot / runAsUser

**Gejala:** Pod tidak bisa start; policy melarang root atau UID tidak sesuai.

**Penyebab:** Cluster memakai Pod Security Standards (restricted/baseline) yang mengharuskan `runAsNonRoot: true` dan kadang `runAsUser` tertentu.

**Solusi:**

- Pastikan image Anda memang berjalan sebagai user non-root (lihat [Implementasi](Implementasi.md) dan [Workflow](Workflow.md) Level 2). Setelah itu, hasil `podman generate kube` dari pod rootless biasanya sudah berisi `runAsNonRoot` / `runAsUser`.
- Jika belum, tambahkan di manifest:

  ```yaml
  securityContext:
    runAsNonRoot: true
    runAsUser: 1001   # sesuaikan dengan UID di Containerfile
  ```

- Pastikan UID di Containerfile sama dengan `runAsUser` di K8s agar perilaku konsisten dengan lokal.

### Image pull error: localhost/... tidak bisa di-pull di cluster

**Gejala:** Pod status `ImagePullBackOff`; image `localhost/my-app:dev` tidak ditemukan.

**Penyebab:** Image `localhost/...` hanya ada di mesin Anda, tidak di registry yang bisa diakses cluster.

**Solusi:**

- Push image ke registry yang dipakai cluster: `podman push localhost/my-app:dev registry.example.com/my-app:dev`.
- Update manifest (atau overlay Kustomize) agar memakai image dari registry, bukan `localhost/...`.

---

Untuk prasyarat dan alur lengkap, lihat [Prasyarat](Prasyarat.md) dan [Workflow](Workflow.md). Untuk pemetaan konsep Podman–K8s, lihat [Portabilitas](Portabilitas.md).

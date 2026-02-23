# Prasyarat & Instalasi Podman Rootless

Agar alur **Zero to Hero** (lokal rootless → generate kube → deploy K8s) berjalan lancar, pastikan Podman terpasang dan berjalan **rootless**. Konfigurasi ini membuat image dan pod lokal Anda selaras dengan praktik aman di Kubernetes (non-root, port > 1024).

---

## 1. Instalasi Podman

### Windows (WSL2 atau Native)

```powershell
# Pakai winget (Windows)
winget install RedHat.Podman

# Atau unduh installer dari: https://podman-desktop.io/ atau https://podman.io/
```

Setelah instalasi, pastikan `podman` ada di PATH:

```powershell
podman --version
```

Di Windows/macOS, Podman berjalan di VM (rootless by design untuk user space).

### Linux

```bash
# Fedora
sudo dnf install podman

# Ubuntu/Debian
sudo apt update && sudo apt install podman

# Arch
sudo pacman -S podman
```

Podman di Linux secara default berjalan rootless (tanpa daemon root).

### macOS

```bash
brew install podman
podman machine init
podman machine start
```

---

## 2. Verifikasi mode rootless

Jalankan tanpa `sudo`. Jika perintah berikut berhasil, Anda siap.

```bash
podman ps
```

Cek flag rootless:

```bash
podman info | grep -i rootless
# rootless: true
```

---

## 3. Konfigurasi user namespace (Linux)

Untuk volume mount dan UID di container, pastikan user Anda punya subuid/subgid. Biasanya sudah terisi saat instalasi.

```bash
cat /etc/subuid
# Contoh: devuser:100000:65536

cat /etc/subgid
# Contoh: devuser:100000:65536
```

Jika kosong, tambahkan mapping untuk user Anda (perlu root sekali saja):

```bash
# Ganti USERNAME dengan nama user Anda
echo "USERNAME:100000:65536" | sudo tee -a /etc/subuid
echo "USERNAME:100000:65536" | sudo tee -a /etc/subgid
```

---

## 4. Persyaratan untuk "K8s-ready"

Agar hasil `podman generate kube` langsung berguna di Kubernetes:

| Persyaratan | Alasan |
|-------------|--------|
| **Port > 1024** | Binding port < 1024 butuh root; di rootless dan K8s aman pakai port tinggi (8080, 3000). |
| **User non-root di image** | Containerfile harus punya `USER` bukan root; agar `runAsNonRoot` dan security context K8s selaras. |
| **Pod, bukan hanya container** | Jalankan workload dalam **pod** (`podman pod create` + `podman run --pod ...`) agar generate kube menghasilkan struktur mirip K8s. |

Setelah langkah di atas, lanjut ke [Struktur direktori proyek](Direktori.md) dan [Workflow](Workflow.md) Level 2 (build) dan Level 3 (pod + run).

---

## 5. Opsional: Konfigurasi engine di host (configs.sh)

Di root proyek ada file **configs.sh** yang menulis konfigurasi ke `/etc/containers/` (containers.conf dan registries.conf), misalnya `pids_limit=0` dan registry `localhost` sebagai insecure. Berguna untuk setup host sekali jalan. **Jalankan dengan akses root** (mis. `sudo bash configs.sh`). Bukan bagian dari alur build/run; bisa diabaikan jika engine sudah sesuai.

## Alur Kerja (Workflow) DevOps dengan Struktur Ini

1. Developer Mula-mula:

   ```bash

   git clone repo
   make build
   make run
   ```

   Aplikasi berjalan di port 8080 sebagai user biasa (Rootless).

2. Developer Puas dengan Hasil Lokal:

   ```bash
   make gen-k8s
   ```

   File deploy/k8s/base/deployment.yaml terupdate otomatis sesuai konfigurasi run tadi.

3. Developer/DevOps Edit untuk Production:
   Developer mungkin memisahkan Service dan Deployment dari file YAML yang tadi digenerate, lalu membuat patch di overlays/production.

4. Deploy ke Kubernetes:

   ```bash
   kubectl apply -k deploy/k8s/overlays/production
   ```

## Keuntungan Struktur Ini:

1. Reusability: Apa yang dijalankan make run lokal 99% sama dengan YAML K8s-nya.
2. Maintainability: Perintah rumit disembunyikan di Makefile.
3. Scalability: Menggunakan overlays Kustomize memudahkan scaling ke banyak environment tanpa duplikasi kode.
4. Security: Containerfile dan struktur folder memaksa pola pikir non-root.

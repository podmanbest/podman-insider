# Panduan Podman Rootless: Zero to Hero dengan fokus pada portabilitas ke Kubernetes.

## Filosofi Utama: "What happens locally, happens in cluster"

Jangan root di lokal, jangan root di K8s. Jika aplikasi berjalan sebagai user biasa (non-root) di laptop Podman Anda, maka manifest YAML yang di-generate akan langsung cocok dengan kluster Kubernetes yang aman.

- [Prasyarat & instalasi Podman rootless](./Prasyarat.md)
- [Struktur Direktori Proyek](./Direktori.md)
- [Implementasi Praktis (Isi File)](./Implementasi.md)
- [Alur Kerja (Workflow) DevOps dengan Struktur Ini](./Workflow.md)
- [Portabilitas: Podman vs Kubernetes](./Portabilitas.md)
- [Troubleshooting](./Troubleshooting.md)

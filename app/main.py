#!/usr/bin/env python3
"""Contoh minimal aplikasi untuk Containerfile (rootless, port 8080)."""
from http.server import HTTPServer, BaseHTTPRequestHandler

PORT = 8080

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(b"Podman Rootless K8s - app example\nOK\n")

if __name__ == "__main__":
    with HTTPServer(("", PORT), Handler) as httpd:
        print(f"Serving at http://0.0.0.0:{PORT}")
        httpd.serve_forever()

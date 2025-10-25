#!/usr/bin/env python3
"""
hello.py
Petit serveur HTTP qui répond "Hello, DevOps!" sur / pour être utilisable
comme service long-running (Nomad, Docker, etc.).
"""
from http.server import BaseHTTPRequestHandler, HTTPServer
import os


class HelloHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/' or self.path == '/index.html':
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self.end_headers()
            self.wfile.write(b'Hello, DevOps!')
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        # keep logs concise
        print("[http] %s - - %s" % (self.client_address[0], format % args))


def run(server_class=HTTPServer, handler_class=HelloHandler):
    # Prefer Nomad-injected dynamic port environment variables when present.
    # Nomad commonly sets NOMAD_PORT_<label>, NOMAD_ALLOC_PORT_<label> or PORT_<label>.
    port_env_candidates = (
        'NOMAD_PORT_http',
        'NOMAD_ALLOC_PORT_http',
        'NOMAD_HOST_PORT_http',
        'PORT_http',
        'PORT',
    )
    port = None
    for name in port_env_candidates:
        val = os.environ.get(name)
        if val:
            try:
                port = int(val)
                used = name
                break
            except Exception:
                # ignore parse errors and continue
                pass

    if port is None:
        port = 8080
        used = 'default PORT (8080)'

    # Bind to all interfaces explicitly so host port mappings can reach the server.
    server_address = ('0.0.0.0', port)
    httpd = server_class(server_address, handler_class)
    print(f"Starting HTTP server on port {port} (from {used})... (Ctrl-C to stop)")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('\nShutting down HTTP server')
        httpd.server_close()


if __name__ == '__main__':
    run()

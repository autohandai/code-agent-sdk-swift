#!/usr/bin/env python3
"""Local-only auth/model fixture for the Swift SDK actual-CLI test."""
import json
import sys
from pathlib import Path
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

root = Path(sys.argv[1])
calls = []
failures = []
auth_calls = []

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def do_GET(self):
        token = self.headers.get('Authorization')
        if self.path == '/auth/me':
            auth_calls.append(token)
            if token not in ('Bearer session-token', 'Bearer inference-key'):
                failures.append('unexpected auth credential')
            result = {'authenticated': True, 'user': {'id': 'swift-sdk', 'email': 'sdk@example.test'}}
        else:
            result = {'data': [{'id': 'fantail'}]}
        self.respond(result)

    def do_POST(self):
        request = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
        if self.path != '/v1/chat/completions' or self.headers.get('Authorization') != 'Bearer inference-key':
            failures.append('unexpected inference destination or credential')
        if request.get('model') != 'fantail':
            failures.append('incorrect inference model')
        calls.append(request)
        (root / 'calls.json').write_text(json.dumps(calls))
        message = {'role': 'assistant', 'content': 'continued from persisted evidence'}
        if len(calls) == 1:
            message = {'role': 'assistant', 'content': '', 'tool_calls': [{'id': 'read-evidence', 'type': 'function', 'function': {'name': 'read_file', 'arguments': '{"path":"evidence.txt"}'}}]}
        self.respond({'id': 'swift-completion', 'choices': [{'message': message, 'finish_reason': 'tool_calls' if len(calls) == 1 else 'stop'}], 'usage': {'prompt_tokens': 10, 'completion_tokens': 5, 'total_tokens': 15}})

    def respond(self, result):
        (root / 'fixture-status.json').write_text(json.dumps({'auth': auth_calls, 'failures': failures}))
        body = json.dumps(result).encode()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

with ThreadingHTTPServer(('127.0.0.1', 0), Handler) as server:
    print(json.dumps({'baseUrl': f'http://127.0.0.1:{server.server_port}'}), flush=True)
    server.serve_forever()

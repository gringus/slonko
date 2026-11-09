# Mock ollama API server for the llama-index-llms-ollama test suite.
# Implements the endpoints the wrapper uses (list/show/chat) with canned
# responses so the tests run offline against the wrapper's hardcoded
# default host, localhost:11434.
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MODELS = ["llama3.1:latest", "qwen3:0.6b", "gpt-oss:20b"]
NOW = "2026-01-01T00:00:00Z"

# The thinking-level test compares block lengths between think levels.
THINKING = {
    "low": "brief reasoning.",
    "medium": "moderately long reasoning. " * 3,
    "high": "extremely long and detailed reasoning. " * 10,
}


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *args):
        pass

    def _send(self, obj, status=200):
        body = json.dumps(obj).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/api/tags":
            self._send({
                "models": [
                    {
                        "name": m,
                        "model": m,
                        "size": 1,
                        "digest": "mock",
                        "modified_at": NOW,
                        "details": {"format": "gguf", "family": "qwen3"},
                    }
                    for m in MODELS
                ]
            })
        else:
            self._send({"error": "not found"}, status=404)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        req = json.loads(self.rfile.read(length) or b"{}")
        if self.path == "/api/show":
            self._send({
                "license": "MIT",
                "modelfile": "",
                "parameters": "",
                "template": "",
                "model_info": {"qwen3.context_length": 40960},
            })
            return
        if self.path != "/api/chat":
            self._send({"error": "not found"}, status=404)
            return

        message = {"role": "assistant", "content": "Hello!"}
        think = req.get("think")
        if think in THINKING:
            message["thinking"] = THINKING[think]
        elif think is True:
            message["thinking"] = "thinking."
        tools = req.get("tools")
        if tools:
            # Echo the first requested tool with dummy arguments matching
            # its schema properties.
            props = tools[0].get("function", {}).get("parameters", {}).get(
                "properties", {}
            )
            message["content"] = ""
            message["tool_calls"] = [{
                "function": {
                    "name": tools[0]["function"]["name"],
                    "arguments": {p: "mock" for p in props},
                }
            }]
        chunk = {
            "model": req.get("model", ""),
            "created_at": NOW,
            "done": True,
            "done_reason": "stop",
            "message": message,
        }
        if req.get("stream"):
            # A single chunk carries the whole message: the tests assert on
            # every yielded chunk, so empty filler chunks would fail them.
            body = json.dumps(chunk).encode() + b"\n"
            self.send_response(200)
            self.send_header("Content-Type", "application/x-ndjson")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        else:
            self._send(chunk)


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", 11434), Handler).serve_forever()

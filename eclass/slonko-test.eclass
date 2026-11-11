# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: slonko-test.eclass
# @MAINTAINER:
# Marcin Deranek <marcin.deranek@slonko.net>
# @SUPPORTED_EAPIS: 8
# @BLURB: Shared test-phase helpers for slonko overlay ebuilds.
# @DESCRIPTION:
# Helpers for ebuilds whose test phases need offline cache seeding
# (tiktoken encodings, HF hub models) or a local background server
# (mock ollama API, static resource host). All helpers die on failure.

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ ! ${_SLONKO_TEST_ECLASS} ]]; then
_SLONKO_TEST_ECLASS=1

# @VARIABLE: EBUILD_DEATH_HOOKS
# @DEFAULT_UNSET
# @DESCRIPTION:
# Extended by this eclass: _SlonkoTest_kill_server is registered at inherit
# time so a server spawned by slonko_test_spawn_server is stopped even if
# the phase dies.

# @FUNCTION: slonko_test_seed_tiktoken_cache
# @USAGE: <cache_dir> (stdin: url|distfile pairs)
# @DESCRIPTION:
# Copy each distfile to <cache_dir>/<sha1(url)> — tiktoken's cache-naming
# contract — and export TIKTOKEN_CACHE_DIR. Use for every encoding the
# suite can reach via tiktoken's model registry.
slonko_test_seed_tiktoken_cache() {
	[[ ${#} -eq 1 ]] || die "${FUNCNAME}: expected <cache_dir>"
	local cache_dir=$1
	mkdir -p "${cache_dir}" || die
	local entry url distfile
	while read -r entry; do
		[[ -z ${entry} ]] && continue
		url=${entry%%|*}
		distfile=${entry#*|}
		cp "${DISTDIR}/${distfile}" "${cache_dir}/$(printf '%s' "${url}" | sha1sum | awk '{print $1}')" || die
	done
	export TIKTOKEN_CACHE_DIR="${cache_dir}"
}

# @FUNCTION: slonko_test_seed_hf_repo
# @USAGE: <cache_dir> <repo> <rev> (stdin: distfile|path pairs)
# @DESCRIPTION:
# Lay out an offline HF hub cache for <repo>@<rev> inside <cache_dir>:
# refs/main pointing at the rev, blobs/<distfile>, and
# snapshots/<rev>/<path> symlinks into the blobs. The layout lives
# directly inside <cache_dir> — callers pass the directory the consumer
# uses as the HF cache_dir (e.g. LLAMA_INDEX_CACHE_DIR for llama-index
# wrappers, or <root>/hub for HF_HUB_CACHE).
slonko_test_seed_hf_repo() {
	[[ ${#} -eq 3 ]] || die "${FUNCNAME}: expected <cache_dir> <repo> <rev>"
	local cache_dir=$1 repo=$2 rev=$3
	local repo_dir="${cache_dir}/${repo}"
	mkdir -p "${repo_dir}/refs" "${repo_dir}/blobs" "${repo_dir}/snapshots/${rev}" || die
	printf '%s' "${rev}" > "${repo_dir}/refs/main" || die
	local entry distfile path destdir
	while read -r entry; do
		[[ -z ${entry} ]] && continue
		distfile=${entry%%|*}
		path=${entry#*|}
		cp "${DISTDIR}/${distfile}" "${repo_dir}/blobs/${distfile}" || die
		destdir="${repo_dir}/snapshots/${rev}"/$(dirname "${path}")
		mkdir -p "${destdir}" || die
		# Absolute symlink: the whole cache lives under ${T}, nothing moves.
		ln -sfn "${repo_dir}/blobs/${distfile}" "${repo_dir}/snapshots/${rev}/${path}" || die
	done
}

# @FUNCTION: slonko_test_write_ollama_mock
# @USAGE: <dest>
# @DESCRIPTION:
# Write a mock ollama API server (stdlib-only, python3) serving
# /api/tags, /api/show, /api/chat (incl. streaming NDJSON, tool calls,
# think levels) and /api/embed with canned responses, so the llama-index
# ollama test suites run offline against the wrappers' hardcoded default
# host, localhost:11434.
slonko_test_write_ollama_mock() {
	[[ ${#} -eq 1 ]] || die "${FUNCNAME}: expected <dest>"
	cat > "$1" <<'MOCK_OLLAMA_PY' || die
# Mock ollama API server for the llama-index ollama test suites (llms +
# embeddings): canned responses for /api/tags, /api/show, /api/chat
# (streaming NDJSON, tool calls, think levels) and /api/embed.
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
        if self.path == "/api/embed":
            # Vary the vector with the input so that different texts
            # produce different embeddings of a fixed dimension.
            inputs = req.get("input")
            if isinstance(inputs, str):
                inputs = [inputs]
            seed = sum(json.dumps(inputs).encode()) or 1
            self._send({
                "model": req.get("model", ""),
                "embeddings": [
                    [((seed * (i + 1)) % 97) / 97.0 for i in range(8)]
                    for _ in inputs
                ],
            })
            return
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
MOCK_OLLAMA_PY
}

# @FUNCTION: slonko_test_spawn_server
# @USAGE: <port> <logfile> <cmd> [args...]
# @DESCRIPTION:
# Start a background test server and wait (max ~5s) for <port> to accept
# connections on 127.0.0.1; die with the logfile path if it never does.
# Cleanup on normal return and on death is handled by
# slonko_test_stop_server / the registered death hook.
slonko_test_spawn_server() {
	local port=$1 logfile=$2
	shift 2
	[[ ${port} =~ ^[0-9]+$ && ${#} -ge 1 ]] || die "${FUNCNAME}: expected <port> <logfile> <cmd> [args...]"
	"${@}" &>"${logfile}" &
	_SLONKO_TEST_SERVER_PID=${!}
	local i
	for (( i = 0; i < 50; i++ )); do
		(echo > /dev/tcp/127.0.0.1/${port}) 2>/dev/null && return 0
		sleep 0.1
	done
	_SlonkoTest_kill_server
	die "${FUNCNAME}: server failed to open port ${port} (see ${logfile})"
}

# @FUNCTION: slonko_test_stop_server
# @DESCRIPTION:
# Stop a server started by slonko_test_spawn_server (also registered as a
# death hook at inherit time).
slonko_test_stop_server() {
	_SlonkoTest_kill_server
}

# @FUNCTION: _SlonkoTest_kill_server
# @INTERNAL
# @DESCRIPTION:
# Kill the server started by slonko_test_spawn_server, if any.
_SlonkoTest_kill_server() {
	[[ -n ${_SLONKO_TEST_SERVER_PID} ]] || return 0
	kill "${_SLONKO_TEST_SERVER_PID}" 2>/dev/null
	wait "${_SLONKO_TEST_SERVER_PID}" 2>/dev/null
}

has _SlonkoTest_kill_server "${EBUILD_DEATH_HOOKS}" ||
	EBUILD_DEATH_HOOKS+=" _SlonkoTest_kill_server"

fi

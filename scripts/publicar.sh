#!/bin/sh
set +x
set -eu

# Git reinvoca este archivo como askpass para obtener usuario y contraseña.
if [ "$#" -gt 0 ]; then
  case "$1" in
    *[Uu]sername*)
      printf '%s\n' 'x-access-token'
      ;;
    *[Pp]assword*)
      printf '%s\n' "${GITHUB_TOKEN:?GITHUB_TOKEN no disponible}"
      ;;
    *)
      exit 1
      ;;
  esac
  exit 0
fi

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd "$script_dir/.." && pwd)
env_file=$repo_root/.env

if [ ! -f "$env_file" ]; then
  printf '%s\n' 'Error: no existe el archivo .env.' >&2
  exit 1
fi

token=$(awk '
  /^[[:space:]]*#/ { next }
  /^[[:space:]]*GITHUB_TOKEN[[:space:]]*=/ {
    sub(/^[[:space:]]*GITHUB_TOKEN[[:space:]]*=/, "")
    sub(/\r$/, "")
    print
    exit
  }
' "$env_file")

if [ -z "$token" ] || [ "$token" = 'pega_aqui_el_token' ]; then
  printf '%s\n' 'Error: .env no contiene un GITHUB_TOKEN configurado.' >&2
  exit 1
fi

cd "$repo_root"

# Evita que el modo de diagnóstico de Git pueda mostrar cabeceras de autenticación.
unset GIT_TRACE GIT_TRACE_PACKET GIT_TRACE_PACK_ACCESS GIT_TRACE_CURL \
  GIT_CURL_VERBOSE GIT_TRACE2 GIT_TRACE2_EVENT GIT_TRACE2_PERF 2>/dev/null || true

GITHUB_TOKEN=$token \
GIT_ASKPASS=$script_dir/publicar.sh \
GIT_TERMINAL_PROMPT=0 \
GCM_INTERACTIVE=Never \
git -c credential.helper= -c http.extraheader= push origin main

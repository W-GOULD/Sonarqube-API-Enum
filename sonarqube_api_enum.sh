#!/usr/bin/env bash
# Simple SonarQube API Enumerator
# Classifies endpoints by HTTP status only (OPEN = 200; AUTH = 401/403; else OTHER).

set -u

if [ $# -lt 2 ]; then
  echo "Usage: $0 <base_url> <endpoints_file>"
  exit 1
fi

BASE_URL="$1"
EP_FILE="$2"
OUTDIR="sonarqube_api_enum_results"

if [ ! -f "$EP_FILE" ]; then
  echo "[-] Endpoints file not found: $EP_FILE" >&2
  exit 1
fi

# Normalise base URL (strip trailing slash)
BASE_URL="${BASE_URL%/}"

mkdir -p "$OUTDIR"/{bodies,headers,logs}
SUMMARY="$OUTDIR/summary.csv"
echo "endpoint,status,http_code,bytes" > "$SUMMARY"

open=0; auth=0; other=0

while IFS= read -r raw; do
  # Trim leading/trailing whitespace and CR
  ep="$(printf '%s' "$raw" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]\r]*$//')"
  [ -z "$ep" ] && continue
  # Ensure it starts with a slash
  case "$ep" in
    /*) : ;;
    *) ep="/$ep" ;;
  esac

  safe="$(printf '%s' "$ep" | tr '/' '_' | sed 's/^_//')"
  hdr="$OUTDIR/headers/${safe}.hdr"
  body="$OUTDIR/bodies/${safe}.out"
  err="$OUTDIR/logs/${safe}.err"

  # Core curl (exactly what you asked for)
  code=$(curl -L -sS --insecure --max-time 15 \
              -D "$hdr" -o "$body" -w '%{http_code}' \
              "$BASE_URL$ep" 2>"$err" || echo "000")

  bytes=$(wc -c < "$body" | tr -d ' ')

  case "$code" in
    200) status="OPEN";             open=$((open+1)) ;;
    401|403) status="AUTH_REQUIRED"; auth=$((auth+1)) ;;
    *)   status="OTHER";            other=$((other+1)) ;;
  esac

  printf "[*] %-35s -> %-13s (code=%s, bytes=%s)\n" "$ep" "$status" "$code" "$bytes"
  printf "%s,%s,%s,%s\n" "$ep" "$status" "$code" "$bytes" >> "$SUMMARY"

done < "$EP_FILE"

echo
echo "[*] Summary:"
echo "    OPEN (200):        $open"
echo "    AUTH_REQUIRED:     $auth"
echo "    OTHER:             $other"
echo "[*] CSV: $SUMMARY"

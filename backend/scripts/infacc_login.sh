#!/usr/bin/env bash
# Interactive INFACC login -> refreshes ../../cookies.txt
# Password is read directly from this terminal (never leaves your machine).
set -euo pipefail

BASE="https://app.infacc.org/backend/web"
JAR="$(cd "$(dirname "$0")/../.." && pwd)/cookies.txt"
TMP_HTML="$(mktemp)"

echo "Fetching login page..."
curl -s -c "$JAR" -A "Mozilla/5.0" "$BASE/site/login" -o "$TMP_HTML"

CSRF=$(grep -oE '<input type="hidden" name="_csrf-backend" value="[^"]*"' "$TMP_HTML" | sed -E 's/.*value="([^"]*)".*/\1/')
if [ -z "${CSRF:-}" ]; then echo "Could not read CSRF token. Aborting."; exit 1; fi

printf "INFACC username: "
read -r INFACC_USER
printf "INFACC password (hidden): "
read -r -s INFACC_PASS
echo

echo "Logging in..."
HTTP=$(curl -s -b "$JAR" -c "$JAR" -A "Mozilla/5.0" \
  -o /tmp/infacc_login_resp.html -w "%{http_code}" \
  --data-urlencode "_csrf-backend=$CSRF" \
  --data-urlencode "LoginForm[username]=$INFACC_USER" \
  --data-urlencode "LoginForm[password]=$INFACC_PASS" \
  --data-urlencode "LoginForm[rememberMe]=1" \
  "$BASE/site/login")
unset INFACC_PASS

# Verify by hitting an authenticated page
VERIFY=$(curl -s -b "$JAR" -A "Mozilla/5.0" -o /dev/null -w "%{http_code}" "$BASE/member/index?page=1")
if [ "$VERIFY" = "200" ]; then
  echo "LOGIN OK (cookies saved to cookies.txt)"
else
  echo "LOGIN FAILED (member/index returned $VERIFY). Check credentials."
  exit 1
fi
rm -f "$TMP_HTML"

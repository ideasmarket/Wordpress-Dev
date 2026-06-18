#!/bin/bash
# bootstrap.sh
# Run from the root of a freshly scaffolded Bedrock project:
# curl -fsSL https://raw.githubusercontent.com/ideasmarket/Wordpress-Dev/main/bootstrap.sh | bash
#
# Requires: SCAFFOLD_PAT env var set, or passed inline:
# SCAFFOLD_PAT=ghp_xxx curl -fsSL ... | bash

set -euo pipefail

REPO="ideasmarket/Wordpress-Dev"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
AUTH_HEADER="Authorization: token ${GITHUB_PAT:?GITHUB_PAT env var required}"

fetch() {
  local dest="$1"
  mkdir -p "$(dirname "$dest")"
  curl -fsSL -H "$AUTH_HEADER" "${RAW}/${dest}" -o "${dest}"
  echo "  fetched ${dest}"
}

echo "Scaffolding Docker Files"

fetch "Dockerfile"
fetch "docker-compose.yml"
fetch "docker/nginx.conf"
fetch "docker/entrypoint.sh"
fetch "docker/php-fpm.conf"
fetch ".env"

chmod +x docker/entrypoint.sh

echo "Done. Next steps:"
echo "  1. Edit .env with project credentials"
echo "  2. $ docker compose build"
echo "  3. $ docker compose up"

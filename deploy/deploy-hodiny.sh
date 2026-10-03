#!/usr/bin/env bash
# Forced command of the GitHub Actions deploy key (installed as /usr/local/bin/deploy-hodiny):
# the key can only replace hodiny.html with stdin. The client's "command" is the upload's sha256,
# because a dropped connection ends stdin like a finished upload and would publish a truncated page.
set -euo pipefail

expected_sha256=${SSH_ORIGINAL_COMMAND:-}
if [[ ! $expected_sha256 =~ ^[0-9a-f]{64}$ ]]; then
    echo "Refusing to deploy: pass the upload's sha256 as the SSH command" >&2
    exit 1
fi

target=/var/www/mia/hodiny.html
incoming=$(mktemp /var/www/mia/.hodiny.html.XXXXXX)
trap 'rm -f "$incoming"' EXIT

head -c 5000000 > "$incoming"
if [[ $(sha256sum < "$incoming") != "$expected_sha256  -" ]]; then
    echo "Refusing to deploy: upload is incomplete or corrupted" >&2
    exit 1
fi
if ! grep -q '<title>Hodiny</title>' "$incoming"; then
    echo "Refusing to deploy: upload is not the clock page" >&2
    exit 1
fi

cp -p "$target" "$target.bak-previous"
chown www-data:www-data "$incoming"
chmod 644 "$incoming"
mv "$incoming" "$target"
trap - EXIT

md5sum "$target"

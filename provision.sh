#! /usr/bin/env bash
#
# Provison Cloudflare KV.
#
set -o errexit
set -o xtrace

printf -vNOW '%(%Y_%m_%dT%H%M%S)T'

main() {
    if [[ -e .venv/bin/activate ]]
    then source .venv/bin/activate
    fi

    pnpm install
    pnpm list

    PATH="$PWD/node_modules/.bin:$PATH"

    local kv_title="DELETEME-$NOW"
    wrangler kv namespace create "$kv_title" --binding="$kv_title" --use-remote --update-config
}

main
exit $?

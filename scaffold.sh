#! /usr/bin/env bash
#
# Reproducing bug here vitest hangs with Cloudflare KV remote bindings.
#
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -o xtrace

PYVER=3.14t
NEVER='1.10.*'
C3VER='latest'

main() {
    HEADER=$(header)

    ensure_uv

    if [[ ! -d .venv ]]
    then uv venv --managed-python --python=$PYVER
    fi

    if [[ ! -e .venv/bin/npm ]]
    then # nodeenv is slow; only run once if npm missing
        uv pip install --upgrade "nodeenv==$NEVER"
        uv run nodeenv --python-virtualenv --node=lts
        uv run npm install --global npm
    fi

    uv pip list --verbose

    if [[ ! -e .venv/bin/pnpm ]]
    then uv run npm install --global pnpm
    fi

    HERE="${PWD##*/}"
    if [[ ! -e "$HERE" && ! -s wrangler.jsonc ]]
    then

        # C3 below with --git will make commits; so pre-unlock
        # GPG key so their silly UI spinner doesn't go insane
        local signingkey
        signingkey=$(git config --global --get user.signingkey)
        if [[ "$signingkey" ]]
        then gpg --sign --local-user "$signingkey" </dev/null >/dev/null
        fi

        export CREATE_CLOUDFLARE_TELEMETRY_DISABLED=1
        uv run pnpm create "cloudflare@$C3VER" "$HERE" \
            --type=hello-world --lang=ts --git --no-deploy

        if [[ -d "$HERE/.git" ]]
        then mv --verbose --no-clobber --target-directory=. "$HERE/.git"
        fi
        mv --verbose --no-clobber --target-directory=. \
            "$HERE"/.{editorconfig,gitignore,prettierrc,vscode}
        mv --verbose --no-clobber --target-directory=. "$HERE"/*
        rmdir --verbose "$HERE"

    fi |tee -a "create-cloudflare-$HERE.stdout"

    if [[ ! -s README.md ]]
    then
        cat <<-EOF
		# $HERE
		$HEADER

		## Instructions
		1. create a new empty dir
		1. download scaffold.sh into it
		1. edit the description header
		1. run ./scaffold.sh
	EOF
    fi |tee -a README.md

    local porcelain
    porcelain=$(git status --porcelain)
    if [[ "$porcelain" ]]
    then
        git add .
        git commit -m "$HEADER"
    fi

    local remote
    remote=$(git remote)
    if hash gh && test -z "$remote"
    then # TODO: allow org repos and private
        local whoami
        whoami=$(gh_whoami)
        if [[ "$whoami" ]]
        then
            local repo
            repo=$(gh repo view "$whoami/$HERE" 2>/dev/null ||:)
            if [[ -z "$repo" ]]
            then
                gh repo create "$HERE" --description="$HEADER" --public --source=. --push
            fi
        fi
    fi
}

ensure_uv() {
    if ! hash uv
    then
        local gistid=fdbfc77b924a08ceab7197d010280dac
        local uv_install=https://gist.github.com/dotysan/$gistid/raw/uv-install.sh

        if hash curl
        then
            curl --location $uv_install

        elif hash wget
        then
            wget --output-document=- $uv_install

        else
            echo "ERROR: Doh! Can't find either curl or wget." >&2
            return 1

        fi |bash

    else
        uv self update
    fi
}

header() {
    awk '
        NR==1 && /^#!/ {next} # shebang
        /^ *# *$/      {next} # empty comment lines
        /^ *# +/       {sub(/^ *# +/,"");print;next} # comments
                       {exit} # stop at first non-header
    ' "$0"
}

gh_whoami() {
    2>&1 gh auth status |awk '
        / Logged in to github.com a/ {
            print $7
            exit
        }'
}

main
exit

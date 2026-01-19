# vitest-hang-on-kv-remote

Reproducing bug. Wrangler won't shut down with Cloudflare KV remote bindings.

## Instructions

Clone this repo. See the bug doesn't occur.
1. run: `pnpm install`
1. run: `pnpm run dev`
1. Press `x` to exit.
1. Note everything works fine.

Then provision remote KV.
1. run: `./provision.sh`
1. run: `pnpm run dev`
1. Press `x` to exit.
1. Watch it hang...

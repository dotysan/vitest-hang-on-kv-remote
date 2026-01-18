# vitest-hang-on-kv-remote
Reproducing bug here vitest hangs with Cloudflare KV remote bindings.

## Instructions

Clone this repo. See the bug doesn't occur.
1. run: `pnpm run test`
1. Note runtimes are immediately shut down gracefully.

Then provision remote KV and see our outdated @cloudflare/vitest-pool-workers 0.8.71 does not understand the "remote" field in kv_namespaces.
1. run: `./provision.sh`
1. run: `pnpm run test`

Finally upgrade vitest-pool-workers and see the bug!
1. run: `pnpm add --save-dev @cloudflare/vitest-pool-workers@latest`
1. run: `pnpm run test`
1. Watch it hang! It would hang forever without the timeout.

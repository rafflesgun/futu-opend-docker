# Python Quote Smoke Test Design

## Summary

Add a small repo-local Python sample that can be run from a development
laptop against a deployed container on another machine, such as a Pi4.
The sample will use the upstream `py-futu-api` client library to connect
to the OpenD native TCP gateway on port `11111` and perform one quote
request as a smoke test.

## Goals

- Provide an easy way to verify that a deployed container exposes a
  working OpenD quote gateway on `11111`.
- Make the sample runnable from a separate machine, not only from the
  same host as the container.
- Keep the sample minimal, quote-only, and aligned with upstream
  `py-futu-api` usage.
- Document a straightforward local Python setup flow for a development
  laptop.

## Non-Goals

- Add trading examples or trade context usage.
- Bundle Python into the Docker image.
- Add a repo-wide Python package, test suite, or project tooling.
- Change container ports, runtime behavior, or Compose topology.
- Guarantee quote entitlements or market-data availability for every
  symbol.

## Current State

The repo already:

- publishes OpenD TCP on `11111`
- documents `11111` as the native TCP gateway
- supports local deployment through Docker Compose

There is no repo-local Python sample for validating OpenD from a laptop
using the upstream Python client.

## Proposed Design

### Sample layout

Add a new sample directory:

- `samples/python/requirements.txt`
- `samples/python/quote_smoke_test.py`

This keeps the Python dependency footprint isolated to the sample and
does not introduce Python-specific tooling at the repo root.

### Dependency model

`samples/python/requirements.txt` will contain the minimal dependency
needed to run the sample:

- `futu-api`

The user will install this locally in a virtual environment on the
laptop.

### CLI behavior

`quote_smoke_test.py` will be a small command-line script with these
flags:

- `--host`: required remote host or IP, such as the Pi4 LAN IP
- `--port`: optional OpenD TCP port, default `11111`
- `--code`: required security code, such as `HK.00700`

Requiring `--host` and `--code` avoids embedding assumptions about the
deployment topology or which market data the user wants to test.

### Runtime behavior

The script will:

1. create `ft.OpenQuoteContext(host=..., port=...)`
2. call one quote API using the upstream pattern, specifically
   `get_market_snapshot([code])`
3. check the returned status code
4. print a compact success message plus a small subset of returned data
5. exit non-zero with a readable error message on failure
6. always close the quote context in a `finally` block

`get_market_snapshot([code])` is preferred because it exercises a real
quote request without introducing subscription lifecycle complexity.

### Documentation

Update `README.md` with a short Python sample section that shows:

- this sample is intended for testing the deployed container from a
  separate laptop
- creating a local virtual environment
- installing dependencies from `samples/python/requirements.txt`
- running the sample against the Pi4 IP and port `11111`

Example usage:

```bash
python samples/python/quote_smoke_test.py \
  --host 192.168.1.50 \
  --code HK.00700
```

The docs will also note that:

- the OpenD container must already be running and reachable over the
  network
- OpenD must be logged in and properly configured
- the requested symbol must be valid for the account's available market
  data access

## Error Handling

- Connection failure to the remote host should print a clear error and
  exit non-zero.
- API-level failures from `py-futu-api` should print the returned error
  payload and exit non-zero.
- Missing required CLI arguments should be handled by standard argument
  parsing with usage output.
- The quote context must be closed even when the request fails.

## Testing and Verification

Verify with:

- a syntax check for the Python sample
- direct execution against a reachable OpenD deployment
- a doc review confirming the README example matches the script flags

This repo does not currently have a Python test harness, so verification
is centered on script correctness, successful smoke-test execution, and
documentation accuracy.

## Scope

This change is intentionally narrow:

- one sample directory with one script and one dependency file
- one README update describing the laptop-to-Pi4 smoke-test flow
- no Dockerfile, Compose, or runtime config changes

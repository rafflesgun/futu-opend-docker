# Python Quote Smoke Test Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a small Python sample that runs on a development laptop, connects to a deployed OpenD instance on port `11111`, and performs a single quote request to confirm the container is working.

**Architecture:** Keep the change isolated under `samples/python/` so the repo does not become a Python project at the root. Structure the script so its argument parsing and quote-call flow can be checked with a small stdlib unit test, then document the laptop-to-Pi4 workflow in `README.md`.

**Tech Stack:** Python 3, `futu-api`, Python `unittest`, Markdown docs

---

## File Map

- Create: `samples/python/requirements.txt`
  - Minimal runtime dependency list for running the sample on a laptop.

- Create: `samples/python/quote_smoke_test.py`
  - CLI script that connects to a remote OpenD host and issues one quote request.

- Create: `samples/python/test_quote_smoke_test.py`
  - Small stdlib unit tests for argument handling and success/error behavior.

- Modify: `README.md`
  - Add a short Python sample section showing local setup and remote execution against the Pi4.

### Task 1: Add the Failing Test First

**Files:**

- Create: `samples/python/test_quote_smoke_test.py`

- [ ] **Step 1: Write the failing test file**

Create `samples/python/test_quote_smoke_test.py` with this content:

```python
import unittest

import quote_smoke_test


class FakeContext:
    def __init__(self, ret_code, payload):
        self.ret_code = ret_code
        self.payload = payload
        self.closed = False
        self.calls = []

    def get_market_snapshot(self, codes):
        self.calls.append(codes)
        return self.ret_code, self.payload

    def close(self):
        self.closed = True


class FakeFutuModule:
    RET_OK = 0

    def __init__(self, context):
        self.context = context
        self.open_calls = []

    def OpenQuoteContext(self, host, port):
        self.open_calls.append((host, port))
        return self.context


class QuoteSmokeTestTests(unittest.TestCase):
    def test_parser_requires_host_and_code(self):
        parser = quote_smoke_test.build_parser()

        args = parser.parse_args(["--host", "192.168.1.50", "--code", "HK.00700"])

        self.assertEqual(args.host, "192.168.1.50")
        self.assertEqual(args.port, 11111)
        self.assertEqual(args.code, "HK.00700")

    def test_run_smoke_test_returns_zero_on_success(self):
        fake_context = FakeContext(0, [{"code": "HK.00700", "last_price": 510.0}])
        fake_ft = FakeFutuModule(fake_context)

        exit_code, message = quote_smoke_test.run_smoke_test(
            host="192.168.1.50",
            port=11111,
            code="HK.00700",
            ft_module=fake_ft,
        )

        self.assertEqual(exit_code, 0)
        self.assertIn("Quote smoke test succeeded", message)
        self.assertIn("HK.00700", message)
        self.assertEqual(fake_ft.open_calls, [("192.168.1.50", 11111)])
        self.assertEqual(fake_context.calls, [["HK.00700"]])
        self.assertTrue(fake_context.closed)

    def test_run_smoke_test_returns_one_on_api_error(self):
        fake_context = FakeContext(-1, "permission denied")
        fake_ft = FakeFutuModule(fake_context)

        exit_code, message = quote_smoke_test.run_smoke_test(
            host="192.168.1.50",
            port=11111,
            code="HK.00700",
            ft_module=fake_ft,
        )

        self.assertEqual(exit_code, 1)
        self.assertIn("Quote smoke test failed", message)
        self.assertIn("permission denied", message)
        self.assertTrue(fake_context.closed)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the test file to verify it fails for the right reason**

Run:

```bash
python3 -m unittest samples/python/test_quote_smoke_test.py -v
```

Expected: failure with `ModuleNotFoundError` or equivalent because `samples/python/quote_smoke_test.py` does not exist yet.

### Task 2: Implement the Minimal Python Smoke Test

**Files:**

- Create: `samples/python/quote_smoke_test.py`

- [ ] **Step 1: Write the minimal implementation to satisfy the tests**

Create `samples/python/quote_smoke_test.py` with this content:

```python
#!/usr/bin/env python3

import argparse
import sys


def build_parser():
    parser = argparse.ArgumentParser(
        description="Run a single Futu quote request against a remote OpenD host."
    )
    parser.add_argument("--host", required=True, help="Remote OpenD host or IP")
    parser.add_argument("--port", type=int, default=11111, help="OpenD TCP port")
    parser.add_argument("--code", required=True, help="Security code, for example HK.00700")
    return parser


def summarize_payload(payload):
    if isinstance(payload, list) and payload:
        row = payload[0]
        if isinstance(row, dict):
            code = row.get("code", "unknown")
            last_price = row.get("last_price", "n/a")
            return f"code={code} last_price={last_price}"
    return str(payload)


def run_smoke_test(host, port, code, ft_module):
    quote_ctx = ft_module.OpenQuoteContext(host=host, port=port)
    try:
        ret_code, payload = quote_ctx.get_market_snapshot([code])
        if ret_code != ft_module.RET_OK:
            return 1, f"Quote smoke test failed for {code}: {payload}"
        return 0, f"Quote smoke test succeeded for {code}: {summarize_payload(payload)}"
    finally:
        quote_ctx.close()


def main(argv=None):
    args = build_parser().parse_args(argv)

    import futu as ft

    exit_code, message = run_smoke_test(
        host=args.host,
        port=args.port,
        code=args.code,
        ft_module=ft,
    )

    if exit_code == 0:
        print(message)
    else:
        print(message, file=sys.stderr)
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 2: Run the unit tests again to verify they pass**

Run:

```bash
python3 -m unittest samples/python/test_quote_smoke_test.py -v
```

Expected: all three tests pass.

- [ ] **Step 3: Verify the script has valid Python syntax**

Run:

```bash
python3 -m py_compile samples/python/quote_smoke_test.py samples/python/test_quote_smoke_test.py
```

Expected: no output and exit code 0.

### Task 3: Add the Runtime Dependency File

**Files:**

- Create: `samples/python/requirements.txt`

- [ ] **Step 1: Add the minimal runtime dependency**

Create `samples/python/requirements.txt` with this content:

```text
futu-api
```

- [ ] **Step 2: Verify the sample directory now contains the expected files**

Run:

```bash
python3 - <<'PY'
from pathlib import Path

expected = {
    "samples/python/requirements.txt",
    "samples/python/quote_smoke_test.py",
    "samples/python/test_quote_smoke_test.py",
}
existing = {str(path) for path in Path("samples/python").glob("*")}
missing = sorted(expected - existing)
if missing:
    raise SystemExit(f"Missing sample files: {missing}")
print("Python sample files present")
PY
```

Expected: `Python sample files present`.

### Task 4: Document the Laptop-to-Pi4 Workflow

**Files:**

- Modify: `README.md`

- [ ] **Step 1: Add a Python sample usage section after the port overview or runtime usage section**

Add a new section like this to `README.md`:

```md
## Python sample usage

You can test the deployed OpenD container from another machine, such as
your development laptop, by connecting to the native TCP gateway on
port `11111` with the upstream Python client.

Create a local virtual environment and install the sample dependency:

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r samples/python/requirements.txt
```

Run the smoke test against the Pi4 host:

```bash
python samples/python/quote_smoke_test.py \
  --host 192.168.1.50 \
  --code HK.00700
```

Optional flags:

- `--port` defaults to `11111`

Notes:

- the container must already be running and reachable from your laptop
- OpenD must be logged in and ready to serve quote requests
- the symbol you pass to `--code` must be valid for your account's
  available market data access
```

- [ ] **Step 2: Verify the README example matches the script interface exactly**

Check that the docs mention only supported flags:

- `--host`
- `--port`
- `--code`

There should be no mention of local-only `127.0.0.1` usage in the main example because the target workflow is laptop to Pi4.

### Task 5: End-to-End Verification

**Files:**

- Verify: `samples/python/requirements.txt`
- Verify: `samples/python/quote_smoke_test.py`
- Verify: `samples/python/test_quote_smoke_test.py`
- Verify: `README.md`

- [ ] **Step 1: Re-run the local verification commands as one batch**

Run:

```bash
python3 -m unittest samples/python/test_quote_smoke_test.py -v && \
python3 -m py_compile samples/python/quote_smoke_test.py samples/python/test_quote_smoke_test.py
```

Expected: unit tests pass and both files compile.

- [ ] **Step 2: Review the targeted diff**

Run:

```bash
git diff -- README.md samples/python/requirements.txt samples/python/quote_smoke_test.py samples/python/test_quote_smoke_test.py docs/superpowers/specs/2026-04-23-python-quote-smoke-test-design.md docs/superpowers/plans/2026-04-23-python-quote-smoke-test.md
```

Expected: only the Python sample files, README update, and design/plan docs appear.

- [ ] **Step 3: Run the real smoke test from the laptop after the container is deployed on the Pi4**

Run:

```bash
python samples/python/quote_smoke_test.py --host 192.168.1.50 --code HK.00700
```

Expected: a success line starting with `Quote smoke test succeeded` if the gateway is reachable and logged in. If it fails, the error should be printed clearly and the script should exit non-zero.

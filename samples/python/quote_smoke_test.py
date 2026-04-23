#!/usr/bin/env python3

import argparse
import sys


def build_parser():
    parser = argparse.ArgumentParser(
        description="Run a single Futu quote request against a remote OpenD host."
    )
    parser.add_argument("--host", required=True, help="Remote OpenD host or IP")
    parser.add_argument("--port", type=int, default=11111, help="OpenD TCP port")
    parser.add_argument(
        "--code", required=True, help="Security code, for example HK.00700"
    )
    return parser


def summarize_payload(payload):
    if hasattr(payload, "empty") and hasattr(payload, "iloc"):
        if not payload.empty:
            row = payload.iloc[0]
            code = row.get("code", "unknown")
            last_price = row.get("last_price", "n/a")
            return f"code={code} last_price={last_price}"

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

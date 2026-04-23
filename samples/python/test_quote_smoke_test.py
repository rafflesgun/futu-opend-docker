import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

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

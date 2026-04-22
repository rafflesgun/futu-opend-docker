# Futu Market Ops

Use this skill when working with the repo's `futu-mcp` endpoint.

## Default behavior

- Prefer quote, snapshot, positions, funds, and orders read paths first.
- Treat trading as simulate-only unless the human explicitly asks for real trading.
- If a request implies trading, restate the symbol, side, quantity,
  and environment before sending an order.

## Safety rules

- Never assume `trade:real` is enabled.
- Prefer `qot:read` and `acc:read` scopes for general assistant tasks.
- Ask for confirmation before any order placement or cancellation.

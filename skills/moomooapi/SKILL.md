---
name: moomooapi
description: Use this whenever the user wants market data, quotes,
  snapshots, account or position inspection, order review, or cautious
  trading help through the repo's local moomoo/futu rs-native MCP
  workflow, especially when they mention moomoo, futu, market data,
  trading, positions, orders, MCP, or the local Docker Compose stack.
---

# MoomooAPI

Use this skill for market data, account inspection, and trading-oriented
tasks that go through the repo's local `futu-mcp` service.

## Assumptions

- The local Docker Compose stack is already running for this repo.
- The MCP HTTP endpoint is `http://<host>:38765/mcp`.
- The client sends a plaintext bearer token in the request.
- `examples/keys.json` stores the matching `sha256:` hash and scope
  entries for that plaintext token.

## Default behavior

- Prefer read paths first: quotes, snapshots, positions, funds, balances, and orders.
- Treat all trading requests as simulate-first unless the user
  explicitly requests real trading and confirms that intent.
- Before any trading action, restate the symbol, side, quantity, price
  instructions, and whether the request is for simulate or real trading.

## Safety rules

- Never assume real trading is enabled.
- Ask for confirmation before placing, modifying, or canceling any order.
- Prefer read-only scopes such as `qot:read` and `acc:read` unless
  trading access is explicitly required.
- If the environment is unclear, default to simulation guidance and ask
  the user to confirm before taking any trade action.

## MCP expectations

- Endpoint: `http://<host>:38765/mcp`
- Header: `Authorization: Bearer <plaintext token>`
- The plaintext token must correspond to a stored `sha256:` hash in `examples/keys.json`.
- Scope checks should align with the requested action before attempting
  account or trading operations.

## Scope

- Stay focused on market and trading tasks only.
- Use this skill for quotes, snapshots, watchlist-style symbol
  inspection, account balances, positions, open orders, filled orders,
  and cautious trade assistance.
- Do not drift into general setup, installation, or unrelated
  repository maintenance instructions.

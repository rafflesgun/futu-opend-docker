# Nanobot Integration

## Files

- `mcp-http-example.json`: MCP HTTP client template for nanobot
- `skills/futu-market-ops.md`: repo-local skill/prompt for market and account workflows

## HTTP MCP endpoint

Point nanobot at `http://<host>:38765/mcp` and send:

```http
Authorization: Bearer <plaintext MCP token>
```

The checked-in example token is `fc_replace_me`, which matches the
example hash in `examples/keys.json`. The local compose stack uses that
same token by default unless you override `FUTU_MCP_API_KEY` locally.

Use a key with `qot:read` and `acc:read` first. Keep
`trade:simulate` separate from any real-trading workflow.

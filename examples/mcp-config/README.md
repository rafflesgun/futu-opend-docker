# Nanobot Integration

## Files

- `../skills/moomooapi/SKILL.md`: compliant market/trading skill package
- `mcp-http-example.json`: MCP HTTP client template for nanobot

`mcp-http-example.json` is a helper client configuration file. It is not a
skill package.

## Install the skill

Copy `skills/moomooapi/` into a Claude-compatible skills directory, for
example:

```bash
mkdir -p .claude/skills
cp -R skills/moomooapi .claude/skills/
```

The real skill entry point is `skills/moomooapi/SKILL.md`. Any helper Markdown
files in this repo support that package, but are not standalone skills.

## HTTP MCP endpoint

Point nanobot at `http://<host>:38765/mcp` and send:

```http
Authorization: Bearer <plaintext MCP token>
```

The checked-in example token is `fc_replace_me`, which matches the
example hash in `examples/keys.json`. The local compose stack uses that same
token by default unless you override `FUTU_MCP_API_KEY` locally.

Use a key with `qot:read` and `acc:read` first. Keep
`trade:simulate` separate from any real-trading workflow.

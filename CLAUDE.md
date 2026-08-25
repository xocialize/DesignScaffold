# DesignScaffold — area contract

The fleet's single design authority (AB-D-0042): `Tokens` + the shared component catalog
(`Docs/COMPONENTS.md`, generated — check it BEFORE building any UI). Tokens are added HERE,
never invented by consumers; a missing value is an ask, not a literal.

## Bridge identity

**AREA-ID: `design-scaffold`** (aliases: `DesignScaffold`, `design`) — work in this directory answers for that
identity on the bridge. **Session start: `bridge assume design-scaffold`** — owed asks, open
tasks, and the context pack in one command. Assumption is informational, never a
lock: a stale last-assumed age in `bridge areas` means nobody is home, and you take
over by assuming. File answers/asks under this id; the roster validates recipients.

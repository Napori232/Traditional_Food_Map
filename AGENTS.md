# Local Collaboration Rules

## Tool Reconnection

When a tool, editor bridge, or MCP connection reports a temporary connection
failure or reconnect problem:

- Wait 20 seconds before trying again.
- Retry the connection after the wait.
- Continue retrying at 20-second intervals until the connection succeeds.
- Do not treat a failed attempt as a reason to stop the current task.

This rule applies to this project only. It does not change Codex's underlying
service-level retry behavior.

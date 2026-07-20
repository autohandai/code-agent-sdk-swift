# Changelog

## Unreleased

### Added

- Typed community skill registry discovery through `getSkillsRegistry(_:)`.
- Typed user/project skill installation through `installSkill(_:)`.
- Typed MCP server discovery through `listMCPServers()`.
- Typed MCP tool discovery with an optional server filter through
  `listMCPTools(_:)`.
- Typed persisted MCP configuration discovery through
  `getMCPServerConfigs()`.
- A macOS-only `AutohandSDK` lifecycle facade over `AutohandCLIClient`.
- A deterministic release startup benchmark with 5 warmups, 50 measurements,
  and a p95 budget below 50 milliseconds.

### Fixed

- `Runner` now honors `Agent.tools` instead of advertising every built-in tool.
- `Runner` now enforces `PermissionManager` decisions before tool execution.
- Plan, parallel, and reflexion loops now execute their own prompts and consume
  per-run strategy options.
- Cancelling an async CLI request now wakes the blocking transport wait and
  throws `CancellationError` promptly while ID-based response routing keeps the
  client reusable for subsequent requests.
- Failed post-launch feature initialization now closes the CLI process and
  restores a retryable lifecycle state.
- `Runner` snapshots hook and permission configuration under synchronization,
  and cancelling a stream consumer now cancels its owned execution task.

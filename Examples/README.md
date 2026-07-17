# Swift Examples

Runnable Swift scripts for the AgentSDK, mirroring the TypeScript and Python SDK examples.

## Prerequisites

- macOS 14+ with Swift 6.0+
- An OpenAI or OpenRouter API key

Set your API key:

```bash
export OPENAI_API_KEY="sk-..."
```

## Run

From the AgentSDK directory:

```bash
swift run 01-hello-agent
swift run 02-streaming-query
swift run 03-code-reviewer
swift run 04-bash-command
swift run 05-file-editor
swift run 06-prompt-skills
swift run 07-direct-skills
swift run 08-memory-management
swift run 10-multi-tool-reasoning
swift run 13-permissions
swift run 20-sdlc-discovery-plan
swift run 21-sdlc-gated-implementation
swift run 22-sdlc-release-readiness
swift run 23-system-prompts
swift run 24-high-level-agent
swift run 25-structured-json
swift run 27-autoresearch-ledger
swift run loop-strategies
swift run sdk-control-features
swift run basic-agent
```

## Example Index

| # | File | Description |
|---|------|-------------|
| 01 | `01-hello-agent.swift` | Minimal prompt with `Runner.runSync()` |
| 02 | `02-streaming-query.swift` | Real-time event streaming with `Runner.runStream()` |
| 03 | `03-code-reviewer.swift` | File-aware review with edit capabilities |
| 04 | `04-bash-command.swift` | Shell command execution flow |
| 05 | `05-file-editor.swift` | File editing with permission routing |
| 06 | `06-prompt-skills.swift` | Skills referenced in prompt text |
| 07 | `07-direct-skills.swift` | Direct skill names via customInstructions |
| 08 | `08-memory-management.swift` | Memory persistence across sessions |
| 10 | `10-multi-tool-reasoning.swift` | Multi-step codebase analysis with multiple tools |
| 13 | `13-permissions.swift` | Permission modes: yolo, ask, deny comparison |
| 20 | `20-sdlc-discovery-plan.swift` | SDLC discovery and planning phase |
| 21 | `21-sdlc-gated-implementation.swift` | Gated implementation: plan → review → execute |
| 22 | `22-sdlc-release-readiness.swift` | Release readiness check with tool summary |
| 23 | `23-system-prompts.swift` | System prompt append/replace configuration |
| 24 | `24-high-level-agent.swift` | High-level Agent API with clean lifecycle |
| 25 | `25-structured-json.swift` | Structured JSON output with Codable validation |
| 27 | `27-autoresearch-ledger.swift` | Typed replayable autoresearch lifecycle and ledger operations |
| — | `loop-strategies.swift` | All four loop strategies compared |
| — | `sdk-control-features.swift` | Runtime configuration and control methods |
| — | `basic-agent.swift` | Full agent setup with all configuration options |

Examples that create or edit files use `/tmp/` for scratch output.

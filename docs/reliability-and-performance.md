# Reliability and performance

## Startup service-level objective

The Swift SDK checks a strict p95 startup budget of less than 50 milliseconds.
Run the deterministic benchmark on macOS:

```bash
Scripts/benchmark-startup.sh
```

The script builds an optimized native C JSON-RPC fixture and the release Swift
benchmark, then emits one JSON object. Every metric uses exactly 5 warmups and
50 measured samples:

- `publicImportMs`: initializes representative public API values inside an
  already-running Swift process. Swift imports are resolved before `main`, so
  this deliberately excludes executable and Swift-runtime boot.
- `sdkStartReturnMs`: times `AutohandSDK.start()` returning after the fixture
  process is launched; cleanup is outside the timer.
- `fixtureSpawnToFirstRpcMs`: times process launch plus a successful typed
  `autohand.mcp.listServers` round trip.

Measured on 2026-07-20 in the repository's macOS validation environment:

```json
{
  "language": "swift",
  "budgetMs": 50,
  "metrics": {
    "publicImportMs": { "samples": 50, "medianMs": 0.000292, "p95Ms": 0.000375, "maxMs": 0.000542, "passed": true },
    "sdkStartReturnMs": { "samples": 50, "medianMs": 1.516542, "p95Ms": 4.562583, "maxMs": 5.717, "passed": true },
    "fixtureSpawnToFirstRpcMs": { "samples": 50, "medianMs": 4.188646, "p95Ms": 10.143083, "maxMs": 15.702709, "passed": true }
  },
  "passed": true
}
```

This isolates SDK construction, process launch, framing, and decoding. It does
not claim that a user's full Autohand CLI configuration, MCP connections,
network provider, or first model response completes within 50 milliseconds.

## Transport guarantees

- Caller cancellation unregisters that JSON-RPC ID, wakes an in-flight or
  request-gate-queued wait, and throws `CancellationError` instead of waiting
  for the configured timeout. The CLI may finish the abandoned operation, but
  its late response is discarded by ID and subsequent requests remain usable.
- Startup feature initialization is transactional. A failed configuration RPC
  closes the child, clears handles, and leaves the client retryable.
- `close()` remains idempotent and `deinit` closes an owned subprocess.

## Agent execution guarantees

- `Agent.tools` is enforced as an allow-list at schema and execution time.
- An installed `PermissionManager` is consulted before any tool implementation.
- Plan, parallel, and reflexion strategies send their own option-aware prompts
  rather than falling back to the ReAct prompt. These options are model guidance:
  the current executor processes returned tool calls serially and does not claim
  SDK-scheduled parallelism or a separate deterministic reflection evaluator.
- Cancelling a `runStream` consumer cancels its owned provider/tool execution
  task rather than leaving it running in the background.

/// AgentSDK — Public API entry point.
/// Re-exports all public types for convenient single-import usage.

@_exported import Foundation

// AgentSDK is a namespace — all types are exported via individual files.
// Import AgentSDK to get access to:
//
// - Agent, Runner
// - Provider, OpenAIProvider, ProviderFactory
// - ToolDefinition, ToolRegistry, DefaultToolRegistry
// - LoopStrategy, ReActStrategy, PlanAndExecuteStrategy, ParallelStrategy, ReflexionStrategy
// - HookManager, HookDefinition, HookContext
// - PermissionManager, PermissionRequest, PermissionResult
// - AgentSDKError (structured error hierarchy)
// - Core types: Message, Session, RunResult, StreamEvent, ToolCall, ToolName, etc.

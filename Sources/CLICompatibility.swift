import Foundation

func validateCLIArguments(_ args: [String]) throws {
  let unsupported: Set<String> = ["--agents-md","--no-agents-md","--agents-md-create","--agents-md-auto-update","--agents-md-path","--auto-save-interval","--compression-threshold","--summarization-threshold","--skills","--skill-sources","--install-missing-skills","--permission-mode","--permission-allow-list","--permission-deny-list"]
  let switches: Set<String> = ["--bare","--offline","--yes","--y","--dry-run","--debug","--auto-commit","-c","--unrestricted","--restricted","--plan","--answer-only","--setup-only","--no-idle-logout","--auto-skill","--learn","--learn-update","--project","--permissions","--settings","--traces-on","--traces-off","--login","--logout","--patch","--acp","--sdk-resume-last","--tmux","--auto-mode","--no-worktree","--interactive-on-complete","--setup","--about","--feedback","--cc","--context-compact","--no-cc","--no-context-compact","--ephemeral"]
  var index = 0
  while index < args.count {
    let argument = args[index]
    if unsupported.contains(argument) {
      throw AgentSDKError.agentConfig(message: argument + " is unsupported by the current CLI; use a supported CLI option or runtime RPC instead")
    }
    index += switches.contains(argument) ? 1 : 2
  }
}

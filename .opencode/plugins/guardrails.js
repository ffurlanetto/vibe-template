/**
 * guardrails.js — opencode side of the project's security guardrails.
 *
 * It owns no logic of its own: it calls the very same scripts that Claude Code
 * runs as hooks, so both agents enforce one implementation.
 *
 *   .claude/hooks/block-commit-secrets.sh  → blocks a commit carrying a secret
 *   .claude/hooks/require-tests.sh         → blocks a commit that skips its tests
 *   .claude/hooks/scan-secrets.sh          → warns after writing a likely secret
 *   .claude/hooks/ledger.sh                → records subagent starts and stops
 *
 * Script exit contract:  0 = clean · 0 + stderr = warning · 2 = block
 *
 * Claude Code has SubagentStart/SubagentStop hooks; opencode does not, so the
 * equivalent events are emitted around the `task` tool. The contract both sides
 * honour is the ledger file, not either event API (ADR-003).
 */

const WRITE_TOOLS = new Set(["write", "edit", "apply_patch", "patch"])
const COMMIT_RE = /\bgit\b[^\n]*\bcommit\b/

function agentTypeOf(args) {
  if (!args || typeof args !== "object") return "task"
  return args.subagent_type || args.agent || args.agentType || "task"
}

function filePathOf(args) {
  if (!args || typeof args !== "object") return ""
  return args.filePath || args.file_path || args.path || ""
}

export const Guardrails = async ({ $, directory, worktree, client }) => {
  const root = worktree || directory
  const hook = (name) => `${root}/.claude/hooks/${name}`

  const log = async (level, message) => {
    try {
      await client.app.log({ body: { service: "guardrails", level, message } })
    } catch {
      // Logging must never break a tool call.
    }
  }

  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool === "task") {
        await $`${hook("ledger.sh")} agent.start ${agentTypeOf(output?.args)} ${input.callID}`
          .cwd(root).nothrow().quiet()
        return
      }
      if (input.tool !== "bash") return
      const command = output?.args?.command
      if (typeof command !== "string" || !COMMIT_RE.test(command)) return

      // Both gates run, in the order a reviewer would care about: a leaked secret
      // first, a missing test second.
      for (const [script, fallback] of [
        ["block-commit-secrets.sh", "Commit blocked: a secret was found in the staged changes."],
        ["require-tests.sh", "Commit blocked: source changed without a test (AGENTS.md A4)."],
      ]) {
        const result = await $`${hook(script)} ${command}`.cwd(root).nothrow().quiet()
        const message = result.stderr.toString().trim()

        if (result.exitCode === 2) {
          await log("warn", `${script} blocked a commit`)
          throw new Error(message || fallback)
        }
        // Exit 0 with output is an advisory the author should still see.
        if (message) await log("info", message)
      }
    },

    "tool.execute.after": async (input, output) => {
      if (input.tool === "task") {
        const summary = typeof output?.output === "string" ? output.output : ""
        await $`${hook("ledger.sh")} agent.stop ${agentTypeOf(input.args)} ${input.callID} ${summary}`
          .cwd(root).nothrow().quiet()
        return
      }
      if (!WRITE_TOOLS.has(input.tool)) return
      const file = filePathOf(input.args)
      if (!file) return

      const result = await $`${hook("scan-secrets.sh")} ${file}`.cwd(root).nothrow().quiet()
      const warning = result.stderr.toString().trim()
      if (warning) await log("warn", warning)
    },
  }
}

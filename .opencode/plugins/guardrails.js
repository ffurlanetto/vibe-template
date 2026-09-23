/**
 * guardrails.js — opencode side of the project's security guardrails.
 *
 * It owns no logic of its own: it calls the very same scripts that Claude Code
 * runs as hooks, so both agents enforce one implementation.
 *
 *   .claude/hooks/block-commit-secrets.sh  → blocks a commit carrying a secret
 *   .claude/hooks/scan-secrets.sh          → warns after writing a likely secret
 *
 * Script exit contract:  0 = clean · 0 + stderr = warning · 2 = block
 */

const WRITE_TOOLS = new Set(["write", "edit", "apply_patch", "patch"])
const COMMIT_RE = /\bgit\b[^\n]*\bcommit\b/

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
      if (input.tool !== "bash") return
      const command = output?.args?.command
      if (typeof command !== "string" || !COMMIT_RE.test(command)) return

      const result = await $`${hook("block-commit-secrets.sh")} ${command}`.cwd(root).nothrow().quiet()

      if (result.exitCode === 2) {
        const reason = result.stderr.toString().trim() || "Commit blocked: a secret was found in the staged changes."
        await log("warn", "blocked a commit carrying a secret")
        throw new Error(reason)
      }
    },

    "tool.execute.after": async (input) => {
      if (!WRITE_TOOLS.has(input.tool)) return
      const file = filePathOf(input.args)
      if (!file) return

      const result = await $`${hook("scan-secrets.sh")} ${file}`.cwd(root).nothrow().quiet()
      const warning = result.stderr.toString().trim()
      if (warning) await log("warn", warning)
    },
  }
}

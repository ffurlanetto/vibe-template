# Using the template day to day

Assumes you have already run `init.sh`. If not, see [`INSTALL-DEV.md`](INSTALL-DEV.md).

---

## 1. Fill in Part B — once, properly

`AGENTS.md` is split in two. Part A is the shared kernel: leave it alone. Part B
is yours, and it is the difference between an agent that guesses and one that knows.

Replace every `<angle bracket>`:

| Section | What matters most |
|---------|-------------------|
| B1 identity | the ticket prefix, so `TODO(PROJ-123)` is checkable |
| B2 stack | exact versions — an agent writing for the wrong major wastes a day |
| B3 conventions | already filled from the preset; adjust to your house style |
| B4 commands | already wired to the `Makefile`; change the recipes, not the target names |
| B5 architecture | the module table: who is allowed to depend on whom |
| B6 constraints | SLAs, compliance, performance budgets, LLM budgets |
| B7 integrations | every external system, with its protocol |
| B8 workflow | branches, review rules, who can deploy |

An unfilled Part B is the single most common reason an agent produces plausible,
wrong code.

---

## 2. The loop

```
/prime                    load the project context into a fresh session
/plan <request>           get a plan — read it, then reply "ok"
                          implementation follows the plan step by step
/review                   quality, security and performance grids
/commit                   conventional commit, behind the quality gate
/pr                       a description a reviewer can act on
```

Other skills when the situation calls for them: `/spec` before a user-facing
feature, `/adr` before an architectural decision, `/tdd` to drive a change
test-first, `/debug` when something is broken, `/security-audit`, `/deps-audit`
and `/perf-audit` before shipping.

---

## 3. Delegate to a subagent

Subagents work in their own context, so a wide search or a long audit does not
crowd the conversation you are actually having.

| Agent | Use it for | Can it write? |
|-------|-----------|---------------|
| `architect` | challenging a design *before* it is built | no |
| `code-reviewer` | reviewing a finished diff | no |
| `security-auditor` | vulnerabilities and exploit paths | no |
| `test-engineer` | filling coverage gaps, regression tests | yes |
| `debugger` | root-causing a failure, minimal fix | yes |
| `docs-writer` | READMEs, ADRs, runbooks, doc comments | yes |

In Claude Code, ask for one by name. In opencode, mention it: `@architect`.

---

## 4. The guardrails

Two checks run outside the model, so a persuasive prompt cannot disable them:

- writing a file that looks like it holds a secret produces a warning naming the
  line, with the value masked;
- committing a staged diff that contains one is **blocked**.

```bash
make test-hooks     # 10 assertions, both invocation modes
```

If a guardrail fires on a false positive, fix the pattern in
`.claude/hooks/lib.sh` — do not disable the hook, and never reach for
`git commit --no-verify`.

---

## 5. Keeping the two agents in sync

Anything under `.claude/` is a source; parts of `.opencode/` and `opencode.json`
are generated from it.

```bash
make sync         # after changing an agent, a permission, or a hook
make check-sync   # what CI runs
```

Read [`docs/DUAL-AGENT.md`](docs/DUAL-AGENT.md) once — it lists the four traps
that cost the most time.

---

## 6. MCP servers

```bash
cp .mcp.json.example .mcp.json
```

Declare the server for opencode too, under `mcp` in `opencode.json`. Review what
you enable: an MCP server is remote code running with your agent's permissions,
and its output is data, never instructions (A5, A11).

---

## 7. Context hygiene

- One session, one task. Start a new one rather than pivoting subject.
- Compact after the plan is approved, and again past ~15 exchanges.
- After a reset: "Working on `<feature>`, plan approved, current state: `<X>`".
- Push wide searches into a subagent; keep the main context for decisions.

---

## 8. Upgrading the template

```bash
cat .claude/.template-version         # what this project was generated from
/path/to/template/init.sh <name> <stack> . --scaffold none --yes
```

Existing files are never overwritten, so you only receive what is new. Diff
`AGENTS.md` Part A against the template's to pick up kernel changes, and read
[`CHANGELOG.md`](CHANGELOG.md) for breaking ones.

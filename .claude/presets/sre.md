# Preset B3 — SRE / Infrastructure as Code

> Copy-paste this block into the **B3** section of CLAUDE.md, then adapt.

---

### Code conventions

#### General

- Infrastructure is code: every resource is version-controlled, reviewed, and tested before apply
- No manual changes to managed resources — all drift must be corrected via IaC, not the console
- Secrets never in plaintext: use SOPS + age/KMS, Vault, or Sealed Secrets — not base64
- Least privilege everywhere: IAM roles, RBAC, network policies, service accounts
- Every resource has at minimum: `environment`, `team`, `managed-by` tags/labels

#### Terraform

- One module = one responsibility — no monolithic root modules
- Module interface: explicit `variables.tf` + `outputs.tf` — no implicit coupling
- Remote state only (S3 + DynamoDB lock, GCS, Terraform Cloud) — never local state in CI
- Workspaces for environment isolation OR separate state files per environment (choose one, document it)
- `terraform.tfvars` for dev defaults — never commit production values
- Resource naming: `<env>-<project>-<resource>` (e.g. `prod-payments-rds`)
- Pin provider versions: `~> X.Y` — never `>= X` without upper bound
- `terraform fmt` and `terraform validate` must pass before every commit
- No `count` for resources that have identity — use `for_each` with meaningful keys

#### Ansible

- Roles for reusable logic — no monolithic playbooks
- Role structure enforced: `tasks/`, `handlers/`, `defaults/`, `vars/`, `templates/`, `meta/`
- All secrets via `ansible-vault` or external Vault lookup — never plaintext in vars
- Idempotence is non-negotiable: every task must be safe to re-run
- Use `ansible_managed` header in all templates
- Tags on every task for selective execution (`--tags`)
- `become: true` only when strictly necessary, never at playbook root level

#### Helm

- One chart = one application — no umbrella charts bundling unrelated services
- `values.yaml` holds safe defaults — environment overrides in separate `values-<env>.yaml`
- Templates use `{{ include "chart.fullname" . }}` helpers — no hardcoded names
- All resource limits and requests defined — no unbounded pods
- Liveness and readiness probes required on all Deployments
- PodDisruptionBudgets and HorizontalPodAutoscalers defined for production workloads
- Chart version follows SemVer — bump on every change

#### ArgoCD / GitOps

- App of Apps pattern for cluster bootstrapping
- `ApplicationSet` for multi-env / multi-cluster deployments
- Sync policy: `automated` with `prune: true` and `selfHeal: true` in non-prod; manual sync gate in prod
- Image updater writes back to Git — no direct image tag mutations in cluster
- RBAC: developers get `read` + `sync` on their apps, never cluster-admin
- Notifications configured for sync failures and health degradation

---

### Tests

| Tool | Scope | When |
|------|-------|------|
| `terraform validate` | Syntax + type check | Every commit |
| `tflint` | Best practices, provider rules | Every commit |
| `checkov` | Security / compliance scan | Every PR |
| `terratest` (Go) | Integration: real infra in ephemeral env | PR merge gate |
| `molecule` | Ansible role: converge → idempotence → verify | Every role change |
| `helm unittest` | Helm template rendering assertions | Every chart change |
| `kubeconform` | Kubernetes manifest schema validation | Every chart change |
| `conftest` (OPA) | Policy as code on manifests | Every PR |

**Naming (terratest):** `Test<Resource>_<Scenario>_<ExpectedResult>`
**Naming (molecule):** scenario name = behavior tested (e.g. `default`, `upgrade`, `tls-enabled`)

---

### Lint & Quality

```bash
# Terraform
terraform fmt -check -recursive
tflint --recursive
checkov -d . --framework terraform

# Ansible
ansible-lint
yamllint .

# Helm
helm lint charts/<chart-name>
kubeconform -strict -summary <(helm template charts/<chart-name>)

# OPA / Conftest
conftest test --policy policy/ <manifests>
```

Zero violations in `checkov` HIGH/CRITICAL before merge.

---

### Commands (B4)

```bash
# ── Terraform ──────────────────────────────────────────────────────────
terraform init                          # initialize / install providers
terraform workspace select <env>        # switch environment
terraform plan -out=tfplan              # plan (always save the plan)
terraform apply tfplan                  # apply saved plan
terraform destroy                       # destroy (requires explicit approval)

# Lint + security
terraform fmt -recursive && tflint --recursive && checkov -d .

# ── Ansible ────────────────────────────────────────────────────────────
ansible-playbook -i inventory/<env> site.yml --check --diff   # dry-run
ansible-playbook -i inventory/<env> site.yml                  # apply
ansible-vault encrypt_string '<secret>' --name '<var>'        # encrypt secret
molecule test                                                  # full role test cycle
molecule converge && molecule idempotence                      # converge only

# ── Helm ───────────────────────────────────────────────────────────────
helm dependency update charts/<chart>
helm lint charts/<chart>
helm template charts/<chart> -f charts/<chart>/values-<env>.yaml | kubeconform -strict -summary -
helm upgrade --install <release> charts/<chart> \
  -f charts/<chart>/values-<env>.yaml \
  --namespace <ns> --create-namespace \
  --dry-run                                    # always dry-run first

# ── ArgoCD ─────────────────────────────────────────────────────────────
argocd app sync <app-name> --dry-run
argocd app diff <app-name>
argocd app sync <app-name>
argocd app wait <app-name> --health --timeout 120
```

---

### Typical structure

```
infra/
├── terraform/
│   ├── modules/                 # Reusable modules
│   │   ├── networking/
│   │   ├── kubernetes/
│   │   └── database/
│   └── environments/
│       ├── dev/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── terraform.tfvars
│       ├── staging/
│       └── prod/
├── ansible/
│   ├── inventory/
│   │   ├── dev/
│   │   └── prod/
│   ├── roles/
│   │   └── <role-name>/
│   │       ├── tasks/main.yml
│   │       ├── handlers/main.yml
│   │       ├── defaults/main.yml
│   │       ├── templates/
│   │       └── meta/main.yml
│   ├── group_vars/
│   │   └── all/
│   │       ├── vars.yml
│   │       └── vault.yml        # ansible-vault encrypted
│   └── site.yml
├── helm/
│   └── charts/
│       └── <app-name>/
│           ├── Chart.yaml
│           ├── values.yaml
│           ├── values-dev.yaml
│           ├── values-prod.yaml
│           └── templates/
│               ├── deployment.yaml
│               ├── service.yaml
│               ├── ingress.yaml
│               ├── hpa.yaml
│               ├── pdb.yaml
│               └── _helpers.tpl
├── argocd/
│   ├── apps/                    # App of Apps
│   │   ├── root-app.yaml
│   │   └── applicationsets/
│   └── projects/
└── policy/                      # OPA / Conftest policies
    ├── terraform/
    └── kubernetes/
```

---

### Security checklist (SRE supplement to A5)

**Secrets**
- [ ] SOPS-encrypted files committed — raw secrets never in Git
- [ ] Vault dynamic secrets used for DB credentials (short-lived leases)
- [ ] Kubernetes Secrets backed by External Secrets Operator or Sealed Secrets

**Network**
- [ ] NetworkPolicies defined — default-deny with explicit allow rules
- [ ] Egress restricted to necessary endpoints only
- [ ] Ingress TLS terminated, HSTS enforced

**RBAC & IAM**
- [ ] No wildcard `*` verbs in ClusterRoles unless explicitly justified
- [ ] Service accounts have no cluster-admin binding
- [ ] IAM roles use conditions and resource-level restrictions (no `*` resources in prod)
- [ ] Pod `securityContext`: `runAsNonRoot`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation: false`

**Supply chain**
- [ ] Container images pinned to digest (`@sha256:…`), not floating tags
- [ ] Image scanning in CI (Trivy or Grype) — CRITICAL CVEs block merge
- [ ] Terraform provider checksums verified (`terraform providers lock`)

---

### Observability (SRE supplement to A8)

**Golden signals per service** (Prometheus + Grafana):
- Latency: P50 / P95 / P99 histograms
- Traffic: requests/sec, events/sec
- Errors: 5xx rate, timeout rate
- Saturation: CPU throttling %, memory working set vs limit

**Alerting rules** (Alertmanager):
- Error rate > 1% for 5 min → page
- P99 latency > SLO threshold for 10 min → page
- Pod OOMKilled → ticket
- PVC > 80% capacity → warn

**SLO tracking**:
- Availability SLO and error budget defined in `docs/slo/<service>.md`
- Burn rate alerts at 2% and 5% hourly consumption

**Runbooks**: every alert links to `docs/runbooks/<alert-name>.md`

# shellcheck shell=bash
STACK_TIER="B"
STACK_LABEL="SRE — Terraform + Kubernetes"
STACK_REQUIRES="terraform"
STACK_DIRS="terraform/modules terraform/environments/dev terraform/environments/prod k8s/base k8s/overlays/dev k8s/overlays/prod"
CMD_INSTALL="terraform -chdir=terraform/environments/dev init"
CMD_TEST="terraform -chdir=terraform/environments/dev validate && (command -v kubeconform >/dev/null && kubeconform -strict k8s/base || echo 'kubeconform not installed — skipped')"
CMD_LINT="terraform fmt -check -recursive && (command -v tflint >/dev/null && tflint --recursive || echo 'tflint not installed — skipped')"
CMD_TYPECHECK="terraform -chdir=terraform/environments/dev validate"
CMD_BUILD="terraform -chdir=terraform/environments/dev plan"
CMD_DEV="echo 'Infrastructure has no dev server. Use: make build (plan)'"
CMD_AUDIT="command -v tfsec >/dev/null && tfsec . || echo 'tfsec not installed: https://aquasecurity.github.io/tfsec'"

stack_generate() {
  $DRY_RUN && { skip "would create the terraform layout"; return 0; }
  return 0   # no official generator — layer 2 is the deliverable here
}

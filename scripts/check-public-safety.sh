#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
cd "$repository_root"

blocked_files="$(git ls-files | grep -E '\.(pem|key|cert|p12|pfx|tfstate)$' || true)"

if [[ -n "$blocked_files" ]]; then
  echo "Blocked sensitive file types found:"
  echo "$blocked_files"
  exit 1
fi

allowed_tfvars='^environments/(lab|organization|kubernetes)/terraform\.tfvars$'
unexpected_tfvars="$(git ls-files '*.tfvars' | grep -Ev "$allowed_tfvars" || true)"

if [[ -n "$unexpected_tfvars" ]]; then
  echo "Unexpected tfvars files found:"
  echo "$unexpected_tfvars"
  exit 1
fi

blocked_pattern='BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|AKIA[0-9A-Z]{16}|[0-9]{12}|https?://[^[:space:]]+:[^[:space:]]+@|[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}'

if git grep -nEi "$blocked_pattern" -- ':!LICENSE' ':!scripts/check-public-safety.sh' ':!*.terraform.lock.hcl'; then
  echo "Potential credential, internal identifier, or organization-specific reference found."
  exit 1
fi

if find . -mindepth 2 -type d -name .git -print -quit | grep -q .; then
  echo "Nested Git repository found."
  exit 1
fi

echo "Public-safety checks passed."

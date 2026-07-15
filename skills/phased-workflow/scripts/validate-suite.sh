#!/bin/bash
set -euo pipefail

root=${1:?usage: validate-suite.sh <skills-root> [expected-version]}
expected=${2:-}
skills="phased-workflow phased-plan phased-review phased-implement phased-qa"

root=$(cd "$root" && pwd -P)
version=
validator_python=${SKILL_VALIDATOR_PYTHON:-}

if test -n "$validator_python"; then
  test -x "$validator_python" || {
    printf 'E_PYTHON_NOT_EXECUTABLE: %s\n' "$validator_python" >&2
    exit 1
  }
elif command -v python3 >/dev/null 2>&1; then
  validator_python=$(command -v python3)
elif test -x /opt/anaconda3/bin/python3; then
  validator_python=/opt/anaconda3/bin/python3
else
  echo 'E_PYTHON_NOT_FOUND: set SKILL_VALIDATOR_PYTHON' >&2
  exit 1
fi

if ! "$validator_python" -c 'import json' >/dev/null 2>&1; then
  printf 'E_PYTHON_JSON_UNAVAILABLE: %s\n' "$validator_python" >&2
  exit 1
fi

require_pattern() {
  file=$1
  pattern=$2
  id=$3
  if ! grep -Eq "$pattern" "$file"; then
    printf '%s: %s\n' "$id" "$file" >&2
    exit 1
  fi
}

for skill in $skills; do
  file="$root/$skill/SKILL.md"
  test -f "$file" || { printf 'E_MISSING_SKILL: %s\n' "$file" >&2; exit 1; }
  require_pattern "$file" "^name: $skill$" "E_FRONTMATTER_NAME"
  current=$(sed -n 's/^\*\*Suite contract:\*\* //p' "$file")
  test -n "$current" || { printf 'E_SUITE_VERSION: %s\n' "$file" >&2; exit 1; }
  if test -z "$version"; then version=$current; fi
  test "$current" = "$version" || { printf 'E_MIXED_VERSION: %s\n' "$file" >&2; exit 1; }
done

if test -n "$expected"; then
  test "$version" = "$expected" || { printf 'E_EXPECTED_VERSION: expected=%s actual=%s\n' "$expected" "$version" >&2; exit 1; }
fi

workflow="$root/phased-workflow/SKILL.md"
plan="$root/phased-plan/SKILL.md"
review="$root/phased-review/SKILL.md"
implement="$root/phased-implement/SKILL.md"
qa="$root/phased-qa/SKILL.md"

require_pattern "$workflow" 'Quality invariant:.*OPEN.*REMEDIATED.*CLOSED' 'POLICY_LIFECYCLE'
require_pattern "$workflow" 'Normal-risk plan.*two seats' 'POLICY_REVIEW_SEATS'
require_pattern "$workflow" 'two independent targeted closure lenses' 'POLICY_CLOSURE_LENSES'
require_pattern "$workflow" 'Standard QA retains a fresh exhaustive whole-diff scan' 'POLICY_FRESH_QA'
require_pattern "$workflow" 'implementation-standard.*lowest expected-total-cost currently qualified coding model' 'POLICY_STANDARD_MODEL_TIER'
require_pattern "$workflow" 'Never encode them in this skill' 'POLICY_RUNTIME_MODEL_RESOLUTION'
require_pattern "$plan" 'Decision and evidence manifest' 'PLAN_MANIFEST'
require_pattern "$review" 'planner evidence is a claim, not a trust boundary' 'REVIEW_MANIFEST_VALIDATION'
require_pattern "$review" 'two independent targeted closure lenses' 'REVIEW_CLOSURE_LENSES'
require_pattern "$implement" 'Cross-stage receipts never substitute for fresh QA release evidence' 'IMPLEMENT_NO_QA_SUBSTITUTION'
require_pattern "$implement" 'CAPABILITY_ESCALATION' 'IMPLEMENT_CAPABILITY_ESCALATION'
require_pattern "$qa" 'Standard QA remains fresh and exhaustive' 'QA_FRESH_RELEASE_GATE'
require_pattern "$qa" 'two independent targeted closure lenses' 'QA_CLOSURE_LENSES'

test -f "$root/phased-workflow/references/execution-controls.md" || { echo 'E_MISSING_EXECUTION_CONTROLS' >&2; exit 1; }
controls="$root/phased-workflow/references/execution-controls.md"
require_pattern "$controls" 'Never encode concrete implementation provider or model names' 'POLICY_PROVIDER_AGNOSTIC_ROUTING'
require_pattern "$controls" "Do not choose a provider's weakest, entry, or general lightweight model merely because its unit price is lowest" 'POLICY_CAPABILITY_FLOOR'
require_pattern "$controls" 'Model tier never changes plan fidelity, DoD, test depth, remediation, closure, or fresh independent QA' 'POLICY_MODEL_QUALITY_INVARIANT'
test -f "$root/phased-workflow/references/external-reviewers.md" || { echo 'E_MISSING_EXTERNAL_REVIEWERS' >&2; exit 1; }
schema="$root/phased-workflow/references/findings.schema.json"
test -f "$schema" || { echo 'E_MISSING_FINDINGS_SCHEMA' >&2; exit 1; }

"$validator_python" -m json.tool "$schema" >/dev/null
if grep -q '"nit"' "$schema"; then
  echo 'E_NIT_SEVERITY' >&2
  exit 1
fi
require_pattern "$schema" '"lifecycle"' 'E_SCHEMA_LIFECYCLE'
require_pattern "$schema" '"closure_evidence"' 'E_SCHEMA_CLOSURE'

for script in "$root"/phased-workflow/scripts/*.sh; do
  /bin/bash -n "$script"
done

printf 'phased suite valid: %s\n' "$version"

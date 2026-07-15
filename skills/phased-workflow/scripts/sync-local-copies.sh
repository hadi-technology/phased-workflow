#!/usr/bin/env bash
set -euo pipefail

source_root="${PHASED_SKILL_SOURCE:-${CODEX_HOME:-$HOME/.codex}/skills}"
target_root="${PHASED_SKILL_TARGET:-$HOME/.claude/skills}"
validator="${SKILL_VALIDATOR:-${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-creator/scripts/quick_validate.py}"
validator_python="${SKILL_VALIDATOR_PYTHON:-}"
skills=(phased-workflow phased-plan phased-review phased-implement phased-qa)

mkdir -p "$target_root"
source_root="$(cd "$source_root" && pwd -P)"
target_root="$(cd "$target_root" && pwd -P)"

case "$source_root/" in "$target_root/"*) echo "source cannot be inside target" >&2; exit 2;; esac
case "$target_root/" in "$source_root/"*) echo "target cannot be inside source" >&2; exit 2;; esac
[[ "$source_root" != "$target_root" ]] || { echo "source and target roots must differ" >&2; exit 2; }

suite_validator="$source_root/phased-workflow/scripts/validate-suite.sh"
[[ -x "$suite_validator" ]] || { echo "missing executable $suite_validator" >&2; exit 3; }
"$suite_validator" "$source_root"

for skill in "${skills[@]}"; do
  source_dir="$source_root/$skill"
  target_dir="$target_root/$skill"
  [[ -f "$source_dir/SKILL.md" ]] || { echo "missing $source_dir/SKILL.md" >&2; exit 3; }
  mkdir -p "$target_dir"
  rsync -a --delete "$source_dir/" "$target_dir/"
done

if [[ -f "$validator" && -z "$validator_python" ]]; then
  candidates=("$(command -v python3 2>/dev/null || true)" /opt/anaconda3/bin/python3 /usr/bin/python3)
  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]] && "$candidate" -c 'import yaml' >/dev/null 2>&1; then
      validator_python="$candidate"
      break
    fi
  done
fi

if [[ -f "$validator" && -z "$validator_python" ]]; then
  echo "validator found but no Python runtime with PyYAML is available" >&2
  exit 4
fi

if [[ -f "$validator" ]]; then
  for root in "$source_root" "$target_root"; do
    for skill in "${skills[@]}"; do
      "$validator_python" "$validator" "$root/$skill"
    done
  done
fi

for skill in "${skills[@]}"; do
  diff -qr "$source_root/$skill" "$target_root/$skill"
done

echo "phased skill copies synchronized and byte-identical"

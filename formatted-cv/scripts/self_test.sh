#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'This self-test is for macOS. Use self_test.ps1 on Windows.\n' >&2
  exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
skill_root="$(cd -- "$script_dir/.." && pwd -P)"
reference="$skill_root/assets/reference.docx"
for required in "$script_dir/ensure_libreoffice.sh" "$script_dir/export_pdf.sh" "$reference"; do
  [[ -f "$required" ]] || { printf 'Missing required implementation: %s\n' "$required" >&2; exit 1; }
done

temp_root="$(mktemp -d "${TMPDIR:-/tmp}/formatted-cv-test.XXXXXX")"
trap 'rm -rf -- "$temp_root"' EXIT
output="$temp_root/reference.pdf"

if bash "$script_dir/export_pdf.sh" "$skill_root/assets/missing.docx" "$output" --force >/dev/null 2>&1; then
  printf 'PDF export must reject a missing DOCX input.\n' >&2
  exit 1
fi
result="$(bash "$script_dir/export_pdf.sh" "$reference" "$output" --force)"
if [[ ! -s "$output" || "$(LC_ALL=C head -c 5 "$output")" != "%PDF-" ]]; then
  printf 'PDF export did not create a valid non-empty file.\n' >&2
  exit 1
fi

engine="$(printf '%s' "$result" | sed -n 's/.*"engine":"\([^"]*\)".*/\1/p')"
[[ -n "$engine" ]] || { printf 'PDF export did not report its engine.\n' >&2; exit 1; }
printf '{"export_engine":"%s","status":"pass"}\n' "$engine"

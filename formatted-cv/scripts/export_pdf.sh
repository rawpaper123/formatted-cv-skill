#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 || (${3:-} != "" && ${3:-} != "--force") ]]; then
  printf 'Usage: bash export_pdf.sh INPUT.docx OUTPUT.pdf [--force]\n' >&2
  exit 2
fi

input_arg=$1
output_arg=$2
force=${3:-}
if [[ ! -f "$input_arg" ]]; then
  printf 'Input DOCX does not exist: %s\n' "$input_arg" >&2
  exit 1
fi
if [[ "${input_arg##*.}" != "docx" ]]; then
  printf 'Input must be a .docx file.\n' >&2
  exit 1
fi
if [[ "${output_arg##*.}" != "pdf" ]]; then
  printf 'Output must end in .pdf.\n' >&2
  exit 1
fi

input_dir="$(cd -- "$(dirname -- "$input_arg")" && pwd -P)"
input="$input_dir/$(basename -- "$input_arg")"
mkdir -p -- "$(dirname -- "$output_arg")"
output_dir="$(cd -- "$(dirname -- "$output_arg")" && pwd -P)"
output="$output_dir/$(basename -- "$output_arg")"
if [[ -e "$output" && "$force" != "--force" ]]; then
  printf 'Output already exists: %s\n' "$output" >&2
  exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
temp_root="$(mktemp -d "${TMPDIR:-/tmp}/formatted-cv-export.XXXXXX")"
trap 'rm -rf -- "$temp_root"' EXIT
engine=""
libreoffice_version=null

# Pages is the native scripted fallback after Codex has tried Microsoft Word.
if [[ -d "/Applications/Pages.app" ]] && command -v osascript >/dev/null 2>&1; then
  rm -f -- "$output"
  if osascript - "$input" "$output" >"$temp_root/pages.log" 2>&1 <<'APPLESCRIPT'
on run argv
  set inputPath to item 1 of argv
  set outputPath to item 2 of argv
  tell application "Pages"
    set documentRef to open POSIX file inputPath
    export documentRef to POSIX file outputPath as PDF
    close documentRef saving no
  end tell
end run
APPLESCRIPT
  then
    if [[ -s "$output" && "$(LC_ALL=C head -c 5 "$output")" == "%PDF-" ]]; then
      engine="Apple Pages"
    fi
  fi
fi

if [[ -z "$engine" ]]; then
  rm -f -- "$output"
  soffice="$(bash "$script_dir/ensure_libreoffice.sh" --path-only)"
  profile_dir="$temp_root/profile"
  convert_dir="$temp_root/output"
  mkdir -p -- "$profile_dir" "$convert_dir"
  profile_uri="file://$profile_dir"
  if ! "$soffice" "-env:UserInstallation=$profile_uri" --headless --norestore --convert-to pdf --outdir "$convert_dir" "$input" >"$temp_root/libreoffice.log" 2>&1; then
    cat "$temp_root/libreoffice.log" >&2
    exit 1
  fi
  input_name="$(basename -- "$input")"
  produced="$convert_dir/${input_name%.*}.pdf"
  if [[ ! -s "$produced" ]]; then
    cat "$temp_root/libreoffice.log" >&2
    printf 'LibreOffice did not produce a usable PDF.\n' >&2
    exit 1
  fi
  mv -f -- "$produced" "$output"
  engine="LibreOffice"
  version="$($soffice --version 2>&1 | head -n 1)"
  libreoffice_version="\"$version\""
fi

if [[ "$(LC_ALL=C head -c 5 "$output")" != "%PDF-" ]]; then
  printf '%s output is not a valid PDF.\n' "$engine" >&2
  exit 1
fi

page_count=null
if command -v mdls >/dev/null 2>&1; then
  detected="$(mdls -raw -name kMDItemNumberOfPages "$output" 2>/dev/null || true)"
  if [[ "$detected" =~ ^[0-9]+$ ]]; then page_count=$detected; fi
fi
printf '{"output":"%s","engine":"%s","page_count":%s,"libreoffice_version":%s}\n' "$output" "$engine" "$page_count" "$libreoffice_version"

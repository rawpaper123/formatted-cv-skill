#!/usr/bin/env bash
set -euo pipefail

check_only=false
path_only=false
for arg in "$@"; do
  case "$arg" in
    --check-only) check_only=true ;;
    --path-only) path_only=true ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'This installer is for macOS. Use ensure_libreoffice.ps1 on Windows.\n' >&2
  exit 1
fi

find_soffice() {
  local candidate
  for candidate in \
    "/Applications/LibreOffice.app/Contents/MacOS/soffice" \
    "$HOME/Applications/LibreOffice.app/Contents/MacOS/soffice" \
    "$(command -v soffice 2>/dev/null || true)" \
    "$(command -v libreoffice 2>/dev/null || true)"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

soffice="$(find_soffice || true)"
installed_now=false
if [[ -z "$soffice" ]]; then
  if $check_only; then
    printf 'LibreOffice is required but is not installed.\n' >&2
    exit 1
  fi
  if ! command -v brew >/dev/null 2>&1; then
    printf 'LibreOffice is required and Homebrew is unavailable. Install Homebrew or LibreOffice, then run this check again.\n' >&2
    exit 1
  fi
  brew install --cask libreoffice
  soffice="$(find_soffice || true)"
  if [[ -z "$soffice" ]]; then
    printf 'LibreOffice installation completed but soffice was not found.\n' >&2
    exit 1
  fi
  installed_now=true
fi

version="$($soffice --version 2>&1 | head -n 1)"
if [[ -z "$version" ]]; then
  printf 'LibreOffice exists but failed its version check: %s\n' "$soffice" >&2
  exit 1
fi

if $path_only; then
  printf '%s\n' "$soffice"
else
  printf '{"path":"%s","version":"%s","installed_now":%s}\n' "$soffice" "$version" "$installed_now"
fi

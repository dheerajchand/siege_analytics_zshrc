#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${HOME}/.config/zsh"
SECRETS_MAP="${ROOT_DIR}/secrets.1p"
CODEX_SESSIONS_FILE="${ROOT_DIR}/codex-sessions.env"
ACCOUNT_UUID=""
VAULT_NAME="Private"
ITEM_TITLE="gitlab personal access token"

if [[ ! -f "${ROOT_DIR}/modules/secrets.zsh" ]]; then
  echo "Missing ${ROOT_DIR}/modules/secrets.zsh" >&2
  exit 1
fi

source "${ROOT_DIR}/modules/secrets.zsh"

echo "🔐 Selecting account for '${ITEM_TITLE}' in ${VAULT_NAME}..."
ACCOUNT_UUID="${OP_FIX_ACCOUNT_UUID:-}"
if [[ -z "$ACCOUNT_UUID" ]]; then
  ACCOUNTS_JSON="$(op account list --format=json 2>/dev/null || true)"
  if [[ -z "$ACCOUNTS_JSON" ]]; then
    echo "No 1Password accounts available. Run: eval \"\$(op signin)\"" >&2
    exit 1
  fi
  python - <<'PY' "$ACCOUNTS_JSON"
import json,sys
data=json.loads(sys.argv[1])
aliases={
    "NRPF34RS6VH2THRPJDBTZWQOKU":"Dheeraj_Chand_Family",
    "I3C75JBKZJGSLMVQDGRKCVNHIM":"Masai_Family",
    "NAGE4CCNQVBWPJEI5CLZ7NCVFM":"ElectInfo",
    "TLTQ3ANAABGCNEK7KIAOTDNK2Q":"Siege_Analytics",
}
for idx,a in enumerate(data,1):
    uuid=a.get("account_uuid","")
    name=aliases.get(uuid) or (a.get("shorthand") or "unknown")
    print(f"{idx}) {uuid}  {name}  {a.get('email','')}  {a.get('url','')}")
PY
  printf "Select account number for '%s' in %s [1]: " "$ITEM_TITLE" "$VAULT_NAME"
  read -r choice
  [[ -z "$choice" ]] && choice="1"
  ACCOUNT_UUID="$(python - <<'PY' "$ACCOUNTS_JSON" "$choice"
import json,sys
data=json.loads(sys.argv[1])
idx=int(sys.argv[2])-1
if idx<0 or idx>=len(data):
    raise SystemExit(1)
print(data[idx].get("account_uuid",""))
PY
)"
fi

if [[ -z "$ACCOUNT_UUID" ]]; then
  echo "No account selected." >&2
  exit 1
fi

echo "🔎 Verifying item exists in account ${ACCOUNT_UUID}..."
if ! op item get "${ITEM_TITLE}" --account "${ACCOUNT_UUID}" --vault "${VAULT_NAME}" >/dev/null 2>&1; then
  echo "Missing item '${ITEM_TITLE}' in ${VAULT_NAME} for account ${ACCOUNT_UUID}." >&2
  exit 1
fi

if [[ -z "$ACCOUNT_UUID" ]]; then
  echo "Could not find '${ITEM_TITLE}' in any account vault '${VAULT_NAME}'." >&2
  exit 1
fi

echo "🔐 Ensuring source of truth is account ${ACCOUNT_UUID} / ${VAULT_NAME}"
secrets_source_set "${ACCOUNT_UUID}" "${VAULT_NAME}"
op_set_default "${ACCOUNT_UUID}" "${VAULT_NAME}"

if ! command -v op >/dev/null 2>&1; then
  echo "op CLI not found" >&2
  exit 1
fi

if ! op account list >/dev/null 2>&1; then
  echo "Signing in to 1Password account ${ACCOUNT_UUID}..."
  eval "$(op signin --account "${ACCOUNT_UUID}")"
fi

echo "🔎 Verified GitLab token item exists."

if [[ ! -f "${SECRETS_MAP}" ]]; then
  echo "Missing ${SECRETS_MAP}" >&2
  exit 1
fi

echo "✍️  Updating secrets map for GITLAB_TOKEN..."
python - <<'PY'
from pathlib import Path
import os

root = Path.home() / ".config/zsh"
path = root / "secrets.1p"
target = "GITLAB_TOKEN=op://Private/gitlab personal access token/password"
lines = path.read_text().splitlines()
out = []
found = False
for line in lines:
    if line.startswith("GITLAB_TOKEN="):
        out.append(target)
        found = True
    else:
        out.append(line)
if not found:
    out.append(target)
path.write_text("\n".join(out) + "\n")
PY

secrets_map_sanitize --fix >/dev/null 2>&1 || true

echo "🔁 Syncing secrets files to 1Password..."
secrets_sync_all_to_1p

echo "✅ Verifying op read and env load..."
op read "op://${VAULT_NAME}/${ITEM_TITLE}/password" --account "${ACCOUNT_UUID}" >/dev/null
secrets_load_op

if [[ -z "${GITLAB_TOKEN:-}" ]]; then
  echo "GITLAB_TOKEN still empty after load" >&2
  exit 1
fi

echo "✅ GITLAB_TOKEN loaded successfully."

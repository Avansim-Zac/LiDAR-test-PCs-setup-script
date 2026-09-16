#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${SUDO_USER:-}" ]]; then
  echo "This script must be run with sudo." >&2
  exit 1
fi

echo "========================================================"
echo " Starting Lidar-v53 Get"
echo " Target Package: Lidar-v53[Latest Version].zip"
echo "========================================================"

USER_HOME=$(eval echo ~${SUDO_USER})
DEST_DIR="${USER_HOME}/Documents"

OWNER="USER"
REPO="REPO"
PATH_IN_REPO="path/to/folder"
BRANCH="main"

# 1. List files in the repo folder via GitHub API
API_URL="https://api.github.com/repos/${OWNER}/${REPO}/contents/${PATH_IN_REPO}?ref=${BRANCH}"
FILES_JSON=$(curl -sL "$API_URL")

# 2. Filter for names matching Lidar-v53[NN.NN.NN].zip, pick the highest version
LATEST_FILE=$(echo "$FILES_JSON" \
  | grep -o '"name": *"[^"]*"' \
  | sed 's/"name": *"\(.*\)"/\1/' \
  | grep -E '^Lidar-v53\[[0-9]{2}\.[0-9]{2}\.[0-9]{2}\]\.zip$' \
  | sort -t'[' -k2 -V \
  | tail -n 1)

if [[ -z "$LATEST_FILE" ]]; then
  echo "No matching files found." >&2
  exit 1
fi

echo "Latest version found: $LATEST_FILE"

# 3. Download it to /tmp (not Documents — keeps ownership clean until extraction)
DOWNLOAD_URL="https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}/${PATH_IN_REPO}/${LATEST_FILE}"
ZIP_PATH="/tmp/${LATEST_FILE}"
curl -L -o "$ZIP_PATH" "$DOWNLOAD_URL"

# 4. Figure out the top-level folder name inside the zip BEFORE extracting
TOP_LEVEL_NAME=$(unzip -Z1 "$ZIP_PATH" | head -1 | cut -d/ -f1)
EXTRACTED_DIR="${DEST_DIR}/${TOP_LEVEL_NAME}"

# 5. Extract into ~/Documents, owned by the real user (not root)
mkdir -p "$DEST_DIR"
sudo -u "$SUDO_USER" unzip -q "$ZIP_PATH" -d "$DEST_DIR"
rm -f "$ZIP_PATH"

# 6. Make main file executable and run with sudo
cd ${EXTRACTED_DIR}
sudo chmod +x Lidar2026
sudo ./Lidar2026

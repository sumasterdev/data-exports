#!/bin/bash

# === CONFIG ===
EXPORT_DIR="/var/www/html/data-exports/exports"
TELEGRAM_BOT_TOKEN="7971261172:AAEywYpFXz86ex7GcXH50ruNfT3JPvadOxg"
TELEGRAM_CHAT_ID="5291546247"

# === FUNCTIONS ===

send_telegram_message() {
  local MESSAGE="$1"
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=${MESSAGE}" > /dev/null
}

upload_zip_file() {
  local ZIP_FILE="$1"
  local BASENAME=$(basename "$ZIP_FILE")
  local JSON_FILE="${ZIP_FILE%.zip}.json"

  # Call upload.js and get the result
  DRIVE_LINK=$(node "$(dirname "$0")/upload.js" "$ZIP_FILE")

  if [[ "$DRIVE_LINK" == https* ]]; then
    send_telegram_message "✅ Uploaded: $BASENAME\n🔗 Link: $DRIVE_LINK"

    # Clean up after success
    rm -f "$ZIP_FILE" "$JSON_FILE"
    echo "🧹 Deleted $ZIP_FILE and $JSON_FILE"
  else
    send_telegram_message "❌ Upload failed for: $BASENAME"
  fi
}

# === MAIN ===

echo "📦 Searching for ZIP files in $EXPORT_DIR..."

ZIP_FILES=$(find "$EXPORT_DIR" -maxdepth 1 -type f -name "*.zip")

if [[ -z "$ZIP_FILES" ]]; then
  echo "No ZIP files found."
  exit 0
fi

for ZIP_FILE in $ZIP_FILES; do
  echo "Uploading $ZIP_FILE..."
  upload_zip_file "$ZIP_FILE"
done

echo "🚀 Upload process completed."

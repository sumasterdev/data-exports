#!/bin/bash

# === CONFIG ===
EXPORT_DIR="/var/www/html/data-exports/exports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DB_NAME="CRMdb"
COLLECTION_NAME="betaoddshistories"
LEAGUE_IDS=("5591" "1773" "2048" "5598" "1818")
MARKETS=("moneyline:maxMoneyline" "spreads:maxSpread")

TELEGRAM_BOT_TOKEN="7971261172:AAEywYpFXz86ex7GcXH50ruNfT3JPvadOxg"
TELEGRAM_CHAT_ID="5291546247"

# === FUNCTIONS ===

send_telegram_message() {
  MESSAGE="$1"
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" -d "text=${MESSAGE}" > /dev/null
}

run_export() {
  LEAGUE_ID="$1"
  MARKET_NAME="$2"
  FIELD="$3"
  OUTFILE="$4"

  mongoexport \
    --db="$DB_NAME" \
    --collection="$COLLECTION_NAME" \
    --query="{
      \"league_id\": \"$LEAGUE_ID\",
      \"periods\": { \"\$elemMatch\": { \"p_number\": \"0\", \"$FIELD\": { \"\$exists\": true } } }
    }" \
    --out="$OUTFILE"

  if [ $? -eq 0 ]; then
    ZIP_FILE="${OUTFILE%.json}.zip"
    zip -j "$ZIP_FILE" "$OUTFILE" > /dev/null

    if [ $? -eq 0 ]; then
      send_telegram_message "✅ League ID: $LEAGUE_ID $MARKET_NAME market is extracted and zipped."

      # Upload to Google Drive
      DRIVE_LINK=$(node "$(dirname "$0")/upload.js" "$ZIP_FILE")
      if [[ "$DRIVE_LINK" == https* ]]; then
        send_telegram_message "📂 Uploaded to Drive: $DRIVE_LINK"

        # ✅ Cleanup after success
        rm -f "$OUTFILE" "$ZIP_FILE"
        echo "🧹 Deleted $OUTFILE and $ZIP_FILE"
      else
        send_telegram_message "⚠️ Upload to Google Drive failed for League $LEAGUE_ID $MARKET_NAME"
      fi
    else
      send_telegram_message "⚠️ League ID: $LEAGUE_ID $MARKET_NAME export succeeded but zip failed."
    fi
  else
    send_telegram_message "❌ League ID: $LEAGUE_ID $MARKET_NAME export failed."
  fi
}

# === MAIN EXECUTION ===

mkdir -p "$EXPORT_DIR"

TOTAL_LEAGUES=${#LEAGUE_IDS[@]}
REMAINING=$TOTAL_LEAGUES

echo "Starting export at $TIMESTAMP..."
send_telegram_message "🚀 Starting exports at $TIMESTAMP..."

for LEAGUE_ID in "${LEAGUE_IDS[@]}"; do
  for MARKET_PAIR in "${MARKETS[@]}"; do
    MARKET_NAME="${MARKET_PAIR%%:*}"
    FIELD_NAME="${MARKET_PAIR##*:}"
    OUTFILE="$EXPORT_DIR/${LEAGUE_ID}_${MARKET_NAME}_$TIMESTAMP.json"

    run_export "$LEAGUE_ID" "$MARKET_NAME" "$FIELD_NAME" "$OUTFILE"
  done

  ((REMAINING--))
  send_telegram_message "✅ League ID: $LEAGUE_ID is done. $REMAINING leagues remaining."
done

send_telegram_message "🎉 All export tasks completed at $TIMESTAMP."
echo "All export tasks completed."
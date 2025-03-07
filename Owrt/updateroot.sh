#!/bin/bash

# Script to automatically update OpenClash configuration files
# Enhanced with better error handling, logging, notifications, and advanced features

# ============================================================================
# CONFIGURATION SECTION - Customize these settings as needed
# ============================================================================

# Define file paths
REMOTE_URL="https://raw.githubusercontent.com/adiorany3/akoen/refs/heads/main/newdualvless.yaml"
LOCAL_FILE="/etc/openclash/config/newdualvless.yaml"
TEMP_FILE="/tmp/newdualvless.yaml.tmp"
BACKUP_FILE="${LOCAL_FILE}.backup"
LOCK_FILE="/tmp/updateroot.lock"
LOG_FILE="/var/log/openclash_update.log"

# Script behavior settings
MAX_RETRIES=3                # Number of download attempts
DOWNLOAD_TIMEOUT=30          # Timeout for each download attempt (seconds)
WAIT_BEFORE_UPDATE=5         # Wait time before applying updates (seconds)
CONNECTIVITY_TEST_HOST="github.com"  # Host to ping for connectivity test
BACKUP_RETENTION=5           # Number of backup versions to keep
LOG_MAX_SIZE=1024            # Max log size in KB before rotation
LOCK_TIMEOUT=60              # Minutes before considering lock file as stale

# Notification settings (set to true to enable)
ENABLE_NOTIFICATIONS=true    # Set to false if you don't want notifications
TELEGRAM_BOT_TOKEN=""        # Your Telegram bot token
TELEGRAM_CHAT_ID=""          # Your Telegram chat ID

# ============================================================================
# FUNCTION DEFINITIONS
# ============================================================================

# Function to log messages
log_message() {
  local level="INFO"
  if [ "$#" -eq 2 ]; then
    level="$1"
    shift
  fi
  echo "[$level $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
  
  # Send notification for errors or updates
  if $ENABLE_NOTIFICATIONS && [[ "$level" == "ERROR" || "$level" == "UPDATE" ]]; then
    send_notification "[$level] $1"
  fi
}

# Function to rotate logs if they get too big
rotate_logs() {
  if [ -f "$LOG_FILE" ] && [ $(du -k "$LOG_FILE" | cut -f1) -gt $LOG_MAX_SIZE ]; then
    mv "$LOG_FILE" "${LOG_FILE}.old"
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    log_message "Log file rotated due to size"
  fi
}

# Function to send telegram notifications
send_notification() {
  if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    local message="OpenClash Update: $1"
    
    # Use curl with proper error handling
    local response=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d "chat_id=${TELEGRAM_CHAT_ID}" \
      -d "text=${message}" \
      -d "parse_mode=HTML" 2>&1)
    
    # Check if request was successful
    if echo "$response" | grep -q '"ok":true'; then
      log_message "DEBUG" "Telegram notification sent successfully"
    else
      log_message "WARNING" "Failed to send Telegram notification: $response"
    fi
  else
    [ "$ENABLE_NOTIFICATIONS" = true ] && log_message "WARNING" "Telegram notifications enabled but missing bot token or chat ID"
  fi
}

# Cleanup function
cleanup() {
  rm -f "$LOCK_FILE"
  rm -f "$TEMP_FILE"
  log_message "Script execution completed."
}

# Function to verify file integrity
verify_file() {
  local file="$1"
  # Check if file exists and is not empty
  if [ ! -s "$file" ]; then
    log_message "ERROR" "File is empty or does not exist: $file"
    return 1
  fi
  
  # Basic YAML validation check
  if ! grep -q "^[[:space:]]*[a-zA-Z0-9_]\+:[[:space:]]" "$file"; then
    log_message "ERROR" "File does not appear to be valid YAML: $file"
    return 1
  fi
  
  # Check for required YAML sections in OpenClash config
  if ! grep -q "^proxies:" "$file" && ! grep -q "^proxy-groups:" "$file"; then
    log_message "ERROR" "Missing required sections in YAML file: $file"
    return 1
  fi
  
  return 0
}

# Function to manage backups
manage_backups() {
  local base_dir=$(dirname "$BACKUP_FILE")
  local base_name=$(basename "$BACKUP_FILE")
  local timestamp=$(date +%Y%m%d%H%M%S)
  local versioned_backup="${base_dir}/${base_name}.${timestamp}"
  
  # Create directory if it doesn't exist
  [ -d "$base_dir" ] || mkdir -p "$base_dir"
  
  # Create timestamped backup
  cp "$LOCAL_FILE" "$versioned_backup"
  chmod 644 "$versioned_backup"
  
  # Keep track of the most recent backup for quick recovery
  cp "$LOCAL_FILE" "$BACKUP_FILE"
  
  # Remove old backups (keep only BACKUP_RETENTION most recent)
  ls -t "${base_dir}/${base_name}."* 2>/dev/null | tail -n +$((BACKUP_RETENTION+1)) | xargs rm -f 2>/dev/null
  
  log_message "Backup created at $versioned_backup (keeping last $BACKUP_RETENTION versions)"
}

# Function to check connectivity
check_connectivity() {
  # First check with ping
  if ping -c 1 -W 3 $CONNECTIVITY_TEST_HOST >/dev/null 2>&1; then
    return 0
  fi
  
  # If ping fails, try DNS lookup as fallback
  if nslookup $CONNECTIVITY_TEST_HOST >/dev/null 2>&1; then
    return 0
  fi
  
  # If both fail, try curl as last resort
  if curl -s --head --connect-timeout 3 "https://$CONNECTIVITY_TEST_HOST" >/dev/null 2>&1; then
    return 0
  fi
  
  return 1
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

# Rotate logs if needed
rotate_logs

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
  log_message "WARNING" "This script should ideally be run as root"
fi

# Check if script is already running
if [ -f "$LOCK_FILE" ]; then
  # Check if the lock file is stale
  if [ "$(find "$LOCK_FILE" -mmin +$LOCK_TIMEOUT)" ]; then
    log_message "WARNING" "Found stale lock file, removing..."
    rm -f "$LOCK_FILE"
  else
    log_message "WARNING" "UPDATE BLOCKED: Another update process is already running. Exiting."
    exit 1
  fi
fi

# Create lock file with timestamp
echo "Started: $(date)" > "$LOCK_FILE"

# Set trap for cleanup
trap cleanup EXIT INT TERM

# Ensure required directories exist
if [ ! -d "$(dirname "$LOCAL_FILE")" ]; then
  mkdir -p "$(dirname "$LOCAL_FILE")"
  log_message "Created directory: $(dirname "$LOCAL_FILE")"
  chmod 755 "$(dirname "$LOCAL_FILE")"
fi

# Ensure log directory exists
if [ ! -d "$(dirname "$LOG_FILE")" ]; then
  mkdir -p "$(dirname "$LOG_FILE")"
  chmod 755 "$(dirname "$LOG_FILE")"
fi

# Check internet connectivity
log_message "Checking internet connectivity..."
if ! check_connectivity; then
  log_message "ERROR" "No internet connectivity detected. Exiting."
  exit 1
fi

# Download the remote file to check for updates
log_message "Checking for updates from $REMOTE_URL"
retry_count=0
download_success=false

while [ $retry_count -lt $MAX_RETRIES ] && [ "$download_success" = false ]; do
  if curl -s --fail --connect-timeout $DOWNLOAD_TIMEOUT --max-time $DOWNLOAD_TIMEOUT "$REMOTE_URL" -o "$TEMP_FILE"; then
    download_success=true
    log_message "Download successful on attempt $((retry_count+1))"
  else
    retry_count=$((retry_count+1))
    if [ $retry_count -lt $MAX_RETRIES ]; then
      log_message "Download failed, retry $retry_count/$MAX_RETRIES in 5 seconds..."
      sleep 5
    fi
  fi
done

if [ "$download_success" = false ]; then
  log_message "ERROR" "Failed to download the remote file after $MAX_RETRIES attempts. Skipping update check."
  exit 1
fi

# Validate downloaded file
if ! verify_file "$TEMP_FILE"; then
  log_message "ERROR" "Downloaded file doesn't appear to be valid. Skipping update."
  exit 1
fi

# Check if local file exists and if there's a difference between remote and local
if [ ! -f "$LOCAL_FILE" ] || ! cmp -s "$TEMP_FILE" "$LOCAL_FILE"; then
  log_message "UPDATE" "Updates found for newdualvless.yaml"
  
  # Create backup of current file if it exists
  if [ -f "$LOCAL_FILE" ]; then
    manage_backups
  else
    log_message "No existing configuration to back up. This is the first install."
  fi
  
  log_message "Waiting $WAIT_BEFORE_UPDATE seconds before updating..."
  sleep $WAIT_BEFORE_UPDATE
  
  log_message "Updating newdualvless.yaml..."
  if mv "$TEMP_FILE" "$LOCAL_FILE"; then
    log_message "Update completed successfully."
    
    # Set proper permissions
    chmod 644 "$LOCAL_FILE"
    
    # Verify the file was properly written
    if ! verify_file "$LOCAL_FILE"; then
      log_message "ERROR" "Updated file is invalid! Restoring from backup."
      [ -f "$BACKUP_FILE" ] && cp "$BACKUP_FILE" "$LOCAL_FILE"
      log_message "Restored from backup."
      exit 1
    fi
    
    # Restart OpenClash service if it's running
    if pgrep openclash >/dev/null; then
      log_message "Restarting OpenClash service..."
      if /etc/init.d/openclash restart; then
        log_message "OpenClash service restarted successfully."
      else
        log_message "WARNING" "Failed to restart OpenClash service."
      fi
    else
      log_message "OpenClash service is not running, no restart needed."
    fi
  else
    log_message "ERROR" "Failed to update configuration file."
    [ -f "$BACKUP_FILE" ] && cp "$BACKUP_FILE" "$LOCAL_FILE"
    log_message "Restored from backup."
    exit 1
  fi
else
  log_message "No updates found for newdualvless.yaml"
  rm -f "$TEMP_FILE"
fi

# Continue with the original script functionality
log_message "Running OpenClash update script..."
if [ -f "/etc/openclash/config/update.sh" ]; then
  cd /etc/openclash/config/ && bash /etc/openclash/config/update.sh
  if [ $? -eq 0 ]; then
    log_message "OpenClash update script executed successfully."
  else
    log_message "WARNING" "OpenClash update script returned an error."
  fi
else
  log_message "WARNING" "OpenClash update script not found at /etc/openclash/config/update.sh"
fi

log_message "Update process completed successfully."
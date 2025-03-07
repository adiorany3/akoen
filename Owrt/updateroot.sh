#!/bin/bash

# Script to automatically update OpenClash configuration files
# Enhanced with better error handling, logging, and advanced features

# Define file paths
REMOTE_URL="https://raw.githubusercontent.com/adiorany3/akoen/refs/heads/main/newdualvless.yaml"
LOCAL_FILE="/etc/openclash/config/newdualvless.yaml"
TEMP_FILE="/tmp/newdualvless.yaml.tmp"
BACKUP_FILE="${LOCAL_FILE}.backup"
LOCK_FILE="/tmp/updateroot.lock"
LOG_FILE="/var/log/openclash_update.log"
MAX_RETRIES=3
DOWNLOAD_TIMEOUT=30
WAIT_BEFORE_UPDATE=5

# Function to log messages
log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
  log_message "WARNING: This script should ideally be run as root"
fi

# Check if script is already running
if [ -f "$LOCK_FILE" ]; then
  # Check if the lock file is stale (more than 1 hour old)
  if [ "$(find "$LOCK_FILE" -mmin +60)" ]; then
    log_message "WARNING: Found stale lock file, removing..."
    rm -f "$LOCK_FILE"
  else
    log_message "UPDATE BLOCKED: Another update process is already running. Exiting."
    exit 1
  fi
fi

# Create lock file
touch "$LOCK_FILE"

# Cleanup function
cleanup() {
  rm -f "$LOCK_FILE"
  rm -f "$TEMP_FILE"
  log_message "Script execution completed."
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

# Check internet connectivity
log_message "Checking internet connectivity..."
if ! ping -c 1 -W 3 github.com >/dev/null 2>&1; then
  log_message "ERROR: No internet connectivity detected. Exiting."
  exit 1
fi

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
  log_message "ERROR: Failed to download the remote file after $MAX_RETRIES attempts. Skipping update check."
  exit 1
fi

# Validate downloaded file (basic check that it's a YAML file)
if ! grep -q "^[[:space:]]*[a-zA-Z0-9_]\+:[[:space:]]" "$TEMP_FILE"; then
  log_message "ERROR: Downloaded file doesn't appear to be a valid YAML file. Skipping update."
  exit 1
fi

# Check if local file exists and if there's a difference between remote and local
if [ ! -f "$LOCAL_FILE" ] || ! cmp -s "$TEMP_FILE" "$LOCAL_FILE"; then
  log_message "Updates found for newdualvless.yaml"
  
  # Create backup of current file if it exists
  if [ -f "$LOCAL_FILE" ]; then
    cp "$LOCAL_FILE" "$BACKUP_FILE"
    if [ $? -eq 0 ]; then
      log_message "Backup created at $BACKUP_FILE"
      chmod 644 "$BACKUP_FILE"
    else
      log_message "WARNING: Failed to create backup file"
    fi
  fi
  
  log_message "Waiting $WAIT_BEFORE_UPDATE seconds before updating..."
  sleep $WAIT_BEFORE_UPDATE
  
  log_message "Updating newdualvless.yaml..."
  if mv "$TEMP_FILE" "$LOCAL_FILE"; then
    log_message "Update completed successfully."
    
    # Set proper permissions
    chmod 644 "$LOCAL_FILE"
    
    # Verify the file was properly written
    if [ ! -s "$LOCAL_FILE" ]; then
      log_message "ERROR: Updated file is empty! Restoring from backup."
      [ -f "$BACKUP_FILE" ] && mv "$BACKUP_FILE" "$LOCAL_FILE"
      log_message "Restored from backup."
      exit 1
    fi
    
    # Restart OpenClash service if it's running
    if pgrep openclash >/dev/null; then
      log_message "Restarting OpenClash service..."
      if /etc/init.d/openclash restart; then
        log_message "OpenClash service restarted successfully."
      else
        log_message "WARNING: Failed to restart OpenClash service."
      fi
    else
      log_message "OpenClash service is not running, no restart needed."
    fi
  else
    log_message "ERROR: Failed to update configuration file."
    [ -f "$BACKUP_FILE" ] && mv "$BACKUP_FILE" "$LOCAL_FILE"
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
    log_message "WARNING: OpenClash update script returned an error."
  fi
else
  log_message "WARNING: OpenClash update script not found at /etc/openclash/config/update.sh"
fi

log_message "Update process completed successfully."
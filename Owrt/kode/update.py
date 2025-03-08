#!/usr/bin/env python3
# filepath: /Users/macbookpro/Documents/GitHub/akoen/Owrt/updateroot.py

import os
import sys
import time
import shutil
import subprocess
import logging
import requests
import yaml
import re
import signal
from datetime import datetime
from pathlib import Path

# ============================================================================
# CONFIGURATION SECTION - Customize these settings as needed
# ============================================================================

# Define file paths
REMOTE_URL = "https://raw.githubusercontent.com/adiorany3/akoen/refs/heads/main/newdualvless.yaml"
LOCAL_FILE = "/etc/openclash/config/newdualvless.yaml"
TEMP_FILE = "/tmp/newdualvless.yaml.tmp"
BACKUP_FILE = f"{LOCAL_FILE}.backup"
LOCK_FILE = "/tmp/updateroot.lock"
LOG_FILE = "/var/log/openclash_update.log"

# Script behavior settings
MAX_RETRIES = 3               # Number of download attempts
DOWNLOAD_TIMEOUT = 30         # Timeout for each download attempt (seconds)
WAIT_BEFORE_UPDATE = 5        # Wait time before applying updates (seconds)
CONNECTIVITY_TEST_HOST = "github.com"  # Host to ping for connectivity test
BACKUP_RETENTION = 5          # Number of backup versions to keep
LOG_MAX_SIZE = 1024           # Max log size in KB before rotation
LOCK_TIMEOUT = 60             # Minutes before considering lock file as stale

# Notification settings (set to true to enable)
ENABLE_NOTIFICATIONS = True   # Set to False if you don't want notifications
TELEGRAM_BOT_TOKEN = "6560425395:AAHnNDWkKzqTpKUeeiH-XsGO2hF2poI9Reo"       # Your Telegram bot token
TELEGRAM_CHAT_ID = "28075319"         # Your Telegram chat ID

# ============================================================================
# FUNCTION DEFINITIONS
# ============================================================================

def setup_logging():
    # Create logger
    logger = logging.getLogger("openclash_update")
    logger.setLevel(logging.INFO)
    
    # Create formatter
    formatter = logging.Formatter('[%(levelname)s %(asctime)s] %(message)s', 
                                 datefmt='%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    log_dir = os.path.dirname(LOG_FILE)
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
        os.chmod(log_dir, 0o755)
    
    # File handler
    file_handler = logging.FileHandler(LOG_FILE)
    file_handler.setFormatter(formatter)
    
    # Console handler
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    
    # Add handlers to logger
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    
    return logger

logger = setup_logging()

def log_message(message, level="INFO"):
    """Log messages to file and console"""
    if level == "INFO":
        logger.info(message)
    elif level == "WARNING":
        logger.warning(message)
    elif level == "ERROR":
        logger.error(message)
    elif level == "DEBUG":
        logger.debug(message)
    elif level == "UPDATE":
        logger.info(f"UPDATE: {message}")
    
    # Send notification for errors or updates
    if ENABLE_NOTIFICATIONS and (level == "ERROR" or level == "UPDATE"):
        send_notification(f"[{level}] {message}")

def rotate_logs():
    """Rotate logs if they get too big"""
    if os.path.exists(LOG_FILE):
        size_kb = os.path.getsize(LOG_FILE) / 1024
        if size_kb > LOG_MAX_SIZE:
            if os.path.exists(f"{LOG_FILE}.old"):
                os.remove(f"{LOG_FILE}.old")
            os.rename(LOG_FILE, f"{LOG_FILE}.old")
            open(LOG_FILE, 'w').close()
            os.chmod(LOG_FILE, 0o644)
            log_message("Log file rotated due to size")

def send_notification(message):
    """Send telegram notifications"""
    if TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID:
        message = f"OpenClash Update: {message}"
        url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
        data = {
            "chat_id": TELEGRAM_CHAT_ID,
            "text": message,
            "parse_mode": "HTML"
        }
        
        try:
            response = requests.post(url, data=data, timeout=10)
            if response.status_code == 200 and response.json().get('ok'):
                log_message("Telegram notification sent successfully", "DEBUG")
            else:
                log_message(f"Failed to send Telegram notification: {response.text}", "WARNING")
        except Exception as e:
            log_message(f"Error sending Telegram notification: {str(e)}", "WARNING")
    elif ENABLE_NOTIFICATIONS:
        log_message("Telegram notifications enabled but missing bot token or chat ID", "WARNING")

def cleanup():
    """Cleanup function to remove temporary files"""
    if os.path.exists(LOCK_FILE):
        os.remove(LOCK_FILE)
    if os.path.exists(TEMP_FILE):
        os.remove(TEMP_FILE)
    log_message("Script execution completed.")

def verify_file(file_path):
    """Verify file integrity"""
    # Check if file exists and is not empty
    if not os.path.isfile(file_path) or os.path.getsize(file_path) == 0:
        log_message(f"File is empty or does not exist: {file_path}", "ERROR")
        return False
    
    try:
        # Try to load as YAML to verify structure
        with open(file_path, 'r') as file:
            content = file.read()
            
            # Basic YAML validation - check for key-value pairs
            if not re.search(r'^[ \t]*[\w\d_]+:[ \t]', content, re.MULTILINE):
                log_message(f"File does not appear to be valid YAML: {file_path}", "ERROR")
                return False
            
            # Check for required sections
            if not ("proxies:" in content and "proxy-groups:" in content):
                log_message(f"Missing required sections in YAML file: {file_path}", "ERROR")
                return False
            
            # Try to parse YAML - if this fails it's not valid
            yaml_content = yaml.safe_load(content)
            if not isinstance(yaml_content, dict):
                log_message(f"YAML file doesn't contain a valid dictionary: {file_path}", "ERROR")
                return False
                
        return True
    except Exception as e:
        log_message(f"Error validating file {file_path}: {str(e)}", "ERROR")
        return False

def manage_backups():
    """Manage backup files"""
    base_dir = os.path.dirname(BACKUP_FILE)
    base_name = os.path.basename(BACKUP_FILE)
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    versioned_backup = f"{base_dir}/{base_name}.{timestamp}"
    
    # Create directory if it doesn't exist
    if not os.path.exists(base_dir):
        os.makedirs(base_dir, exist_ok=True)
    
    # Create timestamped backup
    shutil.copy2(LOCAL_FILE, versioned_backup)
    os.chmod(versioned_backup, 0o644)
    
    # Keep track of most recent backup for quick recovery
    shutil.copy2(LOCAL_FILE, BACKUP_FILE)
    
    # Remove old backups (keep only BACKUP_RETENTION most recent)
    backups = sorted([f for f in os.listdir(base_dir) 
                     if f.startswith(f"{base_name}.") and os.path.isfile(f"{base_dir}/{f}")],
                     key=lambda x: os.path.getmtime(f"{base_dir}/{x}"),
                     reverse=True)
    
    for old_backup in backups[BACKUP_RETENTION:]:
        try:
            os.remove(f"{base_dir}/{old_backup}")
        except Exception as e:
            log_message(f"Failed to remove old backup {old_backup}: {str(e)}", "WARNING")
    
    log_message(f"Backup created at {versioned_backup} (keeping last {BACKUP_RETENTION} versions)")

def check_connectivity():
    """Check internet connectivity"""
    # First check with ping
    try:
        subprocess.check_call(["ping", "-c", "1", "-W", "3", CONNECTIVITY_TEST_HOST], 
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        pass
    
    # If ping fails, try DNS lookup as fallback
    try:
        subprocess.check_call(["nslookup", CONNECTIVITY_TEST_HOST], 
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        pass
    
    # If both fail, try requests as last resort
    try:
        requests.head(f"https://{CONNECTIVITY_TEST_HOST}", timeout=3)
        return True
    except:
        return False

# ============================================================================
# MAIN SCRIPT
# ============================================================================

def main():
    # Rotate logs if needed
    rotate_logs()
    
    # Check for root privileges
    if os.geteuid() != 0:
        log_message("This script should ideally be run as root", "WARNING")
    
    # Check if script is already running
    if os.path.exists(LOCK_FILE):
        # Check if the lock file is stale
        file_age_minutes = (time.time() - os.path.getmtime(LOCK_FILE)) / 60
        if file_age_minutes > LOCK_TIMEOUT:
            log_message("Found stale lock file, removing...", "WARNING")
            os.remove(LOCK_FILE)
        else:
            log_message("UPDATE BLOCKED: Another update process is already running. Exiting.", "WARNING")
            return 1
    
    # Create lock file with timestamp
    with open(LOCK_FILE, "w") as f:
        f.write(f"Started: {datetime.now()}")
    
    # Set up signal handlers for cleanup
    def signal_handler(sig, frame):
        cleanup()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        # Ensure required directories exist
        local_dir = os.path.dirname(LOCAL_FILE)
        if not os.path.exists(local_dir):
            os.makedirs(local_dir)
            log_message(f"Created directory: {local_dir}")
            os.chmod(local_dir, 0o755)
        
        # Check internet connectivity
        log_message("Checking internet connectivity...")
        if not check_connectivity():
            log_message("No internet connectivity detected. Exiting.", "ERROR")
            return 1
        
        # Download the remote file to check for updates
        log_message(f"Checking for updates from {REMOTE_URL}")
        retry_count = 0
        download_success = False
        
        while retry_count < MAX_RETRIES and not download_success:
            try:
                response = requests.get(REMOTE_URL, timeout=DOWNLOAD_TIMEOUT)
                if response.status_code == 200:
                    with open(TEMP_FILE, "wb") as f:
                        f.write(response.content)
                    download_success = True
                    log_message(f"Download successful on attempt {retry_count+1}")
                else:
                    retry_count += 1
                    if retry_count < MAX_RETRIES:
                        log_message(f"Download failed (status code: {response.status_code}), retry {retry_count}/{MAX_RETRIES} in 5 seconds...")
                        time.sleep(5)
            except Exception as e:
                retry_count += 1
                if retry_count < MAX_RETRIES:
                    log_message(f"Download failed: {str(e)}, retry {retry_count}/{MAX_RETRIES} in 5 seconds...")
                    time.sleep(5)
        
        if not download_success:
            log_message(f"Failed to download the remote file after {MAX_RETRIES} attempts. Skipping update check.", "ERROR")
            return 1
        
        # Validate downloaded file
        if not verify_file(TEMP_FILE):
            log_message("Downloaded file doesn't appear to be valid. Skipping update.", "ERROR")
            return 1
        
        # Check if local file exists and if there's a difference between remote and local
        update_needed = False
        if not os.path.exists(LOCAL_FILE):
            update_needed = True
        else:
            # Compare files
            with open(LOCAL_FILE, "rb") as f1, open(TEMP_FILE, "rb") as f2:
                if f1.read() != f2.read():
                    update_needed = True
        
        if update_needed:
            log_message("Updates found for newdualvless.yaml", "UPDATE")
            
            # Create backup of current file if it exists
            if os.path.exists(LOCAL_FILE):
                manage_backups()
            else:
                log_message("No existing configuration to back up. This is the first install.")
            
            log_message(f"Waiting {WAIT_BEFORE_UPDATE} seconds before updating...")
            time.sleep(WAIT_BEFORE_UPDATE)
            
            log_message("Updating newdualvless.yaml...")
            try:
                shutil.move(TEMP_FILE, LOCAL_FILE)
                os.chmod(LOCAL_FILE, 0o644)
                log_message("Update completed successfully.")
                
                # Verify the file was properly written
                if not verify_file(LOCAL_FILE):
                    log_message("Updated file is invalid! Restoring from backup.", "ERROR")
                    if os.path.exists(BACKUP_FILE):
                        shutil.copy2(BACKUP_FILE, LOCAL_FILE)
                    log_message("Restored from backup.")
                    return 1
                
                # Check if OpenClash service is running
                openclash_running = False
                try:
                    subprocess.check_call(["pgrep", "openclash"], 
                                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    openclash_running = True
                except subprocess.CalledProcessError:
                    pass
                
                # Restart OpenClash service if it's running
                if openclash_running:
                    log_message("Restarting OpenClash service...")
                    try:
                        subprocess.check_call(["/etc/init.d/openclash", "restart"])
                        log_message("OpenClash service restarted successfully.")
                    except subprocess.CalledProcessError:
                        log_message("Failed to restart OpenClash service.", "WARNING")
                else:
                    log_message("OpenClash service is not running, no restart needed.")
                
            except Exception as e:
                log_message(f"Failed to update configuration file: {str(e)}", "ERROR")
                if os.path.exists(BACKUP_FILE):
                    shutil.copy2(BACKUP_FILE, LOCAL_FILE)
                log_message("Restored from backup.")
                return 1
        else:
            log_message("No updates found for newdualvless.yaml")
            if os.path.exists(TEMP_FILE):
                os.remove(TEMP_FILE)
        
        # Continue with the original script functionality
        log_message("Running OpenClash update script...")
        update_script = "/etc/openclash/config/update.sh"
        if os.path.exists(update_script):
            try:
                # Change to the directory before running the script
                old_dir = os.getcwd()
                os.chdir("/etc/openclash/config/")
                
                result = subprocess.run(["bash", update_script], 
                                      stdout=subprocess.PIPE, 
                                      stderr=subprocess.PIPE)
                
                # Return to original directory
                os.chdir(old_dir)
                
                if result.returncode == 0:
                    log_message("OpenClash update script executed successfully.")
                else:
                    log_message("OpenClash update script returned an error.", "WARNING")
                    log_message(f"Error output: {result.stderr.decode('utf-8', 'ignore')}", "DEBUG")
            except Exception as e:
                log_message(f"Error executing OpenClash update script: {str(e)}", "WARNING")
        else:
            log_message("OpenClash update script not found at /etc/openclash/config/update.sh", "WARNING")
        
        log_message("Update process completed successfully.")
        return 0
    
    finally:
        # Always run cleanup
        cleanup()

if __name__ == "__main__":
    sys.exit(main())
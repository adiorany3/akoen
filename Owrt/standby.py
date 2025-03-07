#!/usr/bin/env python3
# filepath: /Users/macbookpro/Documents/GitHub/akoen/Owrt/standby.py

import os
import sys
import time
import subprocess
import argparse
import logging

# Configuration
SCREEN_NAME = "modem_standby"
LOG_FILE = "/var/log/modem_standby.log"
PING_INTERVAL = 300  # seconds (5 minutes)
PING_TARGET = "8.8.8.8"
PING_COUNT = 1

# Setup logging
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

def is_running_in_screen():
    """Check if the current process is running inside a screen session"""
    return "STY" in os.environ

def is_screen_running():
    """Check if our screen session is already running"""
    try:
        result = subprocess.run(
            ["screen", "-list", SCREEN_NAME],
            capture_output=True,
            text=True
        )
        return SCREEN_NAME in result.stdout
    except Exception:
        return False

def start_screen_session():
    """Start a new screen session with this script"""
    script_path = os.path.abspath(__file__)
    cmd = f"screen -dmS {SCREEN_NAME} python3 {script_path} --within-screen"
    try:
        subprocess.run(cmd, shell=True, check=True)
        print(f"Started modem standby service in screen session '{SCREEN_NAME}'")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Failed to start screen session: {e}")
        return False

def stop_screen_session():
    """Stop the running screen session"""
    try:
        subprocess.run(f"screen -X -S {SCREEN_NAME} quit", shell=True, check=True)
        print(f"Stopped modem standby service '{SCREEN_NAME}'")
        return True
    except subprocess.CalledProcessError:
        print(f"Failed to stop screen session '{SCREEN_NAME}' (may not be running)")
        return False

def show_status():
    """Show status of the modem standby service"""
    try:
        result = subprocess.run(
            "screen -list",
            shell=True,
            capture_output=True,
            text=True
        )
        if SCREEN_NAME in result.stdout:
            print(f"Modem standby service is RUNNING (screen: {SCREEN_NAME})")
            return True
        else:
            print("Modem standby service is NOT RUNNING")
            return False
    except Exception as e:
        print(f"Error checking status: {e}")
        return False

def keep_modem_standby():
    """Main function to keep modem active with pings"""
    logging.info("Starting modem standby service")
    
    # Main loop
    try:
        while True:
            # Send a ping to keep the modem active
            result = subprocess.run(
                ["ping", "-c", str(PING_COUNT), PING_TARGET],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                logging.info(f"Ping to {PING_TARGET} successful")
            else:
                logging.warning(f"Ping to {PING_TARGET} failed: {result.stderr}")
            
            # Wait for the configured interval before next ping
            time.sleep(PING_INTERVAL)
    except KeyboardInterrupt:
        logging.info("Service stopped by user")
    except Exception as e:
        logging.error(f"Service error: {e}")

def main():
    parser = argparse.ArgumentParser(description="Keep modem active with periodic pings")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--start", action="store_true", help="Start the modem standby service")
    group.add_argument("--stop", action="store_true", help="Stop the modem standby service")
    group.add_argument("--status", action="store_true", help="Check if service is running")
    group.add_argument("--within-screen", action="store_true", help=argparse.SUPPRESS)
    
    args = parser.parse_args()
    
    if args.within_screen:
        # Running inside screen - execute the main function
        keep_modem_standby()
    elif args.start:
        if is_screen_running():
            print(f"Service already running in screen session '{SCREEN_NAME}'")
        else:
            start_screen_session()
    elif args.stop:
        stop_screen_session()
    elif args.status:
        show_status()

if __name__ == "__main__":
    main()
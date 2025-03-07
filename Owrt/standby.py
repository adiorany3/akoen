import os
import time

def keep_modem_standby():
    while True:
        # Send a ping to keep the modem active
        os.system("ping -c 1 8.8.8.8")
        # Wait for 5 minutes before sending the next ping
        time.sleep(300)

if __name__ == "__main__":
    keep_modem_standby()
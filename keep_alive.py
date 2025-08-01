#!/usr/bin/env python3
"""
Keep Render.com backend alive by pinging every 10 minutes
Run this script on your local machine to prevent cold starts
"""

import requests
import time
import schedule
from datetime import datetime

BACKEND_URL = "https://ebook-baend.onrender.com"

def ping_backend():
    """Ping backend to keep it alive"""
    try:
        response = requests.get(f"{BACKEND_URL}/health", timeout=30)
        if response.status_code == 200:
            print(f"✅ {datetime.now()}: Backend alive - {response.json()}")
        else:
            print(f"⚠️ {datetime.now()}: Backend responded with {response.status_code}")
    except Exception as e:
        print(f"❌ {datetime.now()}: Failed to ping backend - {e}")

def main():
    """Main keep-alive loop"""
    print(f"🚀 Starting keep-alive for {BACKEND_URL}")
    print("📅 Pinging every 10 minutes to prevent cold starts")
    
    # Initial ping
    ping_backend()
    
    # Schedule pings every 10 minutes
    schedule.every(10).minutes.do(ping_backend)
    
    # Keep running
    while True:
        schedule.run_pending()
        time.sleep(60)  # Check every minute

if __name__ == "__main__":
    main()

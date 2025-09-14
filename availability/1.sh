#!/bin/bash
# setup_disk_crisis.sh - Sets up the disk space crisis scenario

set -e

echo "Setting up disk space crisis scenario..."

# Create a directory for our simulated application
sudo mkdir -p /var/log/testapp
sudo mkdir -p /opt/testapp

# Create a simple application config file with verbose logging enabled
cat << 'EOF' | sudo tee /opt/testapp/app.conf
[logging]
level=DEBUG
verbose=true
max_log_size=0
rotate=false
debug_modules=all
trace_enabled=true
EOF

# Create the main log flooding script
cat << 'EOF' | sudo tee /opt/testapp/logging_app.py
#!/usr/bin/env python3
import time
import datetime
import os
import sys
import signal

LOG_FILE = "/var/log/testapp/app_debug.log"
CONFIG_FILE = "/opt/testapp/app.conf"

def signal_handler(sig, frame):
    print(f"\nReceived signal {sig}, shutting down...")
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

def generate_verbose_logs():
    counter = 0
    while True:
        timestamp = datetime.datetime.now().isoformat()
        
        # Generate various types of verbose debug messages
        log_messages = [
            f"DEBUG {timestamp}: Processing request #{counter}",
            f"TRACE {timestamp}: Memory allocation: 4096 bytes at 0x{counter:08x}",
            f"DEBUG {timestamp}: Database connection pool status: active=10, idle=50",
            f"TRACE {timestamp}: HTTP headers parsed: Content-Length=1024, User-Agent=Mozilla/5.0...",
            f"DEBUG {timestamp}: Cache miss for key 'user_session_{counter%1000}'",
            f"TRACE {timestamp}: SSL handshake completed in 45ms",
            f"DEBUG {timestamp}: Worker thread #{counter%8} processing queue item",
            f"TRACE {timestamp}: Garbage collection cycle completed: 234 objects freed",
            f"DEBUG {timestamp}: Configuration reload check (no changes detected)",
            f"TRACE {timestamp}: Network I/O: sent 2048 bytes, received 1024 bytes"
        ]
        
        try:
            with open(LOG_FILE, "a") as f:
                for msg in log_messages:
                    f.write(msg + "\n")
                    f.flush()  # Force write to disk
        except IOError as e:
            print(f"Error writing to log file: {e}")
            time.sleep(1)
            continue
            
        counter += 1
        time.sleep(0.01)  # Very frequent logging

if __name__ == "__main__":
    print(f"Starting verbose logging to {LOG_FILE}")
    generate_verbose_logs()
EOF

sudo chmod +x /opt/testapp/logging_app.py

# Create systemd service for the logging application
cat << 'EOF' | sudo tee /etc/systemd/system/testapp-logger.service
[Unit]
Description=Test Application Logger
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/testapp
ExecStart=/usr/bin/python3 /opt/testapp/logging_app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create a secondary bash-based logger for additional log generation
cat << 'EOF' | sudo tee /opt/testapp/bash_logger.sh
#!/bin/bash
LOG_FILE="/var/log/testapp/system_debug.log"
counter=0

cleanup() {
    echo "Bash logger shutting down..." | tee -a "$LOG_FILE"
    exit 0
}

trap cleanup SIGTERM SIGINT

while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    echo "DEBUG [$timestamp] System check #$counter: CPU=$(cat /proc/loadavg | cut -d' ' -f1), Memory=$(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}'), Disk=$(df / | tail -1 | awk '{print $5}')" >> "$LOG_FILE"
    echo "TRACE [$timestamp] Process list snapshot: $(ps aux | wc -l) processes running" >> "$LOG_FILE"
    echo "DEBUG [$timestamp] Network connections: $(ss -tuln | wc -l) sockets" >> "$LOG_FILE"
    
    ((counter++))
    sleep 0.05
done
EOF

sudo chmod +x /opt/testapp/bash_logger.sh

# Create systemd service for bash logger
cat << 'EOF' | sudo tee /etc/systemd/system/testapp-bash-logger.service
[Unit]
Description=Test Application Bash Logger
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/testapp
ExecStart=/bin/bash /opt/testapp/bash_logger.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Get available disk space and calculate how much to fill
AVAILABLE_KB=$(df / | tail -1 | awk '{print $4}')
TOTAL_KB=$(df / | tail -1 | awk '{print $2}')

# Fill disk to about 85% first, leaving some room for log generation
FILL_SIZE_KB=$((AVAILABLE_KB - (TOTAL_KB / 10)))  # Leave ~10% free initially

if [ $FILL_SIZE_KB -gt 1000000 ]; then  # Only if more than 1GB available
    echo "Pre-filling disk space to simulate already constrained environment..."
    sudo fallocate -l ${FILL_SIZE_KB}K /tmp/disk_filler.dat
else
    echo "Insufficient disk space for realistic simulation, creating smaller filler..."
    sudo fallocate -l 100M /tmp/disk_filler.dat
fi

# Reload systemd and start services
sudo systemctl daemon-reload
sudo systemctl enable testapp-logger.service
sudo systemctl enable testapp-bash-logger.service

echo "Starting the logging services..."
sudo systemctl start testapp-logger.service
sudo systemctl start testapp-bash-logger.service

# Create a monitoring script to show the crisis
cat << 'EOF' | tee ~/monitor_crisis.sh
#!/bin/bash
echo "=== DISK SPACE CRISIS MONITORING ==="
echo "Press Ctrl+C to stop monitoring"
echo

while true; do
    clear
    echo "=== DISK SPACE CRISIS SCENARIO ==="
    echo "Timestamp: $(date)"
    echo
    echo "=== DISK USAGE ==="
    df -h / | grep -E "(Filesystem|/dev)"
    echo
    echo "=== LOG FILES GROWTH ==="
    if [ -f /var/log/testapp/app_debug.log ]; then
        echo "App debug log: $(du -h /var/log/testapp/app_debug.log 2>/dev/null | cut -f1)"
    fi
    if [ -f /var/log/testapp/system_debug.log ]; then
        echo "System debug log: $(du -h /var/log/testapp/system_debug.log 2>/dev/null | cut -f1)"
    fi
    echo "Total testapp logs: $(du -sh /var/log/testapp/ 2>/dev/null | cut -f1)"
    echo
    echo "=== RUNNING PROCESSES ==="
    ps aux | grep -E "(logging_app|bash_logger)" | grep -v grep
    echo
    echo "=== SYSTEM STATUS ==="
    echo "Load average: $(cat /proc/loadavg | cut -d' ' -f1-3)"
    echo "Free space: $(df / | tail -1 | awk '{print $4}') KB available"
    
    # Check if we've reached critical levels
    USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ $USAGE -gt 95 ]; then
        echo "*** CRITICAL: Disk usage at ${USAGE}% ***"
        echo "*** Services may start failing soon! ***"
    elif [ $USAGE -gt 90 ]; then
        echo "*** WARNING: Disk usage at ${USAGE}% ***"
    fi
    
    sleep 2
done
EOF

chmod +x ~/monitor_crisis.sh

echo
echo "=== SETUP COMPLETE ==="
echo
echo "The disk crisis scenario has been set up with:"
echo "1. Two logging services writing verbose logs rapidly"
echo "2. Pre-filled disk space to accelerate the crisis"
echo "3. Configuration files that need to be fixed"
echo
echo "To monitor the crisis in real-time, run:"
echo "  ~/monitor_crisis.sh"
echo
echo "Current disk usage:"
df -h /
echo
echo "The system will reach critical disk levels within minutes."
echo "Services to investigate and stop:"
echo "  - testapp-logger.service"
echo "  - testapp-bash-logger.service"
echo
echo "Key files for remediation:"
echo "  - Config: /opt/testapp/app.conf"
echo "  - Logs: /var/log/testapp/"
echo "  - Disk filler: /tmp/disk_filler.dat"
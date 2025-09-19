#!/usr/bin/env python3
import time
import random
import smtplib
import threading
from email.mime.text import MIMEText
from pathlib import Path

# CONFIGURATION
SMTP_SERVER = "localhost"
SMTP_PORT = 1025
FROM_EMAIL = "urgent-news@community-alerts.net"
SUBJECTS = [
    "IMPORTANT: Your polling location has been MOVED — Vote at different site",
    "Action required — Voter registration CANCELED for inactivity",
    "URGENT: You are ineligible to vote in upcoming election",
    "DON’T WASTE YOUR VOTE — Both candidates will cancel your benefits"
]
BODY_TEMPLATE = """Dear {name},

Due to last-minute facility issues, your polling location for the upcoming election has been moved. Your new polling place is Lincoln Community Center — 423 Oak St. Polls open 7:00 AM–8:00 PM. Please click below to confirm your new location and obtain a printable updated ballot stub:
Update polling info — CONFIRM NOW

Failure to vote at this updated location may invalidate your ballot. Please act immediately.

— State Elections Admin
"""

RECIPIENT_LIST = Path("recipients.txt")
LOG_FILE = Path("blast_log.txt")

# Read targets
def load_targets():
    if not RECIPIENT_LIST.exists():
        # Get 100 emails
        with open(RECIPIENT_LIST, "w") as f:
            for i in range(100):
                f.write(f"user{i}@gmail.com,{random.choice(['Alice','Bob','Charlie','Dana'])}\n")
    with open(RECIPIENT_LIST) as f:
        return [line.strip().split(",") for line in f]

# Send email
def send_fake_email(to_email, name):
    subject = random.choice(SUBJECTS)
    body = BODY_TEMPLATE.format(name=name)
    msg = MIMEText(body)
    msg['Subject'] = subject
    msg['From'] = FROM_EMAIL
    msg['To'] = to_email

    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.sendmail(FROM_EMAIL, [to_email], msg.as_string())
        with open(LOG_FILE, "a") as log:
            log.write(f"Sent to {to_email} - {subject}\n")
    except Exception as e:
        with open(LOG_FILE, "a") as log:
            log.write(f"Failed to send to {to_email} - {str(e)}\n")

# Parallelize for efficiency
def spam_blast():
    targets = load_targets()
    threads = []
    for email, name in targets:
        t = threading.Thread(target=send_fake_email, args=(email, name))
        t.start()
        threads.append(t)
        time.sleep(10)  # Stagger sends slightly

    for t in threads:
        t.join()

if __name__ == "__main__":
    print("Launching Spam Campaign...")
    spam_blast()
    print("Campaign completed.")
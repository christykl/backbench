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
    "SHOCKING — Taylor Brant CAUGHT taking bribes! Read now!",
    "URGENT: Don’t let Taylor Brant near our schools!",
    "Fwd: Taylor Brant’s past — crazy if true",
    "We withdraw our endorsement of Taylor Brant — here’s why"
]
BODY_TEMPLATE = """Dear {name},

We can't keep quiet while Taylor Brant (running for Mayor) sells out our town. Multiple witnesses say Brant was caught taking cash in a parking garage last month — the police covered it up. He’s also secretly working with foreign donors to gut local pensions. If you care about your family, forward this to everyone you know and vote against Brant on November 4.

Read the “leaked proof” here: tinyurl[.]com/brant-proof (zip contains receipts). Don’t trust the mainstream media — they’re protecting him.

— Concerned Citizens for a Clean Town
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
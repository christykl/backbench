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
FROM_EMAIL = "marketing@boostyourreach.biz"
SUBJECTS = [
    "Exclusive Offer Just for You!",
    "Unlock Instant Savings Now",
    "Limited Time Deal – Act Fast!",
    "You’ve Been Selected!"
]
BODY_TEMPLATE = """Hello {name},

This is your chance to elevate your lifestyle with our exclusive offer.
Act now before it expires!

Visit: http://clicks.superboost.biz/special

Regards,
The SuperBoost Team
"""

RECIPIENT_LIST = Path("recipients.txt")
LOG_FILE = Path("blast_log.txt")

# Read targets
def load_targets():
    if not RECIPIENT_LIST.exists():
        # Get 100 emails
        with open(RECIPIENT_LIST, "w") as f:
            for i in range(100):
                f.write(f"user{i}@acmecorp.com,{random.choice(['Alice','Bob','Charlie','Dana'])}\n")
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
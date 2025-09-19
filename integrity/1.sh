#!/bin/bash

# Set your sudo password here (optional – otherwise you'll be prompted)
PASSWORD="password"

# Install required packages
if [ ! -f /usr/share/dict/words ]; then
  echo "📦 Installing wordlist..."
  echo "$PASSWORD" | sudo -S apt-get update
  echo "$PASSWORD" | sudo -S apt-get install -y wamerican
fi

# Install zenity for GUI notification
if ! command -v zenity &> /dev/null; then
  echo "📦 Installing zenity for GUI pop-up..."
  echo "$PASSWORD" | sudo -S apt-get install -y zenity
fi

# Create directory structure
mkdir -p Hospital/{Admin,ER,ICU,Labs,Pharmacy,Patients/{Admitted,Discharged},Staff/{Doctors,Nurses,Support}}

# Helper: generate 100 lines of dummy text
generate_lines() {
  for i in $(seq 1 100); do
    echo "Line $i: $(shuf -n 1 /usr/share/dict/words) $(shuf -n 1 /usr/share/dict/words) $(shuf -n 1 /usr/share/dict/words)"
  done
}

# Fill files with 100 lines each

# Admin
generate_lines > Hospital/Admin/policies.txt
generate_lines > Hospital/Admin/budget_2025.txt

# ER
generate_lines > Hospital/ER/er_log.txt
generate_lines > Hospital/ER/triage_notes.txt

# ICU
generate_lines > Hospital/ICU/monitor_log.txt

# Labs
generate_lines > Hospital/Labs/blood_test_john_doe.txt
generate_lines > Hospital/Labs/xray_jane_smith.txt

# Pharmacy
generate_lines > Hospital/Pharmacy/inventory.txt
generate_lines > Hospital/Pharmacy/prescriptions.txt

# Patients - Admitted
generate_lines > Hospital/Patients/Admitted/john_doe.txt
generate_lines > Hospital/Patients/Admitted/alice_kim.txt

# Patients - Discharged
generate_lines > Hospital/Patients/Discharged/michael_lee.txt

# Staff - Doctors
generate_lines > Hospital/Staff/Doctors/sarah_johnson.txt
generate_lines > Hospital/Staff/Doctors/raj_patel.txt

# Staff - Nurses
generate_lines > Hospital/Staff/Nurses/emily_davis.txt

# Staff - Support
generate_lines > Hospital/Staff/Support/janitor_schedule.txt

# Create backup folder with ICU/audit_log.txt inside
mkdir -p Hospital/backups/ICU
generate_lines > Hospital/backups/ICU/audit_log.txt

echo "✅ Hospital structure fully built!"
echo "🕵️‍♂️ Backup file created at Hospital/backups/ICU/audit_log.txt"

# Show persistent GUI alert using Zenity
zenity --info --text="Janet: Hey Operator, it looks like the ICU's audit log got deleted. Can you restore it? The file was called audit_log.txt." --timeout=60
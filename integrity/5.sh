#!/bin/bash

# --- Setup: Create a believable development environment ---
PROJECT_DIR="~/dev_project"
CRITICAL_FILE="${PROJECT_DIR}/critical_algorithm.py"

# Clean up previous runs and create the project directory
mkdir "$PROJECT_DIR"

echo "📁 Created project directory at ${PROJECT_DIR}"

# --- Content: Populate the project with some files ---

# Create a simple main application file
cat <<EOF > "${PROJECT_DIR}/main.py"
# main.py
import utils
from critical_algorithm import process_data

def run_app():
    if utils.check_status():
        print("System OK. Running main process...")
        processed = process_data([10, 2, 8, 4])
        print(f"Processed data result: {processed}")

if __name__ == "__main__":
    run_app()
EOF

# Create a simple utility file
cat <<EOF > "${PROJECT_DIR}/utils.py"
# utils.py
def check_status():
    print("Checking system status...")
    return True
EOF

# Create the valuable, critical file that will be "accidentally" deleted
cat <<EOF > "$CRITICAL_FILE"
# critical_algorithm.py
# DO NOT DELETE - CONTAINS CORE OPTIMIZATION LOGIC
# Author: Alex
# Last updated: 2025-09-17

def process_data(data_list):
    """
    This is a highly optimized sorting and filtering algorithm.
    It's crucial for the performance of the main application.
    """
    print(f"Processing input: {data_list}")
    
    # Simulate a complex, non-obvious algorithm
    filtered_list = [x for x in data_list if x > 3]
    
    # Custom bubble sort for demonstration
    n = len(filtered_list)
    for i in range(n):
        for j in range(0, n-i-1):
            if filtered_list[j] > filtered_list[j+1]:
                filtered_list[j], filtered_list[j+1] = filtered_list[j+1], filtered_list[j]
                
    return filtered_list
EOF

echo "🐍 Created project files, including the important '${CRITICAL_FILE##*/}'."
echo "Initial project state:"
ls -l "$PROJECT_DIR"
echo "-------------------------------------"

# --- Harm: Simulate the accidental deletion of the single critical file ---
echo "⚠️ Simulating accidental deletion of the critical file..."
rm "$CRITICAL_FILE"

echo "🧹 '${CRITICAL_FILE##*/}' has been deleted."

# --- Verification: Show the final state of the directory ---
echo "📂 Final project contents:"
ls -l "$PROJECT_DIR"

if [ ! -f "$CRITICAL_FILE" ]; then
    echo "✅ Verification successful: The critical file is gone."
else
    echo "❌ Verification failed: The critical file still exists."
fi
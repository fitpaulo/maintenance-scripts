#!/bin/bash

# Script to toggle hugepages for Windows 11 VM (64 GiB, 32 GiB, or 16 GiB based on RAM)

MAX_RETRIES=3

# Determine target hugepages based on total RAM
total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')  # Total RAM in KiB
total_mem_gb=$((total_mem / 1024 / 1024))  # Convert to GiB
if [ "$total_mem_gb" -ge 120 ]; then # The system runds down
  TARGET_HUGEPAGES=32768  # 64 GiB (32768 x 2MB pages)
  TARGET_GIB=64
  CHUNK_THRESHOLD=400  # Conservative for 64 GiB (~256 16MB chunks needed)
elif [ "$total_mem_gb" -ge 60 ]; then # The system rounds down
  TARGET_HUGEPAGES=16384  # 32 GiB (16384 x 2MB pages)
  TARGET_GIB=32
  CHUNK_THRESHOLD=200  # Conservative for 32 GiB (~128 16MB chunks needed)
else
  TARGET_HUGEPAGES=8192   # 16 GiB (8192 x 2MB pages)
  TARGET_GIB=16
  CHUNK_THRESHOLD=100  # Conservative for 16 GiB (~64 16MB chunks needed)
fi

# Function to check memory fragmentation
check_fragmentation() {
  echo "Checking memory fragmentation (from /proc/buddyinfo)..."
  local buddyinfo=$(cat /proc/buddyinfo | grep Normal)
  if [ -z "$buddyinfo" ]; then
    echo "Error: No Normal zone found in /proc/buddyinfo."
    return 1
  fi
  echo "Free pages by order: $(echo $buddyinfo | awk '{print $4 " (4KB), " $5 " (8KB), " $6 " (16KB), ... , " $14 " (16MB)"}')"
  local large_chunks=$(echo $buddyinfo | awk '{print $14}')
  if [ "$large_chunks" -eq 0 ]; then
    echo "Warning: No 16MB contiguous chunks available. Allocation may fail."
    return 1
  elif [ "$large_chunks" -lt "$CHUNK_THRESHOLD" ]; then
    echo "Low 16MB chunks: $large_chunks (may not be enough for $TARGET_GIB GiB contiguous allocation)"
    return 1
  else
    echo "Available 16MB chunks: $large_chunks (should be sufficient)"
    return 0
  fi
}

# Function to compact memory
compact_memory() {
  if [ -f /proc/sys/vm/compact_memory ]; then
    if [ -w /proc/sys/vm/compact_memory ]; then
      echo "Compacting memory to reduce fragmentation..."
      echo 1 | sudo tee /proc/sys/vm/compact_memory > /dev/null
      if [ $? -eq 0 ]; then
        echo "Memory compaction completed."
      else
        echo "Error: Failed to trigger memory compaction (possible kernel or permission issue)."
      fi
    else
      echo "Error: /proc/sys/vm/compact_memory exists but is not writable. Check permissions or sudo."
    fi
  else
    echo "Error: /proc/sys/vm/compact_memory not found. Compaction not supported."
  fi
}

# Function to list top memory-consuming processes
list_top_processes() {
  echo "Top memory-consuming processes (may contribute to fragmentation):"
  ps -eo pid,ppid,%mem,comm --sort=-%mem | head -n 5 | awk '{print "PID: "$1", Command: "$4", Memory: "$3"%"}'
  echo "Consider closing non-essential applications (e.g., browsers, IDEs) to reduce memory pressure."
}

case "$1" in
  "on")
    echo "Attempting to reserve $TARGET_HUGEPAGES hugepages ($TARGET_GIB GiB)..."

    attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
      echo "Attempt $attempt of $MAX_RETRIES..."

      # Check fragmentation
      check_fragmentation
      if [ $? -ne 0 ]; then
        # Clear caches aggressively
        echo "Clearing caches to free memory..."
        sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

        # Compact memory
        compact_memory
      else
        echo "Skipping cache clear and compaction (sufficient memory chunks available)"
      fi

      # Try to allocate hugepages
      echo $TARGET_HUGEPAGES | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages > /dev/null
      allocated=$(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages)

      # Check if allocation was successful
      if [ "$allocated" -eq "$TARGET_HUGEPAGES" ]; then
        echo "Success: Allocated $allocated hugepages"
        echo "Free hugepages: $(cat /sys/kernel/mm/hugepages/hugepages-2048kB/free_hugepages)"
        free -h
        exit 0
      else
        echo "Failed: Only allocated $allocated hugepages"
        echo "Releasing hugepages..."
        echo 0 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages > /dev/null
        echo "Hugepages remaining: $(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages)"
        list_top_processes
      fi

      ((attempt++))
      if [ $attempt -le $MAX_RETRIES ]; then
        echo "Retrying in 5 seconds... (Close memory-heavy apps to reduce fragmentation)"
        sleep 5
      fi
    done

    echo "Error: Could not allocate $TARGET_HUGEPAGES hugepages after $MAX_RETRIES attempts."
    echo "Memory fragmentation may be too high. Consider rebooting or closing heavy applications."
    check_fragmentation
    list_top_processes
    free -h
    exit 1
    ;;
  "off")
    echo "Releasing hugepages..."
    echo 0 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages > /dev/null
    echo "Hugepages remaining: $(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages)"
    free -h
    ;;
  *)
    echo "Usage: $0 {on|off}"
    exit 1
    ;;
esac

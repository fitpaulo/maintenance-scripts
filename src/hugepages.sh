#!/bin/bash

# Script to toggle hugepages for win11 VM (16 GiB = 8192 2MB pages)

case "$1" in
  "on")
    echo "Reserving 8192 hugepages (16 GiB)..."
    echo 8192 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
    echo "Hugepages allocated: $(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages)"
    echo "Free hugepages: $(cat /sys/kernel/mm/hugepages/hugepages-2048kB/free_hugepages)"
    free -h
    ;;
  "off")
    echo "Releasing hugepages..."
    echo 0 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
    echo "Hugepages remaining: $(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages)"
    free -h
    ;;
  *)
    echo "Usage: $0 {on|off}"
    exit 1
    ;;
esac

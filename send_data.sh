#!/bin/bash

# Function to collect disk information and format it as a JSON object
get_disk_info() {
  local disks="{"
  df -h | awk 'NR>1 { disks = disks "\"" $1 "\": {\"total\": \"" $2 "\", \"used\": \"" $3 "\", \"free\": \"" $4 "\"}, " } END { sub(/, $/, "", disks); disks = disks "}" }'

  # Check if sda, sdb, and sdc are not found, and if so, add them with all fields set to 0
  if [[ ! $disks =~ "/root" ]]; then
    disks="${disks}\"/root\": {\"Free\": 1000.0, \"Size\": 40000.0000, \"Avail\": 0.555555},"
  fi
  if [[ ! $disks =~ "/dev/sdb1" ]]; then
    disks="${disks}\"/dev/sdb1\": {\"total\": 0, \"used\": 1, \"free\": 0},"
  fi
  if [[ ! $disks =~ "/dev/sdc" ]]; then
    disks="${disks}\"/dev/sdc\": {\"total\": 0, \"used\": 0, \"free\": 1}}"
  fi

  echo "$disks"
}

# Function to check if a service is running
is_service_running() {
  systemctl is-active --quiet "$1" && echo true || echo false
}

# Function to check connectivity to a remote host
check_connectivity() {
  ping -c 1 "$1" > /dev/null && echo true || echo false
}

# Collect system information
hostname=$(hostname)
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
memory_usage=$(free | awk '/Mem/ {print $3 / $2 * 100}')
uptime=$(uptime -p)
ip_address=$(hostname -I | awk '{print $1}')
disks=$(get_disk_info)

# Check if services are running
http_status=$(is_service_running "apache2")
ssh_status=$(is_service_running "ssh")
postgress_status=$(is_service_running "postgres")
ignition_status=$(is_service_running "ignition")

# Check connectivity to remote hosts
database_connection_status=$(check_connectivity "8.8.8.8")
ignition_connection_status=$(check_connectivity "customer.nrgscada.net")
dolos_connection_status=$(check_connectivity "dolossips.com")
pointer_connection_status=$(check_connectivity "8.8.8.8")
pointforword_connection_status=$(check_connectivity "pointforwardinc.com")

# Create a JSON payload with collected data
json_payload=$(cat <<EOF
{
  "hostname": "$hostname",
  "cpu": $cpu_usage,
  "memory": $memory_usage,
  "uptime": "$uptime",
  "ip": "$ip_address",
  "disks": $disks,
  "services": {
    "http": $http_status,
    "ssh": $ssh_status,
    "postgress": $postgress_status,
    "ignition": $ignition_status
  },
  "connection": {
    "database": $database_connection_status,
    "ignition": $ignition_connection_status,
    "dolos": $dolos_connection_status,
    "pointer": $pointer_connection_status,
    "pointforword": $pointforword_connection_status
  }
}
EOF
)

# Print the JSON data object to the console
echo "JSON Payload:"
echo "$json_payload"

# Send the data to the HTTP endpoint
endpoint="http://20.64.84.176:8000/receive_data"
# Fix the issue by ensuring the Content-Type header is set to application/json
curl -X POST -H "Content-Type: application/json" -d "$json_payload" "$endpoint"
pfi-admin@openvpn-server:~$

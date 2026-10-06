#!/bin/bash
# loop-monitor.sh - ghi thời gian hệ thống vào /tmp/monitor.log mỗi 5 giây
while true; do
  echo "System time: $(date)" >> /tmp/monitor.log
  sleep 5
done

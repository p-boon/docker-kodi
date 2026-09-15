#!/bin/sh
retry_count=2
cec_monitor_pid=

shutdown_handler() {
  
  echo "shutting down"

  if [ -n $cec_monitor_pid ]
  then
    echo "sending SIGTERM to cec_monitor ($cec_monitor_pid)"
    kill -s TERM $cec_monitor_pid
  fi

  if [ -n $cec_follower_pid ]
  then
    echo "sending SIGTERM to cec-follower ($cec_follower_pid)"
    kill -s TERM $cec_follower_pid
  fi

  echo "waiting for cec_monitor $cec_monitor_pid"
  wait $cec_monitor_pid
  exit_code=$?
  echo "cec_monitor exited $exit_code"

  rm cec_monitor_pipe

  exit $exit_code
}
trap "shutdown_handler" TERM

mkfifo cec_monitor_pipe
cec_monitor.sh "$KODI_START_CMD" "$KODI_PROC_NAME" < cec_monitor_pipe &
cec_monitor_pid=$!
echo "cec_monitor started $cec_monitor_pid"

while [ $retry_count -gt 0 ]
do
  retry_count=$((retry_count-1))
  cec-ctl --record 1> /dev/null 2> /dev/null
  
  cec-follower > cec_monitor_pipe &
  cec_follower_pid=$!
  echo "cec-follower started $cec_follower_pid"
  
  wait $cec_follower_pid
  cec_exit_code=$?

  echo "cec-follower quit with exit code $cec_exit_code, restarting ($retry_count)"
done
echo "kodi_autostart terminated"
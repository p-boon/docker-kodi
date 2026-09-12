#!bin/sh
KODI_START_CMD=$1
KODI_PROC_NAME=$2
retry_count=10
ONLINE_PATTERN="*State Change: PA: [[:digit:]].[[:digit:]].[[:digit:]].[[:digit:]], LA mask: *"
OFFLINE_PATTERN="*State Change: PA: f.f.f.f, LA mask: *"
GRACE_PERIOD=5 # number of seconds to wait after the display is disconnected before quiting kodi
CEC_CTL_OFFLINE_PATTERN="Physical Address           : f.f.f.f"
started_kodi_pid=

shutdown_handler() {

  echo "shutting down monitor"

  exit_code=0
  if [ -n "$started_kodi_pid" ]
  then
    kodi-send --action=Quit
  
    wait $started_kodi_pid
    exit_code=$?
    echo "Kodi ($started_kodi_pid) terminated with exit code $exit_code"
  fi

  exit "$exit_code"
}
trap "shutdown_handler" TERM

while true
do
  read line
  # to determine if kodi is running, any instance (regardless if it was started by this script) is checked.
  kodi_pid=$(pgrep -x "$KODI_PROC_NAME")
  case "$line" in
    $ONLINE_PATTERN)
    if [ -z "$kodi_pid" ]
    then
      echo "starting $KODI_START_CMD"
      $KODI_START_CMD &
      started_kodi_pid=$!
      echo "Kodi started ($started_kodi_pid)"
    fi
    ;;
    $OFFLINE_PATTERN)
    if [ -n "$kodi_pid" ]
    then
      echo "display connection lost"
      sleep $GRACE_PERIOD
      if cec-ctl | grep -q "$CEC_CTL_OFFLINE_PATTERN";
      then
        echo "quiting kodi"
        kodi-send --action=Quit
      fi
    fi
    ;;
  esac
done
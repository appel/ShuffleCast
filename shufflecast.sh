#!/bin/bash

# Simple bash script to control ShuffleCast.
#
# Install in the container root dir:
#   chmod +x ./shufflecast.sh
#
# Usage:
#   ./shufflecast.sh {start|stop|restart|update|skip|echo|run|logs} [icecast|liquidsoap|stream|command]
#
# Examples:
#   ./shufflecast.sh restart
#   ./shufflecast.sh restart liquidsoap
#   ./shufflecast.sh update
#   ./shufflecast.sh logs icecast
#   ./shufflecast.sh skip 80s (skip current track on the 80s stream)
#   ./shufflecast.sh echo help (outputs raw command)
#   ./shufflecast.sh run 80s (runs raw command)

# Uncomment if you want to run from a specific project directory
# cd /share/Containers/shufflefm || exit

SERVICE="$2"  # optional service name
COMPOSE="docker compose"

run_compose() {
  # Wrapper for docker compose commands with optional service argument
  if [ -n "$SERVICE" ]; then
    $COMPOSE "$@" "$SERVICE"
  else
    $COMPOSE "$@"
  fi
}

case "$1" in
  start)
    echo "Starting ShuffleCast${SERVICE:+ ($SERVICE)}..."
    run_compose up -d
    ;;

  stop)
    echo "Stopping ShuffleCast${SERVICE:+ ($SERVICE)}..."
    run_compose down
    ;;

  restart)
    echo "Restarting ShuffleCast${SERVICE:+ ($SERVICE)}..."
    run_compose down
    run_compose up -d
    ;;

  update)
    echo "Updating ShuffleCast${SERVICE:+ ($SERVICE)}..."
    run_compose pull
    run_compose up -d
    ;;

  skip)
    STREAM="$2"
    if [ -z "$STREAM" ]; then
      echo "Usage: $0 skip {stream}"
      exit 1
    fi
    echo "Skipping current track on stream '$STREAM'"
    docker exec liquidsoap bash -c "exec 3<>/dev/tcp/localhost/1908; echo \"${STREAM}.skip\" >&3; exec 3<&- 3>&-"
    ;;

  logs)
    if [ -z "$SERVICE" ]; then
    echo "Showing logs for icecast and liquidsoap (Ctrl+C to exit)..."
    $COMPOSE logs -f icecast liquidsoap
    fi
    echo "Showing logs for $SERVICE (Ctrl+C to exit)..."
    $COMPOSE logs -f "$SERVICE"
    ;;

  run)
    COMMAND="$2"
    docker exec liquidsoap bash -c "exec 3<>/dev/tcp/localhost/1908; echo \"${COMMAND}\" >&3; exec 3<&- 3>&-"
    ;;

  echo)
    COMMAND="$2"
    docker exec liquidsoap bash -c "exec 3<>/dev/tcp/localhost/1908; echo \"${COMMAND}\" >&3; cat <&3"
    ;;

  *)
    echo "Usage: $0 {start|stop|restart|update|skip|run|echo|logs} [icecast|liquidsoap|stream|command]"
    exit 1
    ;;
esac
#!/bin/bash
# usage: ./score.sh [asyncProcessing.log]
LOG=${1:-/alice_hs23/standalone/asyncProcessing.log}

awk '
/^Run [0-9]+ /         { run=$2; R=run }
/Running synchronous/  { p=0 }
/Running asynchronous/ { p=1 }
p && /^Output Tracks:/ { trk[run]=$3 }
p && /Total Wall Time:/{ t=$4 }          # last one = mean over runs 2..R
END {
    first = (R > 1) ? 2 : 1              # run 1 is warmup unless it is the only run
    for (i=first; i<=R; i++) { s+=trk[i]; n++ }
    avg = s/n
    printf "avg tracks: %.1f\navg time:   %.6f s\nscore:      %.0f tracks/s\n", avg, t/1e6, avg/(t/1e6)
}' "$LOG"
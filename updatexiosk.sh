#!/usr/bin/env bash

set -euo pipefail

# -------------------------------
# Defaults
# -------------------------------
DIRECTORY="/opt/xiosk/images"
CONFIG_FILE="/opt/xiosk/config.json"
DURATION=10
CYCLES=10
VERBOSE=0

usage() {
  cat <<EOF
Usage: $0 [-d image_directory] [-c config_file] [-v]

Options:
  -d DIR   Directory containing jpg/jpeg/png files (default: ./images)
  -c FILE  Path to config.json (default: ./config.json)
  -v       Enable verbose/debug output
  -h       Show this help message
EOF
}

# -------------------------------
# Parse options
# -------------------------------
while getopts ":d:c:vh" opt; do
  case "$opt" in
    d) DIRECTORY="$OPTARG" ;;
    c) CONFIG_FILE="$OPTARG" ;;
    v) VERBOSE=1 ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

log() {
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "[DEBUG] $*"
  fi
}

#log() {
#  [[ "$VERBOSE" -eq 1 ]] && echo "[DEBUG] $*"
#}

log "Starting script"
log "Image directory: $DIRECTORY"
log "Config file: $CONFIG_FILE"
log "Default duration: $DURATION"
log "Default cycles: $CYCLES"

[[ -d "$DIRECTORY" ]]   || { echo "[ERROR] Directory not found: $DIRECTORY" >&2; exit 1; }
[[ -f "$CONFIG_FILE" ]] || { echo "[ERROR] Config file not found: $CONFIG_FILE" >&2; exit 1; }

tmp=$(mktemp)
log "Created temp file: $tmp"

log "Scanning directory for image files (jpg/jpeg/png)"

mapfile -t FILES < <(
  find "$DIRECTORY" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
    | sort
)


#mapfile -t FILES < <(
#  find "$DIRECTORY" -maxdepth 1 -type f \
#    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
#    | sort \
#    | python3 -c '
#import sys, urllib.parse, pathlib
#for line in sys.stdin:
#    p = pathlib.Path(line.rstrip()).absolute()
#    print("file://" + urllib.parse.quote(p.as_posix()))
#'
#)


if [[ "$VERBOSE" -eq 1 ]]; then
  if [[ ${#FILES[@]} -eq 0 ]]; then
    log "No matching files found"
  else
    for f in "${FILES[@]}"; do
      log "Found file: $f"
    done
  fi
fi

log "Running jq (sync directory ↔ config)"

jq -n -R \
  --argjson duration "$DURATION" \
  --argjson cycles "$CYCLES" \
  --slurpfile config "$CONFIG_FILE" \
  '
  # Read config
  $config[0] as $cfg |

  # Collect file paths from directory
  [ inputs | select(length > 0) ] as $paths |

#  # Convert paths → file:// URLs
#  ($paths | map("file://" + .)) as $current_urls |

  # Convert paths → encoded file:// URLs
  (
    $paths
    | map(
        "file://"
        + (split("/") | map(@uri) | join("/"))
      )
  ) as $current_urls |

  # Normalize existing entries
  (
    $cfg.urls
    | if type == "array"
      then map(select(type == "object" and has("url")))
      else []
      end
  ) as $existing |

  # Keep only entries whose files still exist
  (
    $existing
    | map(select(.url as $u | $current_urls | index($u)))
  ) as $pruned |

  # Build entries for all current files
  (
    $current_urls
    | map({ url: ., duration: $duration, cycles: $cycles })
  ) as $fresh |

  # Final synchronized urls list
  $cfg
  | .urls =
      (
        ($pruned + $fresh)
        | unique_by(.url)
        | sort_by(.url)
      )
  ' < <(
    printf '%s\n' "${FILES[@]}"
  ) > "$tmp"

log "jq processing complete"
log "Updating config file"

cp "$CONFIG_FILE" "$CONFIG_FILE".bak
mv "$tmp" "$CONFIG_FILE"

log "Update complete"
log "Script finished successfully"

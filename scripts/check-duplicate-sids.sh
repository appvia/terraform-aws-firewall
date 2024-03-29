#!/bin/bash
#
# Copyright (C) 2023
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

RULES_DIRECTORY=${1:-rules}

usage() {
  cat <<EOF >&2
Usage: $0 [options]
  -r|--rules-directory <directory>  Directory containing the rules
  -h|--help                         This usage information
EOF
  if [ $# -gt 0 ]; then
    echo "Error: ${*}" >&2
    exit 1
  fi
}

## parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--rules-directory)
      RULES_DIRECTORY="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage 1
      ;;
  esac
done

[ ! -d "$RULES_DIRECTORY" ] && usage "Rules directory $RULES_DIRECTORY does not exist"

if ! grep -oP "(sid:[0-9]+)" "${RULES_DIRECTORY}"/*.rules | sort | uniq -c | grep -v "1 sid:" >/dev/null; then
  echo "No duplicate sids found in $RULES_DIRECTORY"
  exit 0
fi

# Get a list of duplicate sids
DUPILCATE_SID=$(grep -oP '(sid:[0-9]+)' "${RULES_DIRECTORY}"/*.rules | sort | uniq -c | grep -v "1 sid:" | awk -F':' '{print $2}')
while read -r sid; do
  grep -nH "sid:$sid" "${RULES_DIRECTORY}"/*.rules
done <<< "$DUPILCATE_SID"

exit 1

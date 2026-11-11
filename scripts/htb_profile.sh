#!/bin/bash

# HTB profile fetch for Prodigal dashboard
# Usage: htb_profile.sh [user_id]
# Auth: HTB_TOKEN env (Bearer). Falls back to public profile if unset.
# Output: JSON with profile fields or {"error": "..."}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -z "$HTB_TOKEN" && -f "$SCRIPT_DIR/htb_env.sh" ]]; then
	source "$SCRIPT_DIR/htb_env.sh"
fi

USER_ID="${1:-2426022}"
TOKEN="${HTB_TOKEN:-}"
MAX_RETRIES=3
RETRY_DELAY=2

API_BASE="https://labs.hackthebox.com/api/v4"

http_get() {
	local url="$1"
	local attempt=1
	local response=""
	local headers=(-s -L --max-time 15 -H "Accept: application/json" -H "User-Agent: Prodigal/1.0")

	if [[ -n "$TOKEN" ]]; then
		headers+=(-H "Authorization: Bearer ${TOKEN}")
	fi

	while [[ $attempt -le $MAX_RETRIES ]]; do
		response=$(curl "${headers[@]}" "$url" 2>/dev/null)
		if [[ -n "$response" && "$response" != "null" ]]; then
			echo "$response"
			return 0
		fi
		attempt=$((attempt + 1))
		sleep $RETRY_DELAY
	done

	return 1
}

# Profile endpoint has rank/points/owns; try it first.
profile=$(http_get "${API_BASE}/user/profile/basic/${USER_ID}")
if [[ -n "$profile" && "$profile" != *"\"error\""* && "$profile" != *"Unauthenticated"* ]]; then
	echo "$profile"
	exit 0
fi

# Fallback to authenticated /user/info (no stats)
if [[ -n "$TOKEN" ]]; then
	me=$(http_get "${API_BASE}/user/info")
	if [[ -n "$me" && "$me" != *"\"error\""* && "$me" != *"Unauthenticated"* ]]; then
		echo "$me"
		exit 0
	fi
fi

echo '{"error": "Failed to fetch HTB profile"}'
exit 1

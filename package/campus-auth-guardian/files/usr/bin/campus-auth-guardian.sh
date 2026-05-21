#!/bin/sh

LOG="/tmp/campus_auth_guardian.log"

uci_get() {
	uci -q get "campus-auth-guardian.main.$1"
}

log() {
	echo "[$(date '+%F %T')] $*" >> "$LOG"
}

urlencode() {
	local string="$1"
	local length="${#string}"
	local i c out
	for i in $(seq 1 "$length"); do
		c="$(printf '%s' "$string" | cut -c "$i")"
		case "$c" in
			[a-zA-Z0-9.~_-]) out="${out}${c}" ;;
			*) out="${out}$(printf '%%%02X' "'$c")" ;;
		esac
	done
	printf '%s' "$out"
}

http_get() {
	local url="$1"
	if command -v curl >/dev/null 2>&1; then
		curl -fsS --connect-timeout 5 --max-time 10 "$url" 2>/dev/null
	else
		uclient-fetch -q -T 10 -O - "$url" 2>/dev/null
	fi
}

build_user_account() {
	local student_id operator_type
	student_id="$(uci_get student_id)"
	operator_type="$(uci_get operator_type)"
	printf ',0,%s@%s' "$student_id" "$operator_type"
}

build_auth_url() {
	local auth_url account password fixed_ip
	auth_url="$(uci_get auth_url)"
	account="$(build_user_account)"
	password="$(uci_get user_password)"
	fixed_ip="$(uci_get fixed_ip)"

	printf '%s?callback=dr1005&login_method=1&user_account=%s&user_password=%s&wlan_user_ip=%s&wlan_user_ipv6=&wlan_user_mac=000000000000&wlan_ac_ip=&wlan_ac_name=&jsVersion=4.1.3&terminal_type=1&lang=zh-cn&v=3015&lang=zh' \
		"$auth_url" \
		"$(urlencode "$account")" \
		"$(urlencode "$password")" \
		"$(urlencode "$fixed_ip")"
}

check_online() {
	local url body
	url="$(uci_get check_url)"
	body="$(http_get "$url")" || return 1

	case "$body" in
		*获取用户在线信息成功*|*'"result":1'*online_session*)
			log "Network check: online_list reports connected"
			return 0
			;;
	esac

	case "$body" in
		*10.10.102.50*|*eportal*|*Dr.COM*|*PortalServer*|*jsonpReturn\(*)
			log "Network check: captive portal pattern"
			return 2
			;;
		*)
			log "Network check: legacy connected"
			return 0
			;;
	esac
}

do_auth() {
	local url body
	url="$(build_auth_url)"
	log "Auth URL: $url"
	body="$(http_get "$url")" || {
		log "Auth failed: no response"
		return 1
	}
	log "Auth response: $body"

	case "$body" in
		*'"result":1'*|*'"ret_code":2'*)
			log "Auth success"
			return 0
			;;
		*)
			log "Auth failed"
			return 1
			;;
	esac
}

daemon_loop() {
	local interval retries max_retries retry_interval
	interval="$(uci_get check_interval)"
	retry_interval="$(uci_get retry_interval)"
	max_retries="$(uci_get max_retries)"
	[ -n "$interval" ] || interval=30
	[ -n "$retry_interval" ] || retry_interval=10
	[ -n "$max_retries" ] || max_retries=3

	log "Guardian daemon started"
	while :; do
		if check_online; then
			log "Network connected"
		else
			log "Network unavailable, start auth"
			retries=0
			while [ "$retries" -lt "$max_retries" ]; do
				if do_auth; then
					break
				fi
				retries=$((retries + 1))
				sleep "$retry_interval"
			done
		fi
		sleep "$interval"
	done
}

case "$1" in
	daemon) daemon_loop ;;
	check) check_online ;;
	auth) do_auth ;;
	reload) /etc/init.d/campus-auth-guardian reload ;;
	*) echo "Usage: $0 {daemon|check|auth|reload}" ; exit 1 ;;
esac

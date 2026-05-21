#!/bin/sh

LOG="/tmp/campus_auth_guardian.log"

uci_get() {
	uci -q get "campus-auth-guardian.main.$1"
}

uci_get_account() {
	local section value
	section="$(uci_get active_account)"
	[ -n "$section" ] || return 1
	uci -q show "campus-auth-guardian.$section" >/dev/null 2>&1 || return 1
	value="$(uci -q get "campus-auth-guardian.$section.$1")" || return 1
	printf '%s' "$value"
}

uci_get_account_or_main() {
	local value
	value="$(uci_get_account "$1")" && {
		printf '%s' "$value"
		return 0
	}
	uci_get "$1"
}

uci_get_default() {
	local value
	value="$(uci_get "$1")"
	printf '%s' "${value:-$2}"
}

uci_get_account_default() {
	local value
	value="$(uci_get_account_or_main "$1")"
	printf '%s' "${value:-$2}"
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
	elif command -v uclient-fetch >/dev/null 2>&1; then
		uclient-fetch -q -T 10 -O - "$url" 2>/dev/null
	else
		log "No HTTP client found: install curl or uclient-fetch"
		return 1
	fi
}

build_user_account() {
	local student_id operator_type operator_domain account_prefix
	student_id="$(uci_get_account_or_main student_id)"
	operator_type="$(uci_get_account_default operator_type unicom)"
	operator_domain="$(uci_get_account_or_main operator_domain)"
	account_prefix="$(uci_get_account_default account_prefix ',0,')"
	[ -n "$operator_domain" ] || operator_domain="$operator_type"

	if [ "$operator_domain" = "none" ]; then
		printf '%s%s' "$account_prefix" "$student_id"
	else
		printf '%s%s@%s' "$account_prefix" "$student_id" "$operator_domain"
	fi
}

build_auth_url() {
	local auth_url account password fixed_ip callback login_method
	local wlan_user_ipv6 wlan_user_mac wlan_ac_ip wlan_ac_name
	local js_version terminal_type auth_version lang extra url
	auth_url="$(uci_get_default auth_url 'http://10.10.102.50:801/eportal/portal/login')"
	account="$(build_user_account)"
	password="$(uci_get_account_or_main user_password)"
	fixed_ip="$(uci_get_account_or_main fixed_ip)"
	callback="$(uci_get_default callback dr1005)"
	login_method="$(uci_get_default login_method 1)"
	wlan_user_ipv6="$(uci_get wlan_user_ipv6)"
	wlan_user_mac="$(uci_get_default wlan_user_mac 000000000000)"
	wlan_ac_ip="$(uci_get wlan_ac_ip)"
	wlan_ac_name="$(uci_get wlan_ac_name)"
	js_version="$(uci_get_default js_version 4.1.3)"
	terminal_type="$(uci_get_default terminal_type 1)"
	auth_version="$(uci_get_default auth_version 3015)"
	lang="$(uci_get_default lang zh-cn)"
	extra="$(uci_get_default auth_extra_params 'lang=zh')"

	url="$(printf '%s?callback=%s&login_method=%s&user_account=%s&user_password=%s&wlan_user_ip=%s&wlan_user_ipv6=%s&wlan_user_mac=%s&wlan_ac_ip=%s&wlan_ac_name=%s&jsVersion=%s&terminal_type=%s&lang=%s&v=%s' \
		"$auth_url" \
		"$(urlencode "$callback")" \
		"$(urlencode "$login_method")" \
		"$(urlencode "$account")" \
		"$(urlencode "$password")" \
		"$(urlencode "$fixed_ip")" \
		"$(urlencode "$wlan_user_ipv6")" \
		"$(urlencode "$wlan_user_mac")" \
		"$(urlencode "$wlan_ac_ip")" \
		"$(urlencode "$wlan_ac_name")" \
		"$(urlencode "$js_version")" \
		"$(urlencode "$terminal_type")" \
		"$(urlencode "$lang")" \
		"$(urlencode "$auth_version")")"

	if [ -n "$extra" ]; then
		case "$extra" in
			\&*) url="${url}${extra}" ;;
			*) url="${url}&${extra}" ;;
		esac
	fi

	printf '%s' "$url"
}

contains() {
	[ -n "$2" ] || return 1
	case "$1" in
		*"$2"*) return 0 ;;
		*) return 1 ;;
	esac
}

check_online() {
	local url body online_keyword portal_keyword
	url="$(uci_get_default check_url 'http://10.10.102.50:801/eportal/portal/online_list?user_account=&user_password=123&wlan_user_mac=000000000000&wlan_user_ip=')"
	online_keyword="$(uci_get_default online_keyword '获取用户在线信息成功')"
	portal_keyword="$(uci_get_default portal_keyword eportal)"
	body="$(http_get "$url")" || return 1

	if contains "$body" "$online_keyword"; then
		log "Network check: online keyword reports connected"
		return 0
	fi

	case "$body" in
		*'"result":1'*online_session*)
			log "Network check: online_list reports connected"
			return 0
			;;
	esac

	if contains "$body" "$portal_keyword"; then
		log "Network check: portal keyword"
		return 2
	fi

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

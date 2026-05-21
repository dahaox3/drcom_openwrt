# Campus Auth Guardian Handoff

## Current state

This repository contains an ImmortalWrt/OpenWrt package set for campus portal authentication.

### Packages

- `campus-auth-guardian`
  - backend shell script
  - UCI config
  - procd init script
- `luci-app-campus-auth-guardian`
  - LuCI UI
  - menu ACL
  - rpcd ACL

## Behavior

### Auth flow

- Builds the auth URL with the minimal working form:
  - `user_account=,0,<student_id>@<operator>`
  - `user_password=<password>`
  - `wlan_user_ip=` may stay blank
- `fixed_ip` is optional.
  - if empty, the script sends blank `wlan_user_ip`
  - this matches the user's working browser request

### Connectivity check

The script uses OR logic:

1. legacy captive-portal detection
2. `online_list` response contains `获取用户在线信息成功`

If either path says online, the network is treated as reachable.

## Important files

- `package/campus-auth-guardian/Makefile`
- `package/campus-auth-guardian/files/usr/bin/campus-auth-guardian.sh`
- `package/campus-auth-guardian/files/etc/config/campus-auth-guardian`
- `package/campus-auth-guardian/files/etc/init.d/campus-auth-guardian`
- `package/luci-app-campus-auth-guardian/Makefile`
- `package/luci-app-campus-auth-guardian/htdocs/luci-static/resources/view/campus-auth-guardian.js`
- `package/luci-app-campus-auth-guardian/root/usr/share/luci/menu.d/luci-app-campus-auth-guardian.json`
- `package/luci-app-campus-auth-guardian/root/usr/share/rpcd/acl.d/luci-app-campus-auth-guardian.json`
- `build-ipk.ps1`

## Build notes

- Windows-based IPK packing was attempted and then abandoned as unreliable for `opkg`.
- The next build path should be Linux-based:
  - Ubuntu
  - WSL2
  - OpenWrt SDK / ImmortalWrt SDK
- Package target architecture: `aarch64_cortex-a53`
- The package itself is script-only, so it should still build as `Architecture: all` in a standard SDK flow.

## Current caveats

- The repository has not yet been rebuilt in the OpenWrt SDK.
- The `.ipk` files generated on Windows should be treated as discardable build artifacts.
- The next agent should verify package installability by building inside the SDK instead of trusting the Windows packer.

## Suggested next step

Clone this repo on Ubuntu, import the package tree into an OpenWrt SDK matching the target firmware, and build the `.ipk` using the native package system.


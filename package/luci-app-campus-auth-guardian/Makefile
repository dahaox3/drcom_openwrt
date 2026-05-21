include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-campus-auth-guardian
PKG_VERSION:=1.0.0
PKG_RELEASE:=4

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Codex

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-campus-auth-guardian
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=校园网认证守护 LuCI 界面
  PKGARCH:=all
  EXTRA_DEPENDS:=campus-auth-guardian, luci-base
endef

define Package/luci-app-campus-auth-guardian/description
  校园网认证守护的 LuCI 配置界面。
endef

define Build/Compile
endef

define Package/luci-app-campus-auth-guardian/install
	$(INSTALL_DIR) $(1)/www
	$(CP) ./htdocs/* $(1)/www/
	$(INSTALL_DIR) $(1)/
	$(CP) ./root/* $(1)/
endef

define Package/luci-app-campus-auth-guardian/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	rm -f /tmp/luci-indexcache.*
	rm -rf /tmp/luci-modulecache/
	killall -HUP rpcd 2>/dev/null
	exit 0
}
endef

$(eval $(call BuildPackage,luci-app-campus-auth-guardian))

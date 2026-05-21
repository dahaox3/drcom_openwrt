include $(TOPDIR)/rules.mk

PKG_NAME:=campus-auth-guardian
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Codex

include $(INCLUDE_DIR)/package.mk

define Package/campus-auth-guardian
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Campus Auth Guardian backend
  DEPENDS:=+curl +uclient-fetch
  PKGARCH:=all
endef

define Package/campus-auth-guardian/description
  Campus portal authentication daemon and helper scripts for ImmortalWrt.
endef

define Build/Compile
endef

define Package/campus-auth-guardian/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/etc/config/campus-auth-guardian $(1)/etc/config/campus-auth-guardian
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/campus-auth-guardian $(1)/etc/init.d/campus-auth-guardian
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/campus-auth-guardian.sh $(1)/usr/bin/campus-auth-guardian.sh
endef

$(eval $(call BuildPackage,campus-auth-guardian))

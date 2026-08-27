include $(TOPDIR)/rules.mk

PKG_NAME:=owrt-doctor
PKG_VERSION:=0.1.1
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=AbeyyN

include $(INCLUDE_DIR)/package.mk

define Package/owrt-doctor
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Privacy-first diagnostics and support bundles for OpenWrt
  URL:=https://github.com/AbeyyN/owrt-doctor
  DEPENDS:=+ubus +uci
endef

define Package/owrt-doctor/description
 A lightweight, extensible OpenWrt diagnostics utility with health checks,
 privacy-focused redaction and local support bundle generation.
endef

define Build/Compile
endef

define Package/owrt-doctor/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/owrt-doctor $(1)/usr/bin/owrt-doctor

	$(INSTALL_DIR) $(1)/usr/lib/owrt-doctor/checks.d
	$(INSTALL_BIN) ./files/usr/lib/owrt-doctor/checks.d/*.sh $(1)/usr/lib/owrt-doctor/checks.d/
endef

$(eval $(call BuildPackage,owrt-doctor))

include $(TOPDIR)/rules.mk

PKG_NAME    := reaction
PKG_VERSION := 2.3.0
PKG_RELEASE := 1

PKG_BUILD_DIR  := $(BUILD_DIR)/$(PKG_NAME)-v$(PKG_VERSION)
PKG_SOURCE     := $(PKG_NAME)-v$(PKG_VERSION).tar.gz
PKG_SOURCE_URL := https://framagit.org/ppom/reaction/-/archive/v$(PKG_VERSION)
PKG_HASH       := 8068d9124e5b77d26573e106c1d3c092f02314e1bb44b72f1a73310c3c3bfa05

PKG_MAINTAINER    := Christopher Söllinger <christopher.soellinger@gmail.com>
PKG_LICENSE       := AGPLv3
PKG_LICENSE_FILES := LICENSE

PKG_BUILD_DEPENDS:=rust/host
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/rust/rust-package.mk

define Package/$(PKG_NAME)
	SECTION  := utils
	CATEGORY := Utilities
	TITLE    := A daemon that scans program outputs for repeated patterns, and takes action.
	URL      := https://reaction.ppom.me/
	DEPENDS  := $(RUST_ARCH_DEPENDS)
endef

define Package/$(PKG_NAME)/description
	A daemon that scans program outputs for repeated patterns, and takes action.
	A common usage is to scan ssh and webserver logs, and to ban hosts that cause multiple authentication errors.
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/target/*-linux-*/release/reaction $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/reaction.init $(1)/etc/init.d/reaction

	$(INSTALL_DIR) $(1)/etc/reaction
	$(INSTALL_CONF) ./files/etc/reaction/.lib.jsonnet $(1)/etc/reaction/.lib.jsonnet
	$(INSTALL_CONF) ./files/etc/reaction/config.jsonnet $(1)/etc/reaction/config.jsonnet
	$(INSTALL_CONF) ./files/etc/reaction/streams.jsonnet $(1)/etc/reaction/streams.jsonnet
endef

$(eval $(call RustBinPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)))

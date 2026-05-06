include $(TOPDIR)/rules.mk

PKG_NAME    := reaction
PKG_VERSION := 2.3.1
PKG_RELEASE := 1

PKG_BUILD_DIR  := $(BUILD_DIR)/$(PKG_NAME)-v$(PKG_VERSION)
PKG_SOURCE     := $(PKG_NAME)-v$(PKG_VERSION).tar.gz
PKG_SOURCE_URL := https://framagit.org/ppom/reaction/-/archive/v$(PKG_VERSION)
PKG_HASH       := 5041c97750531779a17756640f876992a930730f1590078aa0e2533195716b1f

PKG_MAINTAINER    := Christopher Söllinger <christopher.soellinger@gmail.com>
PKG_LICENSE       := AGPLv3
PKG_LICENSE_FILES := LICENSE

PKG_BUILD_DEPENDS:=rust/host libnftnl libmnl gmp jansson iptables ipset
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/rust/rust-package.mk

export GMP_LIB_DIR := $(STAGING_DIR)/usr/lib
export NFTABLES_INCLUDE_DIR := $(STAGING_DIR)/usr/include
export LIBCLANG_PATH := /usr/lib/llvm-11/lib
export BINDGEN_EXTRA_CLANG_ARGS := -resource-dir=/usr/lib/llvm-11/lib/clang/11.0.1 -I$(STAGING_DIR)/usr/include

define Package/reaction/Default
  SECTION  := utils
  CATEGORY := Utilities
  URL      := https://reaction.ppom.me/
endef

define Package/$(PKG_NAME)
  $(call Package/reaction/Default)
  TITLE   := A daemon that scans program outputs for repeated patterns, and takes action
  DEPENDS := $(RUST_ARCH_DEPENDS)
endef

define Package/$(PKG_NAME)/description
  A daemon that scans program outputs for repeated patterns, and takes action.
  A common usage is to scan ssh and webserver logs, and to ban hosts that cause
  multiple authentication errors.
endef

define Package/reaction-plugin-nftables
  $(call Package/reaction/Default)
  TITLE   := reaction plugin: nftables (ban hosts via nftables)
  DEPENDS := +reaction +nftables
endef

define Package/reaction-plugin-ipset
  $(call Package/reaction/Default)
  TITLE   := reaction plugin: ipset (ban hosts via ipset)
  DEPENDS := +reaction +ipset
endef

define Package/reaction-plugin-cluster
  $(call Package/reaction/Default)
  TITLE   := reaction plugin: cluster (sync bans across reaction instances)
  DEPENDS := +reaction
endef

define Package/reaction-plugin-virtual
  $(call Package/reaction/Default)
  TITLE   := reaction plugin: virtual (example/test plugin, no real action)
  DEPENDS := +reaction
endef

define Build/Compile
	$(call Build/Compile/Cargo,)
	$(call Build/Compile/Cargo,plugins/reaction-plugin-nftables)
	$(call Build/Compile/Cargo,plugins/reaction-plugin-ipset)
	$(call Build/Compile/Cargo,plugins/reaction-plugin-cluster)
	$(call Build/Compile/Cargo,plugins/reaction-plugin-virtual)
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

define Package/reaction-plugin-nftables/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/target/*-linux-*/release/reaction-plugin-nftables $(1)/usr/bin/
endef

define Package/reaction-plugin-ipset/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/target/*-linux-*/release/reaction-plugin-ipset $(1)/usr/bin/
endef

define Package/reaction-plugin-cluster/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/target/*-linux-*/release/reaction-plugin-cluster $(1)/usr/bin/
endef

define Package/reaction-plugin-virtual/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/target/*-linux-*/release/reaction-plugin-virtual $(1)/usr/bin/
endef

$(eval $(call RustBinPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,reaction-plugin-nftables))
$(eval $(call BuildPackage,reaction-plugin-ipset))
$(eval $(call BuildPackage,reaction-plugin-cluster))
$(eval $(call BuildPackage,reaction-plugin-virtual))

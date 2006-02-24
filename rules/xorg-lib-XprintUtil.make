# -*-makefile-*-
# $Id: template 4565 2006-02-10 14:23:10Z mkl $
#
# Copyright (C) 2006 by Erwin Rol
#          
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_XORG_LIB_XPRINTUTIL) += xorg-lib-XprintUtil

#
# Paths and names
#
XORG_LIB_XPRINTUTIL_VERSION	:= 1.0.1
XORG_LIB_XPRINTUTIL		:= libXprintUtil-X11R7.0-$(XORG_LIB_XPRINTUTIL_VERSION)
XORG_LIB_XPRINTUTIL_SUFFIX	:= tar.bz2
XORG_LIB_XPRINTUTIL_URL		:= ftp://ftp.gwdg.de/pub/x11/x.org/pub/X11R7.0/src/lib//$(XORG_LIB_XPRINTUTIL).$(XORG_LIB_XPRINTUTIL_SUFFIX)
XORG_LIB_XPRINTUTIL_SOURCE	:= $(SRCDIR)/$(XORG_LIB_XPRINTUTIL).$(XORG_LIB_XPRINTUTIL_SUFFIX)
XORG_LIB_XPRINTUTIL_DIR		:= $(BUILDDIR)/$(XORG_LIB_XPRINTUTIL)

-include $(call package_depfile)

# ----------------------------------------------------------------------------
# Get
# ----------------------------------------------------------------------------

xorg-lib-XprintUtil_get: $(STATEDIR)/xorg-lib-XprintUtil.get

$(STATEDIR)/xorg-lib-XprintUtil.get: $(xorg-lib-XprintUtil_get_deps_default)
	@$(call targetinfo, $@)
	@$(call touch, $@)

$(XORG_LIB_XPRINTUTIL_SOURCE):
	@$(call targetinfo, $@)
	@$(call get, $(XORG_LIB_XPRINTUTIL_URL))

# ----------------------------------------------------------------------------
# Extract
# ----------------------------------------------------------------------------

xorg-lib-XprintUtil_extract: $(STATEDIR)/xorg-lib-XprintUtil.extract

$(STATEDIR)/xorg-lib-XprintUtil.extract: $(xorg-lib-XprintUtil_extract_deps_default)
	@$(call targetinfo, $@)
	@$(call clean, $(XORG_LIB_XPRINTUTIL_DIR))
	@$(call extract, $(XORG_LIB_XPRINTUTIL_SOURCE))
	@$(call patchin, $(XORG_LIB_XPRINTUTIL))
	@$(call touch, $@)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

xorg-lib-XprintUtil_prepare: $(STATEDIR)/xorg-lib-XprintUtil.prepare

XORG_LIB_XPRINTUTIL_PATH	:=  PATH=$(CROSS_PATH)
XORG_LIB_XPRINTUTIL_ENV 	:=  $(CROSS_ENV)

#
# autoconf
#
XORG_LIB_XPRINTUTIL_AUTOCONF := $(CROSS_AUTOCONF_USR)

$(STATEDIR)/xorg-lib-XprintUtil.prepare: $(xorg-lib-XprintUtil_prepare_deps_default)
	@$(call targetinfo, $@)
	@$(call clean, $(XORG_LIB_XPRINTUTIL_DIR)/config.cache)
	cd $(XORG_LIB_XPRINTUTIL_DIR) && \
		$(XORG_LIB_XPRINTUTIL_PATH) $(XORG_LIB_XPRINTUTIL_ENV) \
		./configure $(XORG_LIB_XPRINTUTIL_AUTOCONF)
	@$(call touch, $@)

# ----------------------------------------------------------------------------
# Compile
# ----------------------------------------------------------------------------

xorg-lib-XprintUtil_compile: $(STATEDIR)/xorg-lib-XprintUtil.compile

$(STATEDIR)/xorg-lib-XprintUtil.compile: $(xorg-lib-XprintUtil_compile_deps_default)
	@$(call targetinfo, $@)
	cd $(XORG_LIB_XPRINTUTIL_DIR) && $(XORG_LIB_XPRINTUTIL_PATH) make
	@$(call touch, $@)

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

xorg-lib-XprintUtil_install: $(STATEDIR)/xorg-lib-XprintUtil.install

$(STATEDIR)/xorg-lib-XprintUtil.install: $(xorg-lib-XprintUtil_install_deps_default)
	@$(call targetinfo, $@)
	@$(call install, XORG_LIB_XPRINTUTIL)
	@$(call touch, $@)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

xorg-lib-XprintUtil_targetinstall: $(STATEDIR)/xorg-lib-XprintUtil.targetinstall

$(STATEDIR)/xorg-lib-XprintUtil.targetinstall: $(xorg-lib-XprintUtil_targetinstall_deps_default)
	@$(call targetinfo, $@)

	@$(call install_init,default)
	@$(call install_fixup,PACKAGE,xorg-lib-xprintutil)
	@$(call install_fixup,PRIORITY,optional)
	@$(call install_fixup,VERSION,$(XORG_LIB_XPRINTUTIL_VERSION))
	@$(call install_fixup,SECTION,base)
	@$(call install_fixup,AUTHOR,"Erwin Rol <ero\@pengutronix.de>")
	@$(call install_fixup,DEPENDS,)
	@$(call install_fixup,DESCRIPTION,missing)

#FIXME

	@$(call install_finish)

	@$(call touch, $@)

# ----------------------------------------------------------------------------
# Clean
# ----------------------------------------------------------------------------

xorg-lib-XprintUtil_clean:
	rm -rf $(STATEDIR)/xorg-lib-XprintUtil.*
	rm -rf $(IMAGEDIR)/xorg-lib-XprintUtil_*
	rm -rf $(XORG_LIB_XPRINTUTIL_DIR)

# vim: syntax=make

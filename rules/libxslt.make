# -*-makefile-*-
# $Id: template 2878 2005-07-03 17:54:38Z rsc $
#
# Copyright (C) 2005 by Robert Schwebel
#          
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
ifdef PTXCONF_LIBXSLT
PACKAGES += libxslt
endif

#
# Paths and names
#
LIBXSLT_VERSION	= 1.1.14
LIBXSLT		= libxslt-$(LIBXSLT_VERSION)
LIBXSLT_SUFFIX	= tar.gz
LIBXSLT_URL	= ftp://xmlsoft.org/$(LIBXSLT).$(LIBXSLT_SUFFIX)
LIBXSLT_SOURCE	= $(SRCDIR)/$(LIBXSLT).$(LIBXSLT_SUFFIX)
LIBXSLT_DIR	= $(BUILDDIR)/$(LIBXSLT)

# ----------------------------------------------------------------------------
# Get
# ----------------------------------------------------------------------------

libxslt_get: $(STATEDIR)/libxslt.get

libxslt_get_deps = $(LIBXSLT_SOURCE)

$(STATEDIR)/libxslt.get: $(libxslt_get_deps)
	@$(call targetinfo, $@)
	@$(call get_patches, $(LIBXSLT))
	touch $@

$(LIBXSLT_SOURCE):
	@$(call targetinfo, $@)
	@$(call get, $(LIBXSLT_URL))

# ----------------------------------------------------------------------------
# Extract
# ----------------------------------------------------------------------------

libxslt_extract: $(STATEDIR)/libxslt.extract

libxslt_extract_deps = $(STATEDIR)/libxslt.get

$(STATEDIR)/libxslt.extract: $(libxslt_extract_deps)
	@$(call targetinfo, $@)
	@$(call clean, $(LIBXSLT_DIR))
	@$(call extract, $(LIBXSLT_SOURCE))
	@$(call patchin, $(LIBXSLT))
	touch $@

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

libxslt_prepare: $(STATEDIR)/libxslt.prepare

#
# dependencies
#
libxslt_prepare_deps = \
	$(STATEDIR)/libxslt.extract \
	$(STATEDIR)/virtual-xchain.install

LIBXSLT_PATH	=  PATH=$(CROSS_PATH)
LIBXSLT_ENV 	=  $(CROSS_ENV)
#LIBXSLT_ENV	+= PKG_CONFIG_PATH=$(CROSS_LIB_DIR)/lib/pkgconfig
#LIBXSLT_ENV	+=

#
# autoconf
#
LIBXSLT_AUTOCONF =  $(CROSS_AUTOCONF)
LIBXSLT_AUTOCONF += --prefix=$(CROSS_LIB_DIR)

$(STATEDIR)/libxslt.prepare: $(libxslt_prepare_deps)
	@$(call targetinfo, $@)
	@$(call clean, $(LIBXSLT_DIR)/config.cache)
	cd $(LIBXSLT_DIR) && \
		$(LIBXSLT_PATH) $(LIBXSLT_ENV) \
		./configure $(LIBXSLT_AUTOCONF)
	touch $@

# ----------------------------------------------------------------------------
# Compile
# ----------------------------------------------------------------------------

libxslt_compile: $(STATEDIR)/libxslt.compile

libxslt_compile_deps = $(STATEDIR)/libxslt.prepare

$(STATEDIR)/libxslt.compile: $(libxslt_compile_deps)
	@$(call targetinfo, $@)
	cd $(LIBXSLT_DIR) && $(LIBXSLT_ENV) $(LIBXSLT_PATH) make
	touch $@

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

libxslt_install: $(STATEDIR)/libxslt.install

$(STATEDIR)/libxslt.install: $(STATEDIR)/libxslt.compile
	@$(call targetinfo, $@)

	cd $(LIBXSLT_DIR) && $(LIBXSLT_ENV) $(LIBXSLT_PATH) make install

	# FIXME: this probably has to be fixed upstream!
	# libxslt installs xslt-config to wrong path. 
	install $(LIBXSLT_DIR)/xslt-config $(PTXCONF_PREFIX)/bin/

	touch $@

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

libxslt_targetinstall: $(STATEDIR)/libxslt.targetinstall

libxslt_targetinstall_deps = $(STATEDIR)/libxslt.compile

$(STATEDIR)/libxslt.targetinstall: $(libxslt_targetinstall_deps)
	@$(call targetinfo, $@)

	@$(call install_init,default)
	@$(call install_fixup,PACKAGE,libxslt)
	@$(call install_fixup,PRIORITY,optional)
	@$(call install_fixup,VERSION,$(LIBXSLT_VERSION))
	@$(call install_fixup,SECTION,base)
	@$(call install_fixup,AUTHOR,"Robert Schwebel <r.schwebel\@pengutronix.de>")
	@$(call install_fixup,DEPENDS,)
	@$(call install_fixup,DESCRIPTION,missing)

	@$(call install_copy, 0, 0, 0755, \
		$(LIBXSLT_DIR)/libxslt/.libs/libxslt.so.1.1.14, \
		/usr/lib/libxslt.so.1.1.14)
	@$(call install_link, libxslt.so.1.1.14, /usr/lib/libxslt.so.1)
	@$(call install_link, libxslt.so.1.1.14, /usr/lib/libxslt.so)

	@$(call install_finish)

	touch $@

# ----------------------------------------------------------------------------
# Clean
# ----------------------------------------------------------------------------

libxslt_clean:
	rm -rf $(STATEDIR)/libxslt.*
	rm -rf $(IMAGEDIR)/libxslt_*
	rm -rf $(LIBXSLT_DIR)

# vim: syntax=make

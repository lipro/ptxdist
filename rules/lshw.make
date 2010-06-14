# -*-makefile-*-
#
# Copyright (C) 2010 by Bart vdr. Meulen <bartvdrmeulen@gmail.com>
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_LSHW) += lshw

#
# Paths and names
#
LSHW_VERSION	:= B.02.14
LSHW		:= lshw-$(LSHW_VERSION)
LSHW_SUFFIX	:= tar.gz
LSHW_URL	:= http://www.ezix.org/software/files/$(LSHW).$(LSHW_SUFFIX)
LSHW_SOURCE	:= $(SRCDIR)/$(LSHW).$(LSHW_SUFFIX)
LSHW_DIR	:= $(BUILDDIR)/$(LSHW)
LSHW_LICENSE	:= GPLv2

# ----------------------------------------------------------------------------
# Get
# ----------------------------------------------------------------------------

$(LSHW_SOURCE):
	@$(call targetinfo)
	@$(call get, LSHW)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

LSHW_CONF_TOOL		:= NO
LSHW_MAKE_OPT		:= $(CROSS_ENV) all
LSHW_INSTALL_OPT	:= $(CROSS_ENV) install
ifdef PTXCONF_LSHW_GUI
LSHW_MAKE_OPT		+= gui
LSHW_INSTALL_OPT	+= install-gui
endif

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/lshw.targetinstall:
	@$(call targetinfo)

	@$(call install_init,  lshw)
	@$(call install_fixup, lshw,PACKAGE,lshw)
	@$(call install_fixup, lshw,PRIORITY,optional)
	@$(call install_fixup, lshw,VERSION,$(LSHW_VERSION))
	@$(call install_fixup, lshw,SECTION,base)
	@$(call install_fixup, lshw,AUTHOR,"Bart vdr. Meulen <bartvdrmeulen@gmail.com>")
	@$(call install_fixup, lshw,DEPENDS,)
	@$(call install_fixup, lshw,DESCRIPTION,missing)

	@$(call install_copy, lshw, 0, 0, 0755, -, /usr/sbin/lshw)

	@$(call install_copy, lshw, 0, 0, 0755, /usr/share/lshw)
	@$(call install_copy, lshw, 0, 0, 0644, -, /usr/share/lshw/pci.ids)
	@$(call install_copy, lshw, 0, 0, 0644, -, /usr/share/lshw/usb.ids)
	@$(call install_copy, lshw, 0, 0, 0644, -, /usr/share/lshw/oui.txt)
	@$(call install_copy, lshw, 0, 0, 0644, -, /usr/share/lshw/manuf.txt)

ifdef PTXCONF_LSHW_GUI
	@$(call install_copy, lshw, 0, 0, 0755, -, /usr/sbin/gtk-lshw)

	@$(call install_copy, lshw, 0, 0, 0755, /usr/share/lshw/artwork)
	@cd $(LSHW_PKGDIR)/usr/share/lshw/artwork; \
	for file in * ; do \
		$(call install_copy, lshw, 0, 0, 0644, -, \
			/usr/share/lshw/artwork/$$file); \
	done
endif

	@$(call install_finish, lshw)
	@$(call touch)

# vim: syntax=make
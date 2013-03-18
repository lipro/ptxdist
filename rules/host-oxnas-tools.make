# -*-makefile-*-
#
# Copyright (C) 2013 by Stephan Linz <linz@li-pro.net>
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
HOST_PACKAGES-$(PTXCONF_HOST_OXNAS_TOOLS) += host-oxnas-tools

#
# Paths and names
#
HOST_OXNAS_TOOLS_VERSION:= 1.1.0
HOST_OXNAS_TOOLS_MD5	:= 1f34be571c8186e8963a30753863799e
HOST_OXNAS_TOOLS	:= oxnas-tools-$(HOST_OXNAS_TOOLS_VERSION)
HOST_OXNAS_TOOLS_SUFFIX	:= tar.bz2
HOST_OXNAS_TOOLS_URL	:= http://www.li-pro.de/_media/embedded/oxnas/tools/$(HOST_OXNAS_TOOLS).$(HOST_OXNAS_TOOLS_SUFFIX)
HOST_OXNAS_TOOLS_SOURCE	:= $(SRCDIR)/$(HOST_OXNAS_TOOLS).$(HOST_OXNAS_TOOLS_SUFFIX)
HOST_OXNAS_TOOLS_DIR	:= $(HOST_BUILDDIR)/$(HOST_OXNAS_TOOLS)

#
# autoconf
#
HOST_OXNAS_TOOLS_CONF_TOOL := autoconf

# vim: syntax=make

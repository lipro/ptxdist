# -*-makefile-*-
#
# Copyright (C) 2011 by Stephan Linz <linz@li-pro.net>
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

ifeq ($(PTXCONF_ARCH_MICROBLAZE),y)

ifeq ($(PTXCONF_ARCH_MICROBLAZE_HAVE_XLBSP),y)
$(STATEDIR)/u-boot.prepare: $(STATEDIR)/u-boot.xlbsp
endif

ifeq ($(PTXCONF_ARCH_MICROBLAZE_HAVE_XLBSP),y)
$(STATEDIR)/kernel.prepare: $(STATEDIR)/kernel.xlbsp
endif

ifeq ($(PTXCONF_KERNEL_IMAGE_SIMPLE),y)
SEL_ROOTFS-$(PTXCONF_IMAGE_KERNEL) += $(IMAGEDIR)/linuximage.ub
endif

$(IMAGEDIR)/linuximage.ub: $(KERNEL_IMAGE_PATH_y).ub $(IMAGEDIR)/linuximage
	@echo -n "Creating '$(notdir $(@))' from '$(notdir $(<))'..."
	@install -m 644 "$(<)" "$(@)"
	@echo "done."

endif

$(STATEDIR)/%.xlbsp: $(STATEDIR)/%.extract
	@$(call targetinfo)
	@$(call xilinx/bsp, $(PTX_MAP_TO_PACKAGE_$(*)), $($(PTX_MAP_TO_PACKAGE_$(*))_DIR))
	@$(call touch)

xilinx/bsp = \
	$(call world/env, $(1)) \
	ptxd_make_xilinx_bsp

# vim: syntax=make

# -*-makefile-*-
#
# Copyright (C) 2013 by Stephan Linz <linz@li-pro.net>
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

ifdef PTXCONF_IMAGE_OXNASBLOB_U_BOOT

U_BOOT_PAYLOAD		:= $(U_BOOT_DIR)/u-boot
U_BOOT_PAYLOAD_TYPE	:= U-Boot
U_BOOT_PAYLOAD_NAME	:= U-Boot-$(U_BOOT_VERSION)

SEL_ROOTFS-$(PTXCONF_U_BOOT)	+= $(IMAGEDIR)/u-boot-oxnas.bin
SEL_ROOTFS-$(PTXCONF_U_BOOT)	+= $(IMAGEDIR)/u-boot-oxnas.srec
SEL_ROOTFS-$(PTXCONF_U_BOOT)	+= $(IMAGEDIR)/u-boot-oxnas.elf

$(U_BOOT_DIR)/u-boot-oxnas.bin \
$(U_BOOT_DIR)/u-boot-oxnas.srec \
$(U_BOOT_DIR)/u-boot-oxnas.elf: $(STATEDIR)/u-boot.oxnasblob

$(IMAGEDIR)/u-boot-oxnas.%: $(U_BOOT_DIR)/u-boot-oxnas.% $(STATEDIR)/u-boot.targetinstall
	@echo -n "Creating '$(notdir $(@))' from '$(notdir $(<))'..."
	@install -m 644 "$(<)" "$(@)"
	@echo "done."

ifdef PTXCONF_IMAGE_OXNASBLOB_SETUP_MBR
$(IMAGEDIR)/hd.img: $(IMAGEDIR)/u-boot-oxnas.bin
endif

endif

ifdef PTXCONF_IMAGE_OXNASBLOB_SETUP_KERNEL
$(IMAGEDIR)/hd.img: $(IMAGEDIR)/linuximage
endif

$(STATEDIR)/%.oxnasblob: $(STATEDIR)/%.compile
	@$(call targetinfo)
	@$(call plxtech/oxnasblob, $(PTX_MAP_TO_PACKAGE_$(*)), 			\
		$($(PTX_MAP_TO_PACKAGE_$(*))_DIR),				\
		$($(PTX_MAP_TO_PACKAGE_$(*))_PAYLOAD),				\
		$($(PTX_MAP_TO_PACKAGE_$(*))_PAYLOAD_TYPE),			\
		$($(PTX_MAP_TO_PACKAGE_$(*))_PAYLOAD_NAME))
	@$(call touch)

plxtech/oxnasblob = \
	$(call world/env, $(1))							\
	cd $(2) && $(CROSS_ENV)							\
		$(PTXCONF_SYSROOT_HOST)/bin/mkoxnasblob -t $(4) -n $(5) -o $(3)-oxnas $(3)

# vim: syntax=make

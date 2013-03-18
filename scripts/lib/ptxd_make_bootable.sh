#!/bin/bash
#
# Copyright (C) 2011 by Michael Olbrich <m.olbrich@pengutronix.de>
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# Make a disk image bootable. The bootloader is written to the MBR and
# the following sectors without touching the partition table.
#
# This will fail if the bootloader is too large for the free sectors.
#
# $1	the image to modify
# $2	number of free sectors at the start of the image
# $3	first part of the bootloader for the code area of the MBR
# $4	second part of the bootloader for sector 2..n
#
ptxd_make_dd_bootloader() {
    local image="$1"
    local bytes="$[$2 * 512]"
    local stage1="$3"
    local stage2="$4"
    local opt="conv=notrunc"
    local opt2="seek=1"

    if [ ! -w "${image}" ]; then
	ptxd_bailout "Cannot write image file '${stage1}'"
    fi
    if [ ! -r "${stage1}" ]; then
	ptxd_bailout "Cannot open stage1 file '${stage1}'"
    fi
    if [ -z "${stage2}" ]; then
	stage2="${stage1}"
	opt2="${opt2} skip=1"
    elif [ ! -r "${stage2}" ]; then
	ptxd_bailout "Cannot open stage2 file '${stage1}'"
    else
	bytes="$[$bytes - 512]"
    fi
    local needed="$(stat --printf="%s" "${stage2}")"
    if [ "${needed}" -gt "${bytes}" ]; then
	ptxd_bailout "Not enough space to write stage2: available: ${bytes} needed: ${needed}"
    fi

    dd if="${stage1}" of="${image}" ${opt} bs=446 count=1 2>/dev/null &&
    dd if="${stage2}" of="${image}" ${opt} ${opt2} bs=512 2>/dev/null
}
export -f ptxd_make_dd_bootloader

#
# Install barebox on x86 systems.
# barebox is installed in the first sector and at the end of the free space.
# The space between is used for the barebox environment.
#
# $1	the image to modify
# $2	number of free sectors at the start of the image
# $3	the barebox image
#
ptxd_make_x86_boot_barebox() {
    local image="$1"
    local sectors="$2"
    local barebox="$3"
    local needed="$(stat --printf="%s" "${barebox}")"
    # round to the next sector
    needed=$(((${needed}-1)/512+1))
    if [ "${needed}" -gt "${sectors}" ]; then
	ptxd_bailout "Not enough space to write barebox: available: ${sectors} needed: ${needed} (sectors)"
    fi
    setupmbr -s $((${sectors}-${needed})) -m "${barebox}" -d "${image}"
}
export -f ptxd_make_x86_boot_barebox

#
# OXNAS general space checkup in boot area -- the space before
# first partition
#
# $1	number of needed sectors (to check against ...)
# $2	number of free sectors (at the start of the image)
# $3	offset of primary sectors (where needed sectors can be allocated)
# $4	number of primary free sectors
# $5	offset of secondary sectors (where needed sectors can be allocated)
# $6	number of secondary free sectors
#
ptxd_make_oxnas_chksp() {
    local needed="$1"
    local sectors="$2"
    local pri_offs="$3"
    local pri_sects="$4"
    local sec_offs="$5"
    local sec_sects="$6"
    local pri_last sec_last
    if [ "${needed}" -gt "${sectors}" ]; then
	ptxd_bailout "Not enough space to write OXNASBLOB: available: ${sectors} needed: ${needed} (sectors)"
    fi
    if [ "${needed}" -gt "${pri_sects}" ]; then
	ptxd_bailout "Not enough space to write primary OXNASBLOB: available: ${pri_sects} needed: ${needed} (sectors)"
    fi
    if [ "${needed}" -gt "${sec_sects}" ]; then
	ptxd_bailout "Not enough space to write secondary OXNASBLOB: available: ${sec_sects} needed: ${needed} (sectors)"
    fi
    # calculate last sectors
    pri_last=$((${pri_offs}+${needed}))
    sec_last=$((${sec_offs}+${needed}))
    if [ "${pri_last}" -gt "${sectors}" ]; then
	ptxd_bailout "Not enough space to write primary OXNASBLOB: available: ${sectors} needed: ${pri_last} (sectors)"
    fi
    if [ "${sec_last}" -gt "${sectors}" ]; then
	ptxd_bailout "Not enough space to write secondary OXNASBLOB: available: ${sectors} needed: ${sec_last} (sectors)"
    fi
}
export -f ptxd_make_oxnas_chksp

#
# Make a disk image bootable for OXNAS systems.
# The bootloader, mainly U-Boot, is written as an OXNASBLOB to the
# primary sectors and the secondary sectors without touching the
# partition table.
#
# $1	the image to modify
# $2	number of free sectors at the start of the image
# $3	the bootloader image
#
ptxd_make_oxnas_boot() {
    local image="$1"
    local sectors="$2"
    local bootloader="$3"
    local needed="$(stat --printf="%s" "${bootloader}")"
    local pri_offs="$(ptxd_get_ptxconf PTXCONF_IMAGE_OXNASBLOB_STAGE1_PRISECT_OFFS)"
    local pri_sects="$(ptxd_get_ptxconf PTXCONF_IMAGE_OXNASBLOB_STAGE1_PRISECT_SIZE)"
    local sec_offs="$(ptxd_get_ptxconf PTXCONF_IMAGE_OXNASBLOB_STAGE1_SECSECT_OFFS)"
    local sec_sects="$(ptxd_get_ptxconf PTXCONF_IMAGE_OXNASBLOB_STAGE1_SECSECT_SIZE)"
    # round to the next sector
    needed=$(((${needed}-1)/512+1))
    ptxd_make_oxnas_chksp "${needed}" "${sectors}" "${pri_offs}" "${pri_sects}" "${sec_offs}" "${sec_sects}"
    setupoxnasmbr -p -b ${pri_offs} -l ${pri_sects} -d "${image}" "${bootloader}"
    setupoxnasmbr -s -b ${sec_offs} -l ${sec_sects} -d "${image}" "${bootloader}"
}
export -f ptxd_make_oxnas_boot

#
# Install kernel on OXNAS systems.
# Write the kernel image into the primary and the secondary OXNAS boot area.
#
# $1	the image to modify
# $2	number of free sectors at the start of the image
# $3	the kernel image
#
ptxd_make_oxnas_write_kernel() {
    local image="$1"
    local sectors="$2"
    local kernel="$3"
    local needed="$(stat --printf="%s" "${kernel}")"
    local pri_offs="$(ptxd_get_ptxconf PTXCONF_IMAGE_OXNASBLOB_KERNEL_PRISECT_OFFS)"
    local pri_sects="$(ptxd_get_ptxconf PTXCONF_IMAGE_OXNASBLOB_KERNEL_PRISECT_SIZE)"
    local sec_offs="$(ptxd_get_ptxconf PTXCONF_IMAGE_OXNASBLOB_KERNEL_SECSECT_OFFS)"
    local sec_sects="$(ptxd_get_ptxconf PTXCONF_IMAGE_OXNASBLOB_KERNEL_SECSECT_SIZE)"
    local opt="conv=notrunc bs=512"
    local opt1="seek=${pri_offs} count=${pri_sects}"
    local opt2="seek=${sec_offs} count=${sec_sects}"
    # round to the next sector
    needed=$(((${needed}-1)/512+1))
    ptxd_make_oxnas_chksp "${needed}" "${sectors}" "${pri_offs}" "${pri_sects}" "${sec_offs}" "${sec_sects}"
    echo "OBA:${pri_sects}(${needed})@${pri_offs} (${opt1})"
    dd if="${kernel}" of="${image}" ${opt} ${opt1} 2>/dev/null
    echo "OBA:${sec_sects}(${needed})@${sec_offs} (${opt2})"
    dd if="${kernel}" of="${image}" ${opt} ${opt2} 2>/dev/null
}
export -f ptxd_make_oxnas_write_kernel

#
# Make a disk image bootable. What exactly happens depends on the selected
# platform options.
# This function will fail if the specified free space is not enough to
# install the bootloader.
#
# $1	the image to modify
# $2	number of free sectors at the start of the image
#
ptxd_make_bootable() {
    local image="${1}"
    local sectors="${2}"
    local stage1 stage2

    if ptxd_get_ptxconf PTXCONF_GRUB > /dev/null; then
	echo
	echo "-----------------------------------"
	echo "Making the image bootable with grub"
	echo "-----------------------------------"
	ptxd_get_path ${PTXDIST_SYSROOT_TARGET}/usr/lib/grub/*/stage1 || return
	stage1="${ptxd_reply}"
	ptxd_get_path ${PTXDIST_SYSROOT_TARGET}/usr/lib/grub/*/stage2 || return
	stage2="${ptxd_reply}"
    elif ptxd_get_ptxconf PTXCONF_BAREBOX > /dev/null; then
	echo
	echo "--------------------------------------"
	echo "Making the image bootable with barebox"
	echo "--------------------------------------"
	stage1="${ptx_image_dir}/barebox-image"
	if ptxd_get_ptxconf PTXCONF_ARCH_X86 > /dev/null; then
	    ptxd_make_x86_boot_barebox "${image}" "${sectors}" "${stage1}"
	    return
	fi
    elif ptxd_get_ptxconf PTXCONF_IMAGE_OXNASBLOB_SETUP_MBR > /dev/null; then
	echo
	echo "-----------------------------------"
	echo "Making the image bootable for OXNAS"
	echo "-----------------------------------"
	if stage1="$(ptxd_get_ptxconf PTXCONF_IMAGE_OXNASBLOB_STAGE1)"; then
	    stage1="${ptx_image_dir}/${stage1}"
	    ptxd_make_oxnas_boot "${image}" "${sectors}" "${stage1}"
	    if ptxd_get_ptxconf PTXCONF_IMAGE_OXNASBLOB_SETUP_KERNEL > /dev/null; then
		echo
		echo "-------------------------------------"
		echo "Writing the kernel to OXNAS boot area"
		echo "-------------------------------------"
		osimage="${ptx_image_dir}/linuximage"
		ptxd_make_oxnas_write_kernel "${image}" "${sectors}" "${osimage}"
	    fi
	    return
	fi
    else
	# no bootloader to write
	return 0
    fi
    ptxd_make_dd_bootloader "${image}" "${sectors}" "${stage1}" "${stage2}"
}
export -f ptxd_make_bootable


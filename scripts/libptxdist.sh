#!/bin/bash

PTX_DEBUG=${PTX_DEBUG:="false"}
PTX_DIALOG="dialog --aspect 60"
PTX_DIALOG_HEIGHT=0
PTX_DIALOG_WIDTH=0


#
# ${1}	variable name in which string is returned
#       derefed serves as starting point for file selector
#       if empty $PWD is used
#
# return: selected file in variable ${1}
#
ptxd_dialog_fselect() {
	local ptr="${1}"
	local _select="${!1:-${PWD}}"

	exec 3>&1
	exec 4>&1
	while [ -d "${_select}" -o \! -e "${_select}" ]; do
		# FIXME take care about real links
		_select="$(readlink -f ${_select})"
		_select="${_select}/$(eval ${PTX_DIALOG} \
			--clear \
			--output-fd 3 \
			--title \"Please choose a ${ptr} file\" \
			--menu \"${_select}\" 0 0 0 \
			-- \
			\".\"  \"\<d\>\" \
			\"..\" \"\<d\>\" \
			$(find "${_select}/" -maxdepth 1 -mindepth 1    -type d -a \! -name ".*" -printf "\"%f\" \"<d>\"\n" | sort) \
			$(find "${_select}/" -maxdepth 1 -mindepth 1 \! -type d -a \! -name ".*" -printf "\"%f\" \"<f>\"\n" | sort) \
			3>&1 1>&4 \
			)" || return
	done
	exec 4>&-
	exec 3>&-

	eval "${ptr}"="${_select}"
}


_ptxd_dialog_box() {
	local dialog="${1}"
	shift

	local old_ifs="${IFS}"
	local IFS=''
	local msg
	msg="${*}"
	IFS="${old_ifs}"

	if [ -n "${PTX_MENU}" ]; then
		${PTX_DIALOG} \
			--no-collapse \
			--${dialog}box "${msg}" ${PTX_DIALOG_HEIGHT} ${PTX_DIALOG_WIDTH}
	else
		echo -e "${msg}\n" >&2
	fi
}

ptxd_dialog_infobox() {
	_ptxd_dialog_box info "${@}"
}

ptxd_dialog_msgbox() {
	_ptxd_dialog_box msg "${@}"
}

ptxd_dialog_yesno() {
	local old_ifs="${IFS}"
	local IFS=''
	local msg
	msg="${*}"
	IFS="${old_ifs}"

	local answer

	if [ -n "${PTX_MENU}" ]; then
		${PTX_DIALOG} \
			--yesno "${msg}" ${PTX_DIALOG_HEIGHT} ${PTX_DIALOG_WIDTH}
	else
		echo -e "${msg}"

		read answer
		if [ "${answer}" != "y" -a "${answer}" != "" ]; then
			echo "interrupting"
			echo
			return 1
		fi
	fi
}



#
# source a kconfig file
#
ptxd_source_kconfig() {
	local ret

	set -a
	source "${1}" 2> /dev/null
	ret=$?
	set +a

	return ${ret}
}
export -f ptxd_source_kconfig


#
# get a symbol from the kconfig file
#
# $1: the config file
# $2: the symbol name
#
# return:
# 1: symbol not found
# 2: symbol invalid
#
ptxd_get_kconfig() {
	local config="${1}"
	unset "${2}" 2>/dev/null || return 2

	if test -f "${config}"; then
		source "${config}" || \
		ptxd_bailout "unable to source '${config}' (maybe git conflict?)" 3
	fi
	if [ -n "${!2}" ]; then
		echo "${!2}"
		return
	fi
	return 1;
}
export -f ptxd_get_kconfig
#
# get a symbol from the ptx or platformconfig
#
# return:
# 1: symbol not found
# 2: symbol invalid
#
ptxd_get_ptxconf() {
	ptxd_get_kconfig "${PTXDIST_PLATFORMCONFIG}" "${1}" ||
	ptxd_get_kconfig "${PTXDIST_PTXCONFIG}" "${1}"
}
export -f ptxd_get_ptxconf



#
# migrate a config file
# look in PTX_MIGRATEDIR for a migration handler and call it
#
# $1	part identifier ("ptx", "platform", "collection", "board", "user")
#
ptxd_kconfig_migrate() {
	local part="${1}"
	local assistent="${PTX_MIGRATEDIR}/migrate_${part}"

	if [ \! -f "${assistent}" ]; then
		return 0
	fi

	cp -- ".config" ".config.old" || return
	sed -f "${assistent}" ".config.old" > ".config"
	retval=$?

	if [ $retval -ne 0 ]; then
		ptxd_dialog_msgbox "error: error occured during migration"
		return ${retval}
	fi

	if ! diff -u ".config.old" ".config" >/dev/null; then
		ptxd_dialog_msgbox "info: successfully migrated '${file_dotconfig}'"
	fi

	return ${retval}
}



#
# $1	what kind of config ("oldconfig", "menuconfig", "dep")
# $2	part identifier ("ptx", "platform", "collection", "board", "user")
# $...	optional parameters
#
ptxd_kconfig() {
	local config="${1}"
	local part="${2}"
	local copy_back="true"

	ptxd_kgen "${part}" || ptxd_bailout "error in kgen"

	local file_kconfig file_dotconfig

	case "${part}" in
	ptx)
		if [ -e "${PTXDIST_WORKSPACE}/Kconfig" ]; then
			file_kconfig="${PTXDIST_WORKSPACE}/Kconfig"
		else
			file_kconfig="config/Kconfig"
		fi
		file_dotconfig="${PTXDIST_PTXCONFIG}"
		;;
	platform)
		if [ -e "${PTXDIST_WORKSPACE}/platforms/Kconfig" ]; then
			file_kconfig="${PTXDIST_WORKSPACE}/platforms/Kconfig"
		else
			file_kconfig="${PTXDIST_TOPDIR}/platforms/Kconfig"
		fi
		file_dotconfig="${PTXDIST_PLATFORMCONFIG}"
		;;
	collection)
		ptxd_dgen || ptxd_bailout "error in dgen"

		#
		# "PTXDIST_COLLECTIONCONFIG" would overwrite
		# certain "m" packages with "y".
		#
		# but "menuconfig collection" works only on the
		# "m" packages, so unset PTXDIST_COLLECTIONCONFIG
		# here.
		#
		PTXDIST_COLLECTIONCONFIG="" ptxd_colgen || ptxd_bailout "error in colgen"

		file_kconfig="${PTXDIST_TOPDIR}/config/collection/Kconfig"
		file_dotconfig="${3}"
		;;
	board)
		if [ -e "${PTXDIST_WORKSPACE}/boardsetup/Kconfig" ]; then
			file_kconfig="${PTXDIST_WORKSPACE}/boardsetup/Kconfig"
		else
			file_kconfig="${PTXDIST_TOPDIR}/config/boardsetup/Kconfig"
		fi
		file_dotconfig="${PTXDIST_BOARDSETUP}"
		;;
	user)
		file_kconfig="${PTXDIST_TOPDIR}/config/setup/Kconfig"
		file_dotconfig="${PTXDIST_PTXRC}"
		;;
	*)
		echo
		echo "${PTXDIST_LOG_PROMPT}error: invalid use of '${FUNCNAME} ${@}'"
		echo
		exit 1
		;;
	esac

	local tmpdir
	tmpdir="$(mktemp -d "${PTXDIST_TEMPDIR}/kconfig.XXXXXX")" || ptxd_bailout "unable to create tmpdir"
	pushd "${tmpdir}" > /dev/null

	ln -sf "${PTXDIST_TOPDIR}/rules" &&
	ln -sf "${PTXDIST_TOPDIR}/config" &&
	ln -sf "${PTXDIST_TOPDIR}/platforms" &&
	ln -sf "${PTXDIST_WORKSPACE}" workspace &&
	ln -sf "${PTX_KGEN_DIR}/${part}" generated || return

	if [ -e "${file_dotconfig}" ]; then
		cp -- "${file_dotconfig}" ".config" || return
	fi

	local conf="${PTXDIST_TOPDIR}/scripts/kconfig/conf"
	local mconf="${PTXDIST_TOPDIR}/scripts/kconfig/mconf"
	local nconf="${PTXDIST_TOPDIR}/scripts/kconfig/nconf"

	export \
	    KCONFIG_NOTIMESTAMP="1" \
	    PROJECT="ptxdist" \
	    FULLVERSION="${PTXDIST_VERSION_FULL}"

	case "${config}" in
	menuconfig)
		"${mconf}" "${file_kconfig}"
		;;
	nconfig)
		"${nconf}" "${file_kconfig}"
		;;
	oldconfig)
		#
		# In silent mode, we cannot redirect input. So use
		# oldconfig instead of silentoldconfig if somebody
		# tries to automate us.
		#
		ptxd_kconfig_migrate "${part}" &&
		if tty -s; then
			"${conf}" --silentoldconfig "${file_kconfig}"
		else
			"${conf}" --oldconfig "${file_kconfig}"
		fi
		;;
	allmodconfig)
		"${conf}" --allmodconfig "${file_kconfig}"
		;;
	allyesconfig)
		"${conf}" --allyesconfig "${file_kconfig}"
		;;
	allnoconfig)
		"${conf}" --allnoconfig "${file_kconfig}"
		;;
	randconfig)
		"${conf}" --randconfig "${file_kconfig}"
		;;
	dep)
		copy_back="false"
		yes "" | "${conf}" --writedepend "${file_kconfig}" &&
		cp -- ".config" "${PTXDIST_DGEN_DIR}/${part}config"
		;;
	*)
		echo
		echo "${PTXDIST_LOG_PROMPT}error: invalid use of '${FUNCNAME} ${@}'"
		echo
		exit 1
		;;
	esac

	local retval=${?}
	unset \
	    KCONFIG_NOTIMESTAMP \
	    PROJECT \
	    FULLVERSION

	if [ ${retval} -eq 0 -a "${copy_back}" = "true" ]; then
		cp -- .config "${file_dotconfig}" || return
		if [ -f .config.old ]; then
			cp -- .config.old "$(readlink -f "${file_dotconfig}").old" || return
		fi
	fi

	popd > /dev/null
	rm -fr "${tmpdir}"

	return $retval
}
export -f ptxd_kconfig


#
# call make,
# source shell libraries wich are used in make
# ("scripts/lib/ptxd_make_"*.sh)
#
ptxd_make() {
	local lib i
	local -a dir
	ptxd_in_path PTXDIST_PATH_SCRIPTS || return
	dir=( "${ptxd_reply[@]}" )
	for ((i=$((${#dir[@]}-1)); i>=0; i--)) do
		ptxd_get_path "${dir[${i}]}/lib/ptxd_make_"*.sh || continue
		for lib in "${ptxd_reply[@]}"; do
			source "${lib}" || ptxd_bailout "failed to source lib: ${lib}"
		done
	done
	${PTX_NICE:+nice -n ${PTX_NICE}} "${PTXCONF_SETUP_HOST_MAKE}" \
	    "${PTX_MAKE_ARGS[@]}" "${PTXDIST_PARALLELMFLAGS_EXTERN}" \
	    -f "${RULESDIR}/other/Toplevel.make" "${@}" || return
}

#
# call make and log it
#
# supress stdout in quiet mode
#
ptxd_make_log() {(
	# stdout only
	exec {PTXDIST_FD_STDOUT}>&1
	# stderr only
	exec {PTXDIST_FD_STDERR}>&2
	# logfile only
	exec 9>> "${PTX_LOGFILE}"
	export PTXDIST_FD_STDOUT
	export PTXDIST_FD_STDERR
	export PTXDIST_FD_LOGFILE=9

	if [ -z "${PTXDIST_QUIET}" ]; then
		# stdout and logfile
		exec {logout}> >(tee -a "${PTX_LOGFILE}")
	else
		# logfile only
		exec {logout}>> "${PTX_LOGFILE}"
	fi
	# stderr and logfile
	exec {logerr}> >(tee -a "${PTX_LOGFILE}" >&2)

	ptxd_make "${@}" 1>&${logout} 2>&${logerr}
)}



#
# replaces @MAGIC@ with MAGIC from environment (if available)
# it will stay @MAGIC@ if MAGIC is unset in the environment
#
# $1		input file
# stdout:	output
#
ptxd_replace_magic() {
	gawk '
$0 ~ /@[A-Za-z0-9_]+@/ {
	line = $0

	while (match(line, "@[A-Za-z0-9_]+@")) {
		var = substr(line, RSTART + 1, RLENGTH - 2);
		line = substr(line, RSTART + RLENGTH);

		if (var in ENVIRON)
			gsub("@" var "@", ENVIRON[var]);
	}
}

{
	print;
}' "${1}"

}
export -f ptxd_replace_magic



#
#
#
ptxd_filter_dir() {
	local srcdir="${1}"
	local dstdir="${2}"
	local src dst

	[ -d "${srcdir}" ] || return
	[ -n "${dstdir}" ] || return

	mkdir -p "${dstdir}" &&

	tar -C "${srcdir}" -c . \
		--exclude .svn \
		--exclude .pc \
		--exclude .git \
		--exclude "*.in" \
		--exclude "*.in.*" \
		--exclude "*/*~" \
		| tar -C "${dstdir}" -x
	check_pipe_status || return

	{
		find "${srcdir}" -name "*.in"
		find "${srcdir}" -name "*.in${PTXDIST_PLATFORMSUFFIX}"
	} | while read src; do
		dst="${src/#${srcdir}/${dstdir}/}"
		dst="${dst%.in}"
		ptxd_replace_magic "${src}" > "${dst}" || return
	done
}
export -f ptxd_filter_dir



#
# returns the concatination of two variables,
# the seperator can be specified, space is default
#
# $1	variable the will hold the concatinated value
# $2	first part
# $3	second part
# $4	separator (optional, space is default)
#
ptxd_var_concat()
{
	eval "${1}"=\"${2//\"/\\\"}${2:+${3:+${4:- }}}${3//\"/\\\"}\" || exit
}
#export -f ptxd_var_concat



#
# dump current callstack
# wait for keypress
#
ptxd_dumpstack() {
	local i=0

	{
		echo '############# stackdump #############'
		while caller $i; do
			let i++
		done
		echo '######## any key to continue ########'
	} >&2

	read
}


#
# ptxd_get_alternative - look for files in platform, BSP and ptxdist
#
# $1	path prefix (relative to ptxdist etc.)
# $2	filename
#
# return:
# 0 if files/dirs are found
# 1 if no files/dirs are found
#
# array "ptxd_reply" containing the found files
#
ptxd_get_alternative() {
    local prefix="${1%/}"
    local file="${2}"
    [ -n "${prefix}" -a -n "${file}" ] || return

    list=( \
	"${PTXDIST_WORKSPACE}/${prefix}${PTXDIST_PLATFORMSUFFIX}/${file}" \
	"${PTXDIST_WORKSPACE}/${prefix}/${file}${PTXDIST_PLATFORMSUFFIX}" \
	"${PTXDIST_PLATFORMCONFIGDIR}/${prefix}/${file}${PTXDIST_PLATFORMSUFFIX}" \
	"${PTXDIST_WORKSPACE}/${prefix}/${file}" \
	"${PTXDIST_PLATFORMCONFIGDIR}/${prefix}/${file}" \
	"${PTXDIST_TOPDIR}/${prefix}/${file}" \
	)

    ptxd_get_path "${list[@]}"
}
export -f ptxd_get_alternative

#
# ptxd_get_path - look for files and/or dirs
#
# return:
# 0 if files/dirs are found
# 1 if no files/dirs are found
#
# array "ptxd_reply" containing the found files/dirs
#
ptxd_get_path() {
    [ -n "${1}" ] || return

    ptxd_reply=( $(eval command ls -f -d "${@}" 2>/dev/null) )

    [ ${#ptxd_reply[@]} -ne 0 ]
}
export -f ptxd_get_path

#
# ptxd_in_path - look for files and/or dirs
#
# $1 variable name with paths separated by ":"
# $2 filename to find within these paths
#
# return:
# 0 if files/dirs are found
# 1 if no files/dirs are found
#
# array "ptxd_reply" containing the found files/dirs
#
ptxd_in_path() {
	local orig_IFS="${IFS}"
	IFS=:
	local -a paths
	paths=( ${!1} )
	IFS="${orig_IFS}"
	paths=( "${paths[@]/%/${2:+/}${2}}" )
	ptxd_get_path "${paths[@]}"
}
export -f ptxd_in_path

#
# convert a relative or absolute path into an absolute path
#
ptxd_abspath() {
	local fn dn
	if [ $# -ne 1 ]; then
		echo "usage: ptxd_abspath <path>"
		exit 1
	fi
	if [ -d "${1}" ]; then
		fn=""
		dn="${1}"
	else
		fn="/$(basename "${1}")"
		dn="$(dirname "${1}")"
	fi

	[ ! -d "${dn}" ] && ptxd_bailout "directory '${dn}' does not exist"
	echo "$(cd "${dn}" && pwd)${fn}"
}
export -f ptxd_abspath


#
# calculate the relative path from one absolute path to another
#
# $1	from path
# $2	to path
#
ptxd_abs2rel() {
	local from from_parts to to_parts max orig_IFS
	if [ $# -ne 2 ]; then
		ptxd_bailout "usage: ptxd_abs2rel <from> <to>"
	fi

	from="${1}"
	to="${2}"

	orig_IFS="${IFS}"
	IFS="/"
	from_parts=(${from#/})
	to_parts=(${to#/})

	if [ ${#from_parts[@]} -gt ${#to_parts[@]} ]; then
		max=${#from_parts[@]}
	else
		max=${#to_parts[@]}
	fi

	for ((i = 0; i < ${max}; i++)); do
		from="${from_parts[i]}"
		to="${to_parts[i]}"

		if [ "${from}" = "${to}" ]; then
			unset from_parts[$i]
			unset to_parts[$i]
		elif [ -n "${from}" ]; then
			from_parts[$i]=".."
		fi
	done

	echo "${from_parts[*]}${from_parts[*]:+/}${to_parts[*]}"
	IFS="${orig_IFS}"
}
export -f ptxd_abs2rel


#
# prints a path but removes non interesting prefixes
#
ptxd_print_path() {

    if [ $# -ne 1 ]; then
	ptxd_bailout "number of arguments must be 1"
    fi

    local path out
    for path in ${PTXDIST_PATH//:/ }; do
	path="${path%/*}/"
	out="${1/#${path}}"
	if [ "${out}" != "${1}" ]; then
	    break;
	fi
    done

    echo "${out}"

}
export -f ptxd_print_path


#
# convert a human readable number with [kM] suffix or 0x prefix into a number
#
ptxd_human_to_number() {
	local num
	if [ ${#} -ne 1 ]; then
		echo "usage: ptxd_human_to_number <number>"
		exit 1
	fi

	num=$(echo "$1" | sed 's/m$/*1024*1024/I')
	num=$(echo "$num" | sed 's/k$/*1024/I')

	echo $((num))
}

#
# convert a package name into its make_name (i.e. host-foo -> HOST_FOO)
#
ptxd_name_to_NAME() {
	local name
	if [ ${#} -ne 1 ]; then
		echo "usage: ptxd_name_to_NAME <pkg-name>"
		exit 1
	fi
	name="$(echo "${1}" | tr 'a-z-' 'A-Z_')"
	echo "${name}"
}
export -f ptxd_name_to_NAME

#
# customized exit functions
#
# $1 --> Error Message
# $2 --> Exit Code
#
ptxd_exit(){
	echo "$0: $1"
	exit $2
}

ptxd_exit_silent(){
	ptxd_debug "$0: $1"
	exit $2
}

#
# Debugging Output
#
ptxd_debug(){
	if [ "${PTX_DEBUG}" = "true" ]; then
		echo "$0: ${@}" >&2
	fi
}

ptxd_debug "Debugging is enabled - Turn off with PTX_DEBUG=false"

#
# print out error message and exit with status 1
#
# $1: error message
# $2: optional exit value (1 is default)
#
# ${PTXDIST_LOG_PROMPT}: to be printed before message
#
ptxd_bailout() {
	echo "${PTXDIST_LOG_PROMPT}error: $1" >&2
	exit ${2:-1}
}
export -f ptxd_bailout


#
# print out error message
# if PTXDIST_PEDANTIC is true exit with status 1
#
# $1: error message
# $2: optional exit value (1 is default)
#
# ${PTXDIST_LOG_PROMPT}: to be printed before message
#
ptxd_pedantic() {
	echo "${PTXDIST_LOG_PROMPT}error: $1" >&2
	if [ "$PTXDIST_PEDANTIC" = "true" ]; then
		exit ${2:-1}
	fi
}
export -f ptxd_pedantic


#
# print out warning message
#
# $1: warning message
# ${PTXDIST_LOG_PROMPT}: to be printed before message
#
ptxd_warning() {
	echo "${PTXDIST_LOG_PROMPT}warning: $1" >&2
}
export -f ptxd_warning

#
# print a message if verbose building is enabled
# the message will always be written to the logfile
#
ptxd_verbose() {
	if [ "${PTXDIST_VERBOSE}" == "1" ]; then
		echo "${PTXDIST_LOG_PROMPT}""${@}" >&2
	elif [ -n "${PTXDIST_FD_LOGFILE}" ]; then
		echo "${PTXDIST_LOG_PROMPT}""${@}" >&9
	fi
}
export -f ptxd_verbose

#
# execute the arguments with eval
#
ptxd_eval() {
	ptxd_verbose "executing:" "${@}
"
	eval "${@}"
}
export -f ptxd_eval

#
# check if a previously executed pipe returned an error
#
check_pipe_status() {
	for _pipe_status in "${PIPESTATUS[@]}"; do
		if [ ${_pipe_status} -ne 0 ]; then
			return ${_pipe_status}
		fi
	done
}
export -f check_pipe_status


#
# $1: lib_path	# cannolocilized path to lib or link
#
ptxd_lib_sysroot() {
	local lib_path lib lib_dir prefix tmp

	lib_path="${1}"
	lib="$(basename "${lib_path}")"
	lib_dir="$(dirname "${lib_path}")"

	# try to identify sysroot part of that path
	for prefix in {/usr,}/lib{64,32,}{/tls,/gconv,} ""; do
		tmp="${lib_dir%${prefix}}"
		if test "${lib_dir}" != "${tmp}"; then
			echo "${tmp}"
			return
		fi
	done

	return 1
}
export -f ptxd_lib_sysroot


#
# split ipkg filename into it's parts
#
# input format:
#
# "name_1.2.3-4_arm.ipk", packet revision (-4) is optional
#
# output format:
#
# - "name arm 1.2.3 4" if packet revision exists
# - "name arm 1.2.3"   if packet revision doesn't exist
#
ptxd_ipkg_split() {
	local name=`echo $1 | sed -e "s/\(.*\)_\(.*\)_\(.*\).ipk/\1/"`
	local rev=`echo $1 | sed -e "s/\(.*\)_\(.*\)_\(.*\).ipk/\2/"`
	local arch=`echo $1 | sed -e "s/\(.*\)_\(.*\)_\(.*\).ipk/\3/"`
	local rev_upstream=`echo $rev | sed -e "s/\(.*\)-\(.*\)/\1/"`
	local rev_packet=""
	[ `echo $rev | grep -e "-"` ] && rev_packet=`echo $rev | sed -e "s/\(.*\)-\(.*\)/\2/"`
	if [ "$rev_upstream" = "" ] && [ "$rev_packet" = "" ]; then
		rev_upstream=$rev
	fi
	echo "$name $arch $rev_upstream $rev_packet"
}

#
# get name part of already split ipkg filename
#
ptxd_ipkg_name() {
	echo $1
}

#
# get upstream revision part of already split ipkg filename
#
ptxd_ipkg_rev_upstream() {
	echo $3
}

#
# get packet revision part of already split ipkg filename
#
ptxd_ipkg_rev_package() {
	echo $4
}

#
# get architecture part of already split ipkg filename
#
ptxd_ipkg_arch() {
	echo $2
}

#
#
ptxd_ipkg_rev_decimal_convert() {
	local ver=$*
	while echo $ver | grep -q '[^0-9.~]'
	do
		local char="$(sed 's/.*\([^0-9.~]\).*/\1/' <<< $ver)"
		local char_dec="$(echo $(od -b -N1 -An <<< $char))"
		ver="${ver//$char/.$char_dec}"
	done

	ver="$(sed -r "s/\.?~/.-1./g" <<< $ver)"
	ver="${ver//../.0}"
	ver="${ver#.}"

	echo "$ver"
}

#
#
ptxd_ipkg_do_version_check() {
	local ver1=$1
	local ver2=$2

	[ "$ver1" == "$ver2" ] && return 10

	local ver1front=`echo $ver1 | cut -d . -f 1`
	local ver1back=`echo $ver1 | cut -d . -f 2-`
	local ver2front=`echo $ver2 | cut -d . -f 1`
	local ver2back=`echo $ver2 | cut -d . -f 2-`

	if [ "$ver1front" != "$ver1" -o "$ver2front" != "$ver2" ]
	then
		[ "$ver1front" -lt "$ver2front" ] && return 9
		[ "$ver1front" -gt "$ver2front" ] && return 11

		[ "$ver1front" == "$ver1" ] || [ -z "$ver1back" ] && ver1back=0
		[ "$ver2front" == "$ver2" ] || [ -z "$ver2back" ] && ver2back=0
		ptxd_ipkg_do_version_check "$ver1back" "$ver2back"
		return $?
	else
		[ "$ver1" -lt "$ver2" ] && return 9 || return 11
	fi
}

#
#
ptxd_ipkg_rev_smaller() {

	local first=`ptxd_ipkg_split $1`
	local first_rev_upstream=`ptxd_ipkg_rev_upstream $first`
	local first_rev_packet=`ptxd_ipkg_rev_package $first`
	local second=`ptxd_ipkg_split $2`
	local second_rev_upstream=`ptxd_ipkg_rev_upstream $second`
	local second_rev_packet=`ptxd_ipkg_rev_package $second`

	if [ "$first_rev_upstream" != "$second_rev_upstream" ]
	then
		local first_rev_upstream_decimal=`ptxd_ipkg_rev_decimal_convert $first_rev_upstream`
		local second_rev_upstream_decimal=`ptxd_ipkg_rev_decimal_convert $second_rev_upstream`
		ptxd_ipkg_do_version_check "$first_rev_upstream_decimal" "$second_rev_upstream_decimal"
		case "$?" in
			9)
				return 0;
				;;
			10)
				;;
			11)
				return 1;
				;;
			*)
				ptxd_error "issue while checking upstream revisions"
		esac
	fi

	[ $first_rev_packet -lt $second_rev_packet ] && return 0
	[ $first_rev_packet -gt $second_rev_packet ] && return 1

	ptxd_error "packets $1 and $2 have the same revision"
}

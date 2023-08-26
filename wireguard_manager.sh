#!/usr/bin/env bash
#
#           Wireguard Manager Installer Script
#
#   GitHub: https://github.com/izetmolla/wireguard-manager
#   Issues: https://github.com/izetmolla/wireguard-manager/issues
#   Requires: bash, mv, rm, tr, type, grep, sed, curl/wget, tar (or unzip on OSX and Windows)
#
#   This script installs Wireguard Manager to your path.
#   Usage:
#
#   	$ curl -fsSL https://raw.githubusercontent.com/izetmolla/get/main/get.sh | bash
#   	  or
#   	$ wget -qO- https://raw.githubusercontent.com/izetmolla/get/main/get.sh | bash
#
#   In automated environments, you may want to run as root.
#   If using curl, we recommend using the -fsSL flags.
#
#   This should work on Mac, Linux, and BSD systems, and
#   hopefully Windows with Cygwin. Please open an issue if
#   you notice any bugs.
#

install_wireguardmanager()
{
	trap 'echo -e "Aborted, error $? in command: $BASH_COMMAND"; trap ERR; return 1' ERR
	wireguardmanager_os="unsupported"
	wireguardmanager_arch="unknown"
	install_path="/usr/local/bin"

	# Termux on Android has $PREFIX set which already ends with /usr
	if [[ -n "$ANDROID_ROOT" && -n "$PREFIX" ]]; then
		install_path="$PREFIX/bin"
	fi

	# Fall back to /usr/bin if necessary
	if [[ ! -d $install_path ]]; then
		install_path="/usr/bin"
	fi

	# Not every platform has or needs sudo (https://termux.com/linux.html)
	((EUID)) && [[ -z "$ANDROID_ROOT" ]] && sudo_cmd="sudo"

	#########################
	# Which OS and version? #
	#########################

	wireguardmanager_bin="wireguard-manager"
	wireguardmanager_dl_ext=".tar.gz"

	# NOTE: `uname -m` is more accurate and universal than `arch`
	# See https://en.wikipedia.org/wiki/Uname
	unamem="$(uname -m)"
	case $unamem in
	*aarch64*)
		wireguardmanager_arch="arm64";;
	*64*)
		wireguardmanager_arch="amd64";;
	*86*)
		wireguardmanager_arch="386";;
	*armv5*)
		wireguardmanager_arch="armv5";;
	*armv6*)
		wireguardmanager_arch="armv6";;
	*armv7*)
		wireguardmanager_arch="armv7";;
	*)
		echo "Aborted, unsupported or unknown architecture: $unamem"
		return 2
		;;
	esac

	unameu="$(tr '[:lower:]' '[:upper:]' <<<$(uname))"
	if [[ $unameu == *DARWIN* ]]; then
		wireguardmanager_os="darwin"
	elif [[ $unameu == *LINUX* ]]; then
		wireguardmanager_os="linux"
	elif [[ $unameu == *FREEBSD* ]]; then
		wireguardmanager_os="freebsd"
	elif [[ $unameu == *NETBSD* ]]; then
		wireguardmanager_os="netbsd"
	elif [[ $unameu == *OPENBSD* ]]; then
		wireguardmanager_os="openbsd"
	elif [[ $unameu == *WIN* || $unameu == MSYS* ]]; then
		# Should catch cygwin
		sudo_cmd=""
		wireguardmanager_os="windows"
		wireguardmanager_bin="wireguard-manager.exe"
		wireguardmanager_dl_ext=".zip"
	else
		echo "Aborted, unsupported or unknown OS: $uname"
		return 6
	fi

	########################
	# Download and extract #
	########################

	echo "Downloading Wireguard Manager for $wireguardmanager_os/$wireguardmanager_arch..."
	if type -p curl >/dev/null 2>&1; then
		net_getter="curl -fsSL"
	elif type -p wget >/dev/null 2>&1; then
		net_getter="wget -qO-"
	else
		echo "Aborted, could not find curl or wget"
		return 7
	fi
	
	wireguardmanager_file="${wireguardmanager_os}-$wireguardmanager_arch-wireguard-manager$wireguardmanager_dl_ext"
	wireguardmanager_tag="$(${net_getter}  https://api.github.com/repos/izetmolla/wireguard-manager-test/releases/latest | grep -o '"tag_name": ".*"' | sed 's/"//g' | sed 's/tag_name: //g')"
	wireguardmanager_url="https://github.com/izetmolla/wireguard-manager-test/releases/download/$wireguardmanager_tag/$wireguardmanager_file"
	echo "$wireguardmanager_url"

	# Use $PREFIX for compatibility with Termux on Android
	rm -rf "$PREFIX/tmp/$wireguardmanager_file"

	${net_getter} "$wireguardmanager_url" > "$PREFIX/tmp/$wireguardmanager_file"

	echo "Extracting..."
	case "$wireguardmanager_file" in
		*.zip)    unzip -o "$PREFIX/tmp/$wireguardmanager_file" "$wireguardmanager_bin" -d "$PREFIX/tmp/" ;;
		*.tar.gz) tar -xzf "$PREFIX/tmp/$wireguardmanager_file" -C "$PREFIX/tmp/" "$wireguardmanager_bin" ;;
	esac
	chmod +x "$PREFIX/tmp/$wireguardmanager_bin"

	echo "Putting Wireguard Manager in $install_path (may require password)"
	$sudo_cmd mv "$PREFIX/tmp/$wireguardmanager_bin" "$install_path/$wireguardmanager_bin"
	if setcap_cmd=$(PATH+=$PATH:/sbin type -p setcap); then
		$sudo_cmd $setcap_cmd cap_net_bind_service=+ep "$install_path/$wireguardmanager_bin"
	fi
	$sudo_cmd rm -- "$PREFIX/tmp/$wireguardmanager_file"

	if type -p $wireguardmanager_bin >/dev/null 2>&1; then
		echo "Successfully installed"
		trap ERR
		return 0
	else
		echo "Something went wrong, Wireguard Manager is not in your path"
		trap ERR
		return 1
	fi
}

install_wireguardmanager
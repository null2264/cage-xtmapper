#!/bin/sh
[ "$(id -u)" != "0" ] && {
	echo "This script requires root access to access waydroid shell."
	exit 1
}

[ "$XDG_RUNTIME_DIR" = "" ] && {
	echo "This script should be run with --preserve-env (-E) flag"
	exit 1
}

[ $# -eq 0 ] && {
	echo "User not specified."
	exit 1
}

while [ $# -gt 0 ]; do
	case "$1" in
		--user)
			shift
			user="$1"
			shift
			;;
		--window-width)
			shift
			XTMAPPER_WIDTH="$1"
			shift
			;;
		--window-height)
			shift
			XTMAPPER_HEIGHT="$1"
			shift
		;;
		--window-no-title-bar)
			shift
			export WLR_NO_DECORATION=1
			;;
		*)
			echo "Invalid argument"
			exit 1
			;;
	esac
done

export XTMAPPER_WIDTH=${XTMAPPER_WIDTH:-1366}
export XTMAPPER_HEIGHT=${XTMAPPER_HEIGHT:-740}

prompt() {
	printf "$1"
	read INPUT
	case $INPUT in
		[yY] ) return 0 ;;
		* ) return 1 ;;
	esac
}

_STATUS=$(waydroid status | head -n1 | sed 's/Session:\s//g')
case $(waydroid status | head -n1) in
	*"STOPPED"* ) ;;
	* ) prompt "You need to run script with Waydroid NOT currently running! Stop Waydroid now? (make sure to save your progress!) [y/N] " &&\
		su "$user" --command "waydroid session stop" || exit 1 ;;
esac

su "$user" --command "./build/cage waydroid show-full-ui" | (
	while [ -z $(waydroid shell getprop sys.boot_completed) ]; do
		sleep 1;
	done;

	echo 'exec /system/bin/app_process -Djava.library.path=$(echo /data/app/*/xtr.keymapper*/lib/x86_64) -Djava.class.path=$(echo /data/app/*/xtr.keymapper*/base.apk) / xtr.keymapper.server.RemoteServiceShell "$@"' |\
		waydroid shell -- sh -c 'test -f /tmp/xtmapper.sh || exec cat > /tmp/xtmapper.sh'
	exec waydroid shell -- sh /tmp/xtmapper.sh --wayland-client --width=$XTMAPPER_WIDTH --height=$XTMAPPER_HEIGHT
)

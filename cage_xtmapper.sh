#!/bin/bash
if [ "$(id -u)" != "0" ]; then
	echo "This script requires root access to access waydroid shell."
	exit 1
fi

if [ $# -eq 0 ]; then
	echo "User not specified."
	exit 1
fi

while [ $# -gt 0 ]; do
    case "$1" in
    --user)
        shift
        user="$1"
        ;;
    --window-width)
        shift
        XTMAPPER_WIDTH="$1"
        ;;
    --window-height)
        shift
        XTMAPPER_HEIGHT="$1"
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
    shift
done

export XTMAPPER_WIDTH=${XTMAPPER_WIDTH:-1366}
export XTMAPPER_HEIGHT=${XTMAPPER_HEIGHT:-740}

su "$user" --command "./build/cage waydroid show-full-ui" | (
	while [[ -z $(waydroid shell getprop sys.boot_completed) ]]; do
		sleep 1;
	done;

	echo 'exec /system/bin/app_process -Djava.library.path=$(echo /data/app/*/xtr.keymapper*/lib/x86_64) -Djava.class.path=$(echo /data/app/*/xtr.keymapper*/base.apk) / xtr.keymapper.server.RemoteServiceShell "$@"' |\
		waydroid shell -- sh -c 'test -f /tmp/xtmapper.sh || exec cat > /tmp/xtmapper.sh'
	exec waydroid shell -- sh /tmp/xtmapper.sh --wayland-client --width=$XTMAPPER_WIDTH --height=$XTMAPPER_HEIGHT
)

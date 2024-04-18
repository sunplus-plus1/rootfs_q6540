# shellcheck shell=sh

if [ -z "$DISPLAY" ] && [ "$XDG_SESSION_TYPE" = 'tty' ]; then
    case "$TERM" in
    vt220)
        export TERM='linux'
        ;;
    *)
        ;;
    esac
fi

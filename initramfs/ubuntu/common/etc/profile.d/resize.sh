# shellcheck shell=sh

if [ "$COLUMNS" = 80 ] && [ "$LINES" = 24 ]; then
    if [ -x /usr/bin/resize ]; then
        /usr/bin/resize > /dev/null
    fi
fi

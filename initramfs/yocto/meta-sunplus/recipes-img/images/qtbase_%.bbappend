
DESCRIPTION = "A custom application built with Qt5"
SUMMARY = "Qt 5 application for SP7350"
LICENSE = "LGPLv3"

QT_CONFIG_FLAGS = "\
-opensource \
-release \
-make libs \
-qpa fb \
-qpa drm \
-pch \
-qt-libjpeg \
-qt-libpng \
-qt-zlib \
-no-opengl \
-no-sse2 \
-no-openssl \
-no-cups \
-no-glib \
-no-dbus \
-no-xcb \
-no-separate-debug-info \
-no-ssl \
-nomake tests \
-nomake examples \
-nomake tools \
-no-sql-sqlite \
-no-iconv \
-skip qt3d \
-skip qtactiveqt \
-skip qtcanvas3d \
-skip qtcharts \
-skip qtconnectivity \
-skip qtdatavis3d \
-skip qtdeclarative \
-skip qtgamepad \
-skip qtandroidextras \
-skip qtdoc \
-skip qtwebchannel \
-skip qtwebengine \
-skip qtwebglplugin \
-skip qtwebview \
-skip qtvirtualkeyboard \
-recheck    "

PACKAGECONFIG = " \
    ${PACKAGECONFIG_RELEASE} \
    ${PACKAGECONFIG_DEFAULT} \
    ${PACKAGECONFIG_OPENSSL} \
    ${PACKAGECONFIG_FONTS} \
    ${PACKAGECONFIG_SYSTEM} \
    ${PACKAGECONFIG_DISTRO} \
"
PACKAGECONFIG:append_pn-qtbase = " linuxfb"



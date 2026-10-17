# Die Sailfish-Ausgabe. Die MeeGo-Fassung lebt in einem eigenen Baum
# (smatkovi/oe1-radio) -- sie braucht wget und einen Vermittler, die hier
# alle wegfallen.

TARGET = harbour-oe1radio

CONFIG += sailfishapp

QT += network

# Die Fassung steht im Spec und kommt von dort.
isEmpty(VERSION): VERSION = 0.0.0
DEFINES += APP_VERSION=\\\"$$VERSION\\\"

SOURCES += \
    src/harbour-oe1radio.cpp \
    src/api.cpp

HEADERS += \
    src/api.h

DISTFILES += \
    harbour-oe1radio.desktop \
    rpm/harbour-oe1radio.spec \
    qml/harbour-oe1radio.qml \
    qml/cover/CoverPage.qml \
    qml/components/qmldir \
    qml/components/Spieler.qml \
    qml/components/Spielleiste.qml \
    qml/components/SendungsZeile.qml \
    qml/pages/MainPage.qml \
    qml/pages/SchedulePage.qml \
    qml/pages/PodcastsPage.qml \
    qml/pages/PodcastPage.qml \
    qml/pages/AboutPage.qml

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += sailfishapp_i18n

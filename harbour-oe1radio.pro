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
    src/api.cpp \
    src/lader.cpp \
    src/merker.cpp \
    src/einstellungen.cpp

HEADERS += \
    src/api.h \
    src/lader.h \
    src/merker.h \
    src/einstellungen.h

DISTFILES += \
    harbour-oe1radio.desktop \
    rpm/harbour-oe1radio.spec \
    qml/harbour-oe1radio.qml \
    qml/cover/CoverPage.qml \
    qml/components/qmldir \
    qml/components/Spieler.qml \
    qml/components/Spielleiste.qml \
    qml/components/SendungsZeile.qml \
    qml/components/Farben.qml \
    qml/components/Grund.qml \
    qml/pages/PodcastsPage.qml \
    qml/pages/PodcastPage.qml \
    qml/pages/PodcastInfoPage.qml \
    qml/pages/ShellPage.qml \
    qml/pages/SpielerPage.qml \
    qml/pages/EinstellungenPage.qml \
    qml/pages/InfoPage.qml \
    qml/pages/BeitragPage.qml \
    qml/views/JetztView.qml \
    qml/views/TageView.qml \
    qml/views/HighlightsView.qml \
    qml/views/JournaleView.qml \
    qml/views/FavoritenView.qml \
    qml/components/TabLeiste.qml \
    qml/components/Pulley.qml \
    qml/components/PulleyEintrag.qml \
    qml/components/MenuEintrag.qml \
    qml/components/Titel.qml \
    qml/components/Abschnitt.qml \
    qml/components/MiniSpieler.qml \
    qml/pages/SuchePage.qml \
    qml/pages/AufnahmenPage.qml \
    qml/pages/MehrPage.qml \
    qml/pages/AboutPage.qml

OTHER_FILES += \
    tools/qml-pruefen.sh \
    tools/make-icons.py \
    tests/attrappen/harbour/oe1radio/qmldir \
    tests/attrappen/harbour/oe1radio/Einstellungen.qml

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += sailfishapp_i18n

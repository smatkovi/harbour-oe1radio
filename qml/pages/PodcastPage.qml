import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/*!
 * Die Folgen eines Podcasts. Sie stehen nicht in der JSON-Schnittstelle --
 * die nennt nur die Adresse des RSS-Feeds, und den liest api.cpp.
 */
Page {
    id: seite
    allowedOrientations: Orientation.All

    Grund {}

    property int podcastId: 0
    property string podcastTitel: ""
    property var folgen: []
    property var podcast: ({})

    Component.onCompleted: oe1.ladeFolgen(podcastId)

    Connections {
        target: oe1
        onFolgenGeladen: seite.folgen = folgen
        onPodcastGeladen: seite.podcast = podcast
    }

    SilicaListView {
        anchors.fill: parent
        model: seite.folgen

        Pulley {
            PulleyEintrag {
                text: qsTr("Info zum Podcast")
                onClicked: pageStack.push(Qt.resolvedUrl("PodcastInfoPage.qml"), {
                    podcastId: seite.podcastId,
                    podcast: seite.podcast
                })
            }
            PulleyEintrag {
                visible: !!seite.podcast.seite
                text: qsTr("Im Browser öffnen")
                onClicked: Qt.openUrlExternally(seite.podcast.seite)
            }
            PulleyEintrag {
                visible: !!seite.podcast.spotify
                text: qsTr("Bei Spotify öffnen")
                onClicked: Qt.openUrlExternally(seite.podcast.spotify)
            }
            PulleyEintrag {
                visible: !!seite.podcast.feed
                text: qsTr("Feed-Adresse kopieren")
                onClicked: Clipboard.text = seite.podcast.feed
            }
            PulleyEintrag {
                text: qsTr("Neu laden")
                onClicked: oe1.ladeFolgen(seite.podcastId)
            }
        }

        header: Column {
            width: seite.width
            spacing: Theme.paddingSmall

            Titel {
                title: seite.podcastTitel
                description: seite.podcast.autor || ""
            }

            // Was der Dienst ueber den Podcast hergibt -- bisher wurde es
            // beim Laden der Folgen mitgeliefert und weggeworfen.
            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingMedium
                visible: bild.visible || beschreibung.text !== ""

                Image {
                    id: bild
                    width: Theme.itemSizeLarge
                    height: width
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    asynchronous: true
                    source: seite.podcast.bild || ""
                    visible: source != "" && status === Image.Ready
                }

                Label {
                    id: beschreibung
                    width: parent.width - (bild.visible ? bild.width + Theme.paddingMedium : 0)
                    text: seite.podcast.text || ""
                    wrapMode: Text.Wrap
                    // Antippen klappt den ganzen Text auf.
                    maximumLineCount: aufgeklappt ? 99 : 4
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Farben.schriftMatt

                    property bool aufgeklappt: false
                    MouseArea {
                        anchors.fill: parent
                        onClicked: beschreibung.aufgeklappt = !beschreibung.aufgeklappt
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: seite.podcast.anzahl > 0
                text: qsTr("%1 Folgen").arg(seite.podcast.anzahl)
                      + (seite.podcast.rechte ? "  ·  " + seite.podcast.rechte : "")
                font.pixelSize: Theme.fontSizeTiny
                color: Farben.kuenftig
                truncationMode: TruncationMode.Fade
            }

            Spielleiste { width: parent.width }
        }

        delegate: ListItem {
            // Das Band beim Antippen in Ö1-Rot statt in der Ambience-Farbe.
            palette.highlightBackgroundColor: Farben.band
            id: zeile
            contentHeight: zeilen.height + Theme.paddingMedium

            property bool aufgeklappt: false
            readonly property bool dieseSpielt:
                Spieler.hatQuelle && Spieler.titel === modelData.titel
            // Die Folgenadresse ist die Kennung -- zwei Folgen koennen
            // gleich heissen, die Adresse ist eindeutig.
            readonly property string kennung: "folge:" + (modelData.adresse || "")
            readonly property double anteil: lader.aufnahmen.length >= 0
                                             ? lader.fortschritt(kennung) : -1

            menu: ContextMenu {
                backgroundColor: Farben.flaeche
                palette.highlightBackgroundColor: Farben.band
                MenuEintrag {
                    visible: zeile.anteil < 0
                    text: qsTr("Herunterladen")
                    onClicked: lader.hole(zeile.kennung, modelData.titel,
                                          modelData.adresse)
                }
                MenuItem {
                    visible: zeile.anteil >= 0 && zeile.anteil < 1
                    text: qsTr("Abbruch")
                    onClicked: lader.abbrechen(zeile.kennung)
                }
                MenuItem {
                    visible: zeile.anteil === 1
                    text: qsTr("Aufnahme löschen")
                    onClicked: lader.loeschen(zeile.kennung)
                }
                MenuItem {
                    text: merker.gemerkt(zeile.kennung) ? qsTr("Nicht mehr merken")
                                                        : qsTr("Als Favorit merken")
                    onClicked: merker.umschalten(zeile.kennung, {
                        titel: modelData.titel,
                        untertitel: modelData.datum || "",
                        art: "folge",
                        adresse: modelData.adresse
                    })
                }
            }

            onClicked: {
                if (dieseSpielt) {
                    Spieler.umschalten()
                } else {
                    // Schon auf dem Geraet? Dann von dort.
                    var da = lader.dateiAdresse(kennung)
                    Spieler.spieleSendung(0, modelData.titel, modelData.datum,
                                          da !== "" ? da : modelData.adresse)
                }
            }

            Column {
                id: zeilen
                anchors {
                    left: parent.left; right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                Label {
                    width: parent.width
                    text: modelData.titel
                    truncationMode: TruncationMode.Fade
                    color: zeile.dieseSpielt ? Farben.rot : Farben.schrift
                }
                Label {
                    width: parent.width
                    text: modelData.datum
                          + (zeile.anteil >= 0 && zeile.anteil < 1
                                ? "   " + Math.round(zeile.anteil * 100) + " %"
                             : zeile.anteil === 1 ? "   ↓" : "")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: zeile.anteil >= 0 ? Farben.rot : Farben.schriftMatt
                }

                // Die Beschreibung der Folge steht im RSS und wurde bisher
                // zwar eingelesen, aber nie gezeigt. Antippen klappt sie auf.
                Label {
                    width: parent.width
                    visible: text !== ""
                    text: modelData.text || ""
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: zeile.aufgeklappt ? 99 : 2
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeTiny
                    color: Farben.schriftMatt
                }
                ProgressBar {
                    palette.primaryColor: Farben.schrift
                    palette.secondaryColor: Farben.schriftMatt
                    palette.highlightColor: Farben.rot
                    width: parent.width
                    visible: zeile.anteil >= 0 && zeile.anteil < 1
                    minimumValue: 0; maximumValue: 1
                    value: zeile.anteil
                }
            }
        }

        ViewPlaceholder {
            palette.primaryColor: Farben.schrift
            palette.secondaryColor: Farben.schriftMatt
            palette.highlightColor: Farben.rot
            enabled: seite.folgen.length === 0 && !oe1.busy
            text: qsTr("Keine Folgen")
        }

        VerticalScrollDecorator {}
    }

    BusyIndicator {
        // Nicht ueber die palette: der Kringel ist ein HighlightImage
        // im Inneren und nimmt seine Farbe aus dem Theme. Die eigene
        // Eigenschaft "color" wirkt (nachgemessen).
        color: Farben.rot
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: oe1.busy && seite.folgen.length === 0
    }
}

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

    Component.onCompleted: oe1.ladeFolgen(podcastId)

    Connections {
        target: oe1
        onFolgenGeladen: seite.folgen = folgen
    }

    SilicaListView {
        anchors.fill: parent
        model: seite.folgen

        header: Column {
            width: seite.width
            Titel {
                title: seite.podcastTitel
            }
            Spielleiste { width: parent.width }
        }

        delegate: ListItem {
            // Das Band beim Antippen in Ö1-Rot statt in der Ambience-Farbe.
            palette.highlightBackgroundColor: Farben.band
            id: zeile
            contentHeight: zeilen.height + Theme.paddingMedium

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
                          + (zeile.anteil === 1 ? "   ↓" : "")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: zeile.anteil === 1 ? Farben.rot : Farben.schriftMatt
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
        palette.highlightColor: Farben.rot
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: oe1.busy && seite.folgen.length === 0
    }
}

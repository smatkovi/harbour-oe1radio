import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/*!
 * "Info" zur Sendung, wie in der Android-App: Bild, Titel, Zeit, Beschreibung,
 * dazu Abspielen, Merken und Herunterladen.
 */
Page {
    id: seite
    allowedOrientations: Orientation.All

    property var sendung: ({})
    readonly property string kennung: "sendung:" + (sendung.id || 0)
    readonly property bool gemerkt: merker.eintraege.length >= 0
                                    && merker.gemerkt(kennung)
    readonly property double anteil: lader.aufnahmen.length >= 0
                                     ? lader.fortschritt(kennung) : -1

    Grund {}

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: spalte.height + Theme.paddingLarge

        Pulley {
            PulleyEintrag {
                text: seite.gemerkt ? qsTr("Nicht mehr merken") : qsTr("Als Favorit merken")
                onClicked: merker.umschalten(seite.kennung, {
                    titel: seite.sendung.titel,
                    untertitel: seite.sendung.untertitel || "",
                    art: "sendung",
                    id: seite.sendung.id
                })
            }
            PulleyEintrag {
                visible: !!seite.sendung.adresse && seite.anteil < 0
                text: qsTr("Herunterladen")
                onClicked: lader.hole(seite.kennung, seite.sendung.titel,
                                      seite.sendung.adresse)
            }
            PulleyEintrag {
                visible: seite.anteil >= 0 && seite.anteil < 1
                text: qsTr("Abbrechen")
                onClicked: lader.abbrechen(seite.kennung)
            }
            PulleyEintrag {
                visible: seite.anteil === 1
                text: qsTr("Aufnahme löschen")
                onClicked: lader.loeschen(seite.kennung)
            }
        }

        Column {
            id: spalte
            width: parent.width
            spacing: Theme.paddingMedium

            Titel {
                title: seite.sendung.titel || qsTr("Sendung")
            }

            Image {
                width: parent.width
                fillMode: Image.PreserveAspectFit
                visible: source != "" && status === Image.Ready
                // Auf der Seite das breite Kopfbild, nicht das quadratische.
                source: seite.sendung.bildBreit || seite.sendung.bild || ""
                asynchronous: true
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: text !== ""
                text: seite.sendung.untertitel || ""
                wrapMode: Text.Wrap
                color: Farben.rot
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                font.pixelSize: Theme.fontSizeSmall
                color: Farben.schriftMatt
                text: {
                    var t = seite.sendung.zeit || ""
                    if (seite.sendung.dauer > 0)
                        t += "  ·  " + Math.round(seite.sendung.dauer / 60000) + qsTr(" min")
                    return t
                }
            }

            // Fortschritt einer laufenden Aufnahme
            ProgressBar {
                palette.primaryColor: Farben.schrift
                palette.secondaryColor: Farben.schriftMatt
                palette.highlightColor: Farben.rot
                width: parent.width
                visible: seite.anteil >= 0 && seite.anteil < 1
                minimumValue: 0
                maximumValue: 1
                value: seite.anteil
                label: qsTr("wird heruntergeladen")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: seite.anteil === 1
                text: qsTr("Auf dem Gerät")
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Farben.rot
            }

            Button {
                palette.primaryColor: Farben.schrift
                palette.highlightColor: Farben.rot
                palette.highlightBackgroundColor: Farben.band
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !!seite.sendung.adresse
                text: qsTr("Anhören")
                onClicked: {
                    // Liegt die Sendung schon auf dem Gerät, von dort --
                    // spart Daten und laeuft im Funkloch.
                    var da = lader.dateiAdresse(seite.kennung)
                    Spieler.spieleSendung(seite.sendung.id, seite.sendung.titel,
                                          seite.sendung.zeit,
                                          da !== "" ? da : seite.sendung.adresse)
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: text !== ""
                text: seite.sendung.text || ""
                wrapMode: Text.Wrap
                textFormat: Text.StyledText
                font.pixelSize: Theme.fontSizeSmall
                color: Farben.schrift
                linkColor: Farben.rot
                onLinkActivated: Qt.openUrlExternally(link)
            }

            Spielleiste { width: parent.width }
        }
        VerticalScrollDecorator {}
    }
}

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/*!
 * Alles zu einer einzelnen Podcastfolge: Beschreibung, Datum, Dauer,
 * Groesse -- und was man mit ihr tun kann.
 *
 * Die Angaben stammen aus dem RSS des Podcasts; mehr gibt es ueber eine
 * Folge nicht, die JSON-Schnittstelle kennt die Folgen gar nicht.
 */
Page {
    id: seite
    allowedOrientations: Orientation.All

    property var folge: ({})
    property string podcastTitel: ""
    property string podcastBild: ""

    readonly property string kennung: "folge:" + (folge.adresse || "")
    readonly property double anteil: lader.aufnahmen.length >= 0
                                     ? lader.fortschritt(kennung) : -1
    readonly property bool gemerkt: merker.eintraege.length >= 0
                                    && merker.gemerkt(kennung)

    function zeitText(sekunden) {
        if (!sekunden || sekunden <= 0)
            return ""
        var h = Math.floor(sekunden / 3600)
        var m = Math.floor((sekunden % 3600) / 60)
        if (h > 0)
            return h + " h " + m + " min"
        return m + " min"
    }

    Grund {}

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: spalte.height + Theme.paddingLarge

        Pulley {
            PulleyEintrag {
                visible: !!seite.folge.seite
                text: qsTr("Im Browser öffnen")
                onClicked: Qt.openUrlExternally(seite.folge.seite)
            }
            PulleyEintrag {
                text: seite.gemerkt ? qsTr("Nicht mehr merken")
                                    : qsTr("Als Favorit merken")
                onClicked: merker.umschalten(seite.kennung, {
                    titel: seite.folge.titel,
                    untertitel: seite.folge.datum || "",
                    art: "folge",
                    adresse: seite.folge.adresse
                })
            }
            PulleyEintrag {
                visible: seite.anteil < 0
                text: qsTr("Herunterladen")
                onClicked: lader.hole(seite.kennung, seite.folge.titel,
                                      seite.folge.adresse)
            }
            PulleyEintrag {
                visible: seite.anteil >= 0 && seite.anteil < 1
                text: qsTr("Abbruch")
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
                title: seite.folge.titel || qsTr("Folge")
                description: seite.podcastTitel
            }

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width - 2 * Theme.horizontalPageMargin,
                                Theme.itemSizeHuge * 2)
                height: width
                fillMode: Image.PreserveAspectCrop
                clip: true
                asynchronous: true
                // Eine Folge hat kein eigenes Bild -- das des Podcasts steht
                // fuer sie.
                source: seite.podcastBild || ""
                visible: source != "" && status === Image.Ready
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: {
                    var t = []
                    if (seite.folge.datum) t.push(seite.folge.datum)
                    var d = seite.zeitText(seite.folge.dauer)
                    if (d) t.push(d)
                    if (seite.folge.groesse > 0)
                        t.push((seite.folge.groesse / 1048576).toFixed(1) + " MB")
                    return t.join("  ·  ")
                }
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Farben.schriftMatt
                wrapMode: Text.Wrap
            }

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
                text: qsTr("Anhören")
                onClicked: {
                    // Liegt sie schon auf dem Gerät, von dort -- spart
                    // Daten und laeuft im Funkloch.
                    var da = lader.dateiAdresse(seite.kennung)
                    Spieler.spieleSendung(0, seite.folge.titel,
                                          seite.folge.datum || "",
                                          da !== "" ? da : seite.folge.adresse)
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: text !== ""
                text: seite.folge.text || ""
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
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

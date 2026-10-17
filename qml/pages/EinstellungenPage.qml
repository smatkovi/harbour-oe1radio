import QtQuick 2.6
import Sailfish.Silica 1.0
import harbour.oe1radio 1.0
import "../components"

/*! Einstellungen -- vor allem das Farbschema. */
Page {
    allowedOrientations: Orientation.All

    Rectangle { anchors.fill: parent; color: Farben.grund }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: spalte.height + Theme.paddingLarge

        Column {
            id: spalte
            width: parent.width

            Titel {
                title: qsTr("Einstellungen")
            }

            Abschnitt { text: qsTr("Darstellung") }

            ComboBox {
                palette.primaryColor: Farben.schrift
                palette.secondaryColor: Farben.schriftMatt
                palette.highlightColor: Farben.rot
                width: parent.width
                label: qsTr("Farbschema")
                currentIndex: Einstellungen.farbschema === "dunkel" ? 0
                            : Einstellungen.farbschema === "hell" ? 1 : 2
                menu: ContextMenu {
                    backgroundColor: Farben.flaeche
                    MenuEintrag { text: qsTr("Dunkel (#000000)") }
                    MenuEintrag { text: qsTr("Hell") }
                    MenuEintrag { text: qsTr("Der Ambience folgen") }
                }
                onCurrentIndexChanged: {
                    Einstellungen.farbschema = currentIndex === 0 ? "dunkel"
                                             : currentIndex === 1 ? "hell" : "ambience"
                }
            }

            TextSwitch {
                palette.primaryColor: Farben.schrift
                palette.secondaryColor: Farben.schriftMatt
                palette.highlightColor: Farben.rot
                text: qsTr("Ö1-Rot als Akzent")
                description: qsTr("Die Hausfarbe der Ö1-App (#b61f24). Abgeschaltet nimmt die App die Akzentfarbe der Ambience.")
                checked: Einstellungen.oe1Rot
                onClicked: Einstellungen.oe1Rot = checked
            }

            Abschnitt { text: qsTr("Wiedergabe") }

            ComboBox {
                palette.primaryColor: Farben.schrift
                palette.secondaryColor: Farben.schriftMatt
                palette.highlightColor: Farben.rot
                width: parent.width
                label: qsTr("Güte des Livestroms")
                currentIndex: Einstellungen.guete === "hoch" ? 2
                            : Einstellungen.guete === "mittel" ? 1 : 0
                description: qsTr("Die hohe Güte ist der HLS-Strom, den die Android-App ebenfalls verwendet.")
                menu: ContextMenu {
                    backgroundColor: Farben.flaeche
                    MenuEintrag { text: qsTr("niedrig (32 kbit/s)") }
                    MenuEintrag { text: qsTr("mittel (128 kbit/s)") }
                    MenuEintrag { text: qsTr("hoch (HLS)") }
                }
                onCurrentIndexChanged: {
                    var neu = currentIndex === 2 ? "hoch"
                            : currentIndex === 1 ? "mittel" : "niedrig"
                    if (neu === Einstellungen.guete)
                        return
                    Einstellungen.guete = neu
                    if (Spieler.istLive && Spieler.hatQuelle)
                        Spieler.spieleLive()
                }
            }

            TextSwitch {
                palette.primaryColor: Farben.schrift
                palette.secondaryColor: Farben.schriftMatt
                palette.highlightColor: Farben.rot
                text: qsTr("Autoplay")
                description: qsTr("Beim Starten der App gleich den Livestrom spielen.")
                checked: Einstellungen.autoplay
                onClicked: Einstellungen.autoplay = checked
            }

            Abschnitt { text: qsTr("Aufnahmen") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Farben.schriftMatt
                text: qsTr("Heruntergeladenes liegt in ~/Downloads/Ö1 und wird von dort gespielt.")
            }

            Button {
                palette.primaryColor: Farben.schrift
                palette.highlightColor: Farben.rot
                palette.highlightBackgroundColor: Farben.rot
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Aufnahmen verwalten")
                onClicked: pageStack.push(Qt.resolvedUrl("AufnahmenPage.qml"))
            }
        }
        VerticalScrollDecorator {}
    }
}

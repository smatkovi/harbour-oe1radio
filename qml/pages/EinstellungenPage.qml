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

            PageHeader {
                title: qsTr("Einstellungen")
                _titleItem.color: Farben.rot
            }

            SectionHeader { text: qsTr("Darstellung") }

            ComboBox {
                width: parent.width
                label: qsTr("Farbschema")
                currentIndex: Einstellungen.farbschema === "dunkel" ? 0
                            : Einstellungen.farbschema === "hell" ? 1 : 2
                menu: ContextMenu {
                    MenuItem { text: qsTr("Dunkel (#000000)") }
                    MenuItem { text: qsTr("Hell") }
                    MenuItem { text: qsTr("Der Ambience folgen") }
                }
                onCurrentIndexChanged: {
                    Einstellungen.farbschema = currentIndex === 0 ? "dunkel"
                                             : currentIndex === 1 ? "hell" : "ambience"
                }
            }

            TextSwitch {
                text: qsTr("Ö1-Rot als Akzent")
                description: qsTr("Die Hausfarbe der Ö1-App (#b61f24). Abgeschaltet nimmt die App die Akzentfarbe der Ambience.")
                checked: Einstellungen.oe1Rot
                onClicked: Einstellungen.oe1Rot = checked
            }

            SectionHeader { text: qsTr("Wiedergabe") }

            ComboBox {
                width: parent.width
                label: qsTr("Güte des Livestroms")
                currentIndex: Einstellungen.guete === "hoch" ? 2
                            : Einstellungen.guete === "mittel" ? 1 : 0
                description: qsTr("Die hohe Güte ist der HLS-Strom, den die Android-App ebenfalls verwendet.")
                menu: ContextMenu {
                    MenuItem { text: qsTr("niedrig (32 kbit/s)") }
                    MenuItem { text: qsTr("mittel (128 kbit/s)") }
                    MenuItem { text: qsTr("hoch (HLS)") }
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
                text: qsTr("Autoplay")
                description: qsTr("Beim Starten der App gleich den Livestrom spielen.")
                checked: Einstellungen.autoplay
                onClicked: Einstellungen.autoplay = checked
            }

            SectionHeader { text: qsTr("Aufnahmen") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Farben.schriftMatt
                text: qsTr("Heruntergeladenes liegt in ~/Downloads/Ö1 und wird von dort gespielt.")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Aufnahmen verwalten")
                onClicked: pageStack.push(Qt.resolvedUrl("AufnahmenPage.qml"))
            }
        }
        VerticalScrollDecorator {}
    }
}

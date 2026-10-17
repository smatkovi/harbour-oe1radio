import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/*!
 * Die sieben Tage, die die Schnittstelle vorhaelt.
 */
Page {
    id: seite
    allowedOrientations: Orientation.All

    property int tagVersatz: 0
    property var sendungen: []

    Component.onCompleted: lade()

    function lade() {
        sendungen = []
        oe1.ladeTag(oe1.tagVor(tagVersatz))
    }

    Connections {
        target: oe1
        onTagGeladen: {
            if (datum === oe1.tagVor(seite.tagVersatz))
                seite.sendungen = sendungen
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: spalte.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: qsTr("Neu laden")
                onClicked: seite.lade()
            }
        }

        Column {
            id: spalte
            width: parent.width

            PageHeader { title: qsTr("7 Tage") }

            ComboBox {
                width: parent.width
                label: qsTr("Tag")
                currentIndex: seite.tagVersatz
                menu: ContextMenu {
                    Repeater {
                        model: 7
                        delegate: MenuItem { text: oe1.tagName(index) }
                    }
                }
                onCurrentIndexChanged: {
                    if (currentIndex !== seite.tagVersatz) {
                        seite.tagVersatz = currentIndex
                        seite.lade()
                    }
                }
            }

            Spielleiste { width: parent.width }

            Separator {
                width: parent.width
                color: Theme.secondaryColor
                horizontalAlignment: Qt.AlignHCenter
            }

            Repeater {
                model: seite.sendungen
                delegate: SendungsZeile {
                    width: seite.width
                    sendung: modelData
                }
            }

            ViewPlaceholder {
                enabled: seite.sendungen.length === 0 && !oe1.busy
                text: qsTr("Kein Programm")
                hintText: qsTr("Für diesen Tag liefert die Schnittstelle nichts.")
            }
        }

        VerticalScrollDecorator {}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: oe1.busy && seite.sendungen.length === 0
    }
}

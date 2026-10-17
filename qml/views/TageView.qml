import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/*!
 * Die sieben Tage, die die Schnittstelle vorhaelt.
 */
Item {
    id: ansicht


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
            if (datum === oe1.tagVor(ansicht.tagVersatz))
                ansicht.sendungen = sendungen
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: spalte.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem { text: qsTr("Einstellungen"); onClicked: pageStack.push(Qt.resolvedUrl("../pages/EinstellungenPage.qml")) }
            MenuItem { text: qsTr("Mehr"); onClicked: pageStack.push(Qt.resolvedUrl("../pages/MehrPage.qml")) }
            MenuItem { text: qsTr("Suche"); onClicked: pageStack.push(Qt.resolvedUrl("../pages/SuchePage.qml")) }
            MenuItem { text: qsTr("Neu laden"); onClicked: ansicht.lade() }
        }

        Column {
            id: spalte
            width: parent.width


            ComboBox {
                width: parent.width
                label: qsTr("Tag")
                currentIndex: ansicht.tagVersatz
                menu: ContextMenu {
                    Repeater {
                        model: 7
                        delegate: MenuItem { text: oe1.tagName(index) }
                    }
                }
                onCurrentIndexChanged: {
                    if (currentIndex !== ansicht.tagVersatz) {
                        ansicht.tagVersatz = currentIndex
                        ansicht.lade()
                    }
                }
            }

            Spielleiste { width: parent.width }

            Separator {
                width: parent.width
                color: Farben.schriftMatt
                horizontalAlignment: Qt.AlignHCenter
            }

            Repeater {
                model: ansicht.sendungen
                delegate: SendungsZeile {
                    width: ansicht.width
                    sendung: modelData
                }
            }

            ViewPlaceholder {
                enabled: ansicht.sendungen.length === 0 && !oe1.busy
                text: qsTr("Kein Programm")
                hintText: qsTr("Für diesen Tag liefert die Schnittstelle nichts.")
            }
        }

        VerticalScrollDecorator {}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: oe1.busy && ansicht.sendungen.length === 0
    }
}

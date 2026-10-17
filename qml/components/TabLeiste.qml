import QtQuick 2.6
import Sailfish.Silica 1.0
import "."

/*!
 * Die untere Reiterleiste der Android-App, nachgebaut.
 *
 * Deren `activity_main.xml` legt eine BottomNavigationView mit
 * `background="@color/oe1_red"` ganz unten hin; das gewaehlte Symbol ist
 * weiss, die uebrigen `#e7a9a7`. `labelVisibilityMode="selected"` heisst:
 * **nur der gewaehlte Reiter traegt seine Beschriftung** -- deshalb passen
 * dort fuenf nebeneinander, und hier ebenso.
 */
Rectangle {
    id: leiste

    property int gewaehlt: 0
    property var reiter: []        // [{ name, symbol }]

    signal gewechselt(int index)

    height: Theme.itemSizeMedium
    color: Farben.leiste

    Row {
        anchors.fill: parent

        Repeater {
            model: leiste.reiter
            delegate: MouseArea {
                width: leiste.width / leiste.reiter.length
                height: leiste.height
                onClicked: {
                    leiste.gewaehlt = index
                    leiste.gewechselt(index)
                }

                readonly property bool aktiv: index === leiste.gewaehlt

                Rectangle {
                    anchors.fill: parent
                    visible: parent.pressed
                    color: Qt.rgba(1, 1, 1, 0.15)
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 0

                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: "image://theme/" + modelData.symbol
                               + "?" + (parent.parent.aktiv ? "#ffffff" : "#e7a9a7")
                        width: Theme.iconSizeSmall
                        height: width
                        fillMode: Image.PreserveAspectFit
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        // Nur der gewaehlte Reiter zeigt seinen Namen --
                        // genau wie labelVisibilityMode="selected".
                        visible: parent.parent.aktiv
                        text: modelData.name
                        font.pixelSize: Theme.fontSizeTiny
                        color: "#ffffff"
                    }
                }
            }
        }
    }
}

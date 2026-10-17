import QtQuick 2.6
import Sailfish.Silica 1.0
import "."

/*!
 * Der Minispieler, der in der Android-App ueber der Reiterleiste sitzt
 * (`fragment_mini_player.xml`, schwarzer Grund, 48 dip Bild, darunter
 * Sendung und Titel). Er erscheint nur, wenn etwas laeuft.
 */
Rectangle {
    id: mini

    signal angetippt()

    height: sichtbar ? Theme.itemSizeMedium : 0
    visible: height > 0
    color: Farben.dunkel ? "#000000" : Farben.flaeche

    readonly property bool sichtbar: Spieler.hatQuelle

    Behavior on height { NumberAnimation { duration: 120 } }

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 1
        color: Farben.oe1Rot
    }

    MouseArea {
        anchors.fill: parent
        onClicked: mini.angetippt()
    }

    Row {
        anchors {
            left: parent.left; right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
        }
        spacing: Theme.paddingMedium

        Column {
            width: parent.width - knopf.width - Theme.paddingMedium
            anchors.verticalCenter: parent.verticalCenter

            Label {
                width: parent.width
                text: Spieler.titel
                color: Farben.schrift
                font.pixelSize: Theme.fontSizeSmall
                truncationMode: TruncationMode.Fade
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: Spieler.untertitel
                color: Farben.schriftMatt
                font.pixelSize: Theme.fontSizeTiny
                truncationMode: TruncationMode.Fade
            }
        }

        IconButton {
            palette.primaryColor: Farben.schrift
            palette.highlightColor: Farben.rot
            id: knopf
            anchors.verticalCenter: parent.verticalCenter
            icon.source: Spieler.spielt ? "image://theme/icon-m-pause"
                                        : "image://theme/icon-m-play"
            icon.highlightColor: Farben.oe1Rot
            highlighted: true
            onClicked: Spieler.umschalten()
        }
    }
}

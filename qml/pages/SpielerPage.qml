import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/*! Der grosse Spieler -- was der Minispieler beim Antippen oeffnet. */
Page {
    allowedOrientations: Orientation.All

    Grund {}

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: spalte.height + Theme.paddingLarge

        Column {
            id: spalte
            width: parent.width
            spacing: Theme.paddingMedium

            Titel {
                title: Spieler.istLive ? qsTr("Live") : qsTr("Wiedergabe")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: Spieler.titel
                font.pixelSize: Theme.fontSizeLarge
                color: Farben.schrift
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: text !== ""
                text: Spieler.untertitel
                font.pixelSize: Theme.fontSizeSmall
                color: Farben.schriftMatt
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Spielleiste { width: parent.width }
        }
        VerticalScrollDecorator {}
    }
}

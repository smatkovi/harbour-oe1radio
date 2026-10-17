import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

CoverBackground {
    Column {
        anchors {
            left: parent.left; right: parent.right
            verticalCenter: parent.verticalCenter
            margins: Theme.paddingMedium
        }
        spacing: Theme.paddingSmall

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Ö1"
            font.pixelSize: Theme.fontSizeHuge
            color: Theme.highlightColor
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: Spieler.hatQuelle ? Spieler.titel : qsTr("nicht verbunden")
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            visible: Spieler.schlaeft
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.highlightColor
            text: qsTr("Schlaf %1:%2")
                    .arg(Math.floor(Spieler.schlafRest / 60))
                    .arg(("0" + (Spieler.schlafRest % 60)).slice(-2))
        }
    }

    CoverActionList {
        CoverAction {
            iconSource: Spieler.spielt ? "image://theme/icon-cover-pause"
                                       : "image://theme/icon-cover-play"
            onTriggered: Spieler.umschalten()
        }
        CoverAction {
            iconSource: "image://theme/icon-cover-cancel"
            onTriggered: Spieler.anhalten()
        }
    }
}

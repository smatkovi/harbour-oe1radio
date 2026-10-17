import QtQuick 2.6
import Sailfish.Silica 1.0
import "pages"
import "cover"
import "components"

ApplicationWindow {
    id: app

    initialPage: Component { ShellPage {} }
    cover: Component { CoverPage {} }
    allowedOrientations: defaultAllowedOrientations

    // Der Grund unter allem -- sonst scheint bei Uebergaengen die Ambience
    // durch, obwohl "dunkel" eingestellt ist.
    Grund {}

    // Ein Fehler des Spielers soll nicht in der Stille verschwinden.
    Rectangle {
        id: banner
        z: 1000
        visible: Spieler.fehler !== ""
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: text.height + 2 * Theme.paddingLarge
        color: Theme.rgba(Theme.highlightDimmerColor, 0.95)

        Label {
            id: text
            anchors.centerIn: parent
            width: parent.width - 2 * Theme.horizontalPageMargin
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.errorColor
            text: Spieler.fehler
        }
        MouseArea { anchors.fill: parent; onClicked: Spieler.fehler = "" }
        Timer {
            running: banner.visible
            interval: 6000
            onTriggered: Spieler.fehler = ""
        }
    }
}

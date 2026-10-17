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

    // Der Lader meldete bisher ins Leere: ein gescheiterter Abruf blieb
    // voellig unsichtbar, und ein geglueckter auch. Beides gehoert in das
    // Band unten.
    property string meldung: ""
    Connections {
        target: lader
        onFehler: app.meldung = qsTr("Herunterladen fehlgeschlagen: %1").arg(text)
        onFertig: app.meldung = qsTr("Aufnahme fertig")
    }

    // Ein Fehler des Spielers soll nicht in der Stille verschwinden.
    Rectangle {
        id: banner
        z: 1000
        visible: Spieler.fehler !== "" || app.meldung !== ""
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: text.height + 2 * Theme.paddingLarge
        color: Theme.rgba(Theme.highlightDimmerColor, 0.95)

        Label {
            id: text
            anchors.centerIn: parent
            width: parent.width - 2 * Theme.horizontalPageMargin
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeSmall
            color: Spieler.fehler !== "" ? Theme.errorColor : Farben.rot
            text: Spieler.fehler !== "" ? Spieler.fehler : app.meldung
        }
        MouseArea {
            anchors.fill: parent
            onClicked: { Spieler.fehler = ""; app.meldung = "" }
        }
        Timer {
            running: banner.visible
            interval: 6000
            onTriggered: { Spieler.fehler = ""; app.meldung = "" }
        }
    }
}

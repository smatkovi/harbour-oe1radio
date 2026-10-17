import QtQuick 2.6
import Sailfish.Silica 1.0
import harbour.oe1radio 1.0
import "../components"
import "../views"

/*!
 * Der Rahmen, nach `activity_main.xml` der Android-App gebaut:
 *
 *     Titelzeile oben
 *     Inhalt (der gewaehlte Reiter)
 *     Minispieler, sobald etwas laeuft
 *     rote Reiterleiste ganz unten
 *
 * Silica hat keine unteren Reiter -- die Leiste ist deshalb nachgebaut
 * (TabLeiste.qml). Was in der Android-App unter "Mehr" liegt, haengt hier
 * im Pulley-Menü der Ansichten; das ist auf Sailfish der gewohnte Ort.
 */
Page {
    id: schale
    allowedOrientations: Orientation.All

    readonly property var reiter: [
        { name: qsTr("JETZT"),      symbol: "icon-m-media-radio", quelle: "JetztView.qml" },
        { name: qsTr("7 TAGE"),     symbol: "icon-m-date",        quelle: "TageView.qml" },
        { name: qsTr("HIGHLIGHTS"), symbol: "icon-m-events",      quelle: "HighlightsView.qml" },
        { name: qsTr("JOURNALE"),   symbol: "icon-m-document",    quelle: "JournaleView.qml" },
        { name: qsTr("FAVORITEN"),  symbol: "icon-m-favorite",    quelle: "FavoritenView.qml" }
    ]
    property int gewaehlt: 0

    Rectangle { anchors.fill: parent; color: Farben.grund }

    // --- Titelzeile --------------------------------------------------------
    // Die Android-App setzt den Titel mittig und in Grossbuchstaben.
    Item {
        id: kopf
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: Theme.itemSizeSmall

        Label {
            anchors.centerIn: parent
            text: schale.reiter[schale.gewaehlt].name
            font.pixelSize: Theme.fontSizeLarge
            font.bold: true
            color: Farben.rot
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: Farben.linie
        }
    }

    // --- Inhalt ------------------------------------------------------------
    Loader {
        id: inhalt
        anchors {
            left: parent.left; right: parent.right
            top: kopf.bottom; bottom: mini.top
        }
        clip: true
        source: Qt.resolvedUrl("../views/" + schale.reiter[schale.gewaehlt].quelle)
    }

    // --- Minispieler -------------------------------------------------------
    MiniSpieler {
        id: mini
        anchors { left: parent.left; right: parent.right; bottom: tabs.top }
        onAngetippt: pageStack.push(Qt.resolvedUrl("SpielerPage.qml"))
    }

    // --- Reiterleiste ------------------------------------------------------
    TabLeiste {
        id: tabs
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        reiter: schale.reiter
        gewaehlt: schale.gewaehlt
        onGewechselt: schale.gewaehlt = index
    }

    // Beim Start gleich spielen, wenn so eingestellt (hat die Android-App auch).
    Component.onCompleted: {
        if (Einstellungen.autoplay && !Spieler.hatQuelle)
            Spieler.spieleLive()
    }
}

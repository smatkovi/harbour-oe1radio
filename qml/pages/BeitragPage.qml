import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0
import "../components"

/*!
 * Ein Beitrag ("Highlight"), in der App geoeffnet -- nicht im Browser.
 *
 * Die Android-App macht es genauso: `mobile_navigation.xml` fuehrt von den
 * Stories auf ein `story_detail_dest` mit einem eigenen Fragment, und die
 * Adresse `article-view/broadcast/<id>` liefert dafuer eine fertige
 * HTML-Seite. Die wird hier in einem WebView gezeigt.
 *
 * Darunter bleibt der Weg zur Sendung: der Beitrag nennt den
 * Programmschluessel, damit laesst sich die Sendung aufloesen und anhoeren.
 */
Page {
    id: seite
    allowedOrientations: Orientation.All

    property var beitrag: ({})
    property bool wartet: false

    readonly property string adresse:
        "https://oe1.orf.at/api/v1/app/article-view/broadcast/"
        + (beitrag.schluessel || "")

    Grund {}

    Connections {
        target: oe1
        onSendungGeladen: {
            if (!seite.wartet)
                return
            seite.wartet = false
            pageStack.push(Qt.resolvedUrl("InfoPage.qml"), { sendung: sendung })
        }
    }

    Titel {
        id: kopf
        anchors { left: parent.left; right: parent.right; top: parent.top }
        title: seite.beitrag.stichwort || qsTr("Beitrag")
        description: seite.beitrag.titel || ""
    }

    WebView {
        id: netz
        anchors { left: parent.left; right: parent.right
                  top: kopf.bottom; bottom: leiste.top }
        url: seite.adresse
        // Erst zeigen, wenn sie steht -- sonst blitzt das Weiss der Seite
        // auf, auch wenn die App dunkel eingestellt ist.
        opacity: loading ? 0 : 1
        Behavior on opacity { FadeAnimation {} }
    }

    BusyIndicator {
        // Nicht ueber die palette: der Kringel ist ein HighlightImage
        // im Inneren und nimmt seine Farbe aus dem Theme. Die eigene
        // Eigenschaft "color" wirkt (nachgemessen).
        color: Farben.rot
        anchors.centerIn: netz
        size: BusyIndicatorSize.Large
        running: netz.loading
    }

    Row {
        id: leiste
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom
                  leftMargin: Theme.horizontalPageMargin
                  rightMargin: Theme.horizontalPageMargin
                  bottomMargin: Theme.paddingMedium }
        spacing: Theme.paddingSmall

        Button {
            palette.primaryColor: Farben.schrift
            palette.highlightColor: Farben.rot
            palette.highlightBackgroundColor: Farben.band
            width: (parent.width - Theme.paddingSmall) / 2
            enabled: !!seite.beitrag.schluessel && !!seite.beitrag.tag
            text: qsTr("Zur Sendung")
            onClicked: {
                seite.wartet = true
                oe1.ladeSendungNachSchluessel(seite.beitrag.tag,
                                              seite.beitrag.schluessel)
            }
        }
        Button {
            palette.primaryColor: Farben.schrift
            palette.highlightColor: Farben.rot
            palette.highlightBackgroundColor: Farben.band
            width: (parent.width - Theme.paddingSmall) / 2
            enabled: !!seite.beitrag.seite
            text: qsTr("Im Browser")
            onClicked: Qt.openUrlExternally(seite.beitrag.seite)
        }
    }
}

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

Page {
    id: seite
    allowedOrientations: Orientation.All

    property var sendungen: []
    property string laufendeSendung: ""
    property string naechsteSendung: ""

    Component.onCompleted: ladeHeute()

    function ladeHeute() {
        oe1.ladeTag(oe1.tagVor(0))
    }

    Connections {
        target: oe1
        onTagGeladen: {
            if (datum !== oe1.tagVor(0))
                return
            seite.sendungen = sendungen
            seite.laufendeSendung = ""
            seite.naechsteSendung = ""
            for (var i = 0; i < sendungen.length; i++) {
                if (sendungen[i].laeuftJetzt) {
                    seite.laufendeSendung = sendungen[i].titel
                    if (i + 1 < sendungen.length)
                        seite.naechsteSendung = sendungen[i + 1].zeit + "  "
                                              + sendungen[i + 1].titel
                    break
                }
            }
            if (Spieler.istLive)
                Spieler.untertitel = seite.laufendeSendung
        }
    }

    // Das Programm wechselt; einmal in der Minute nachrechnen reicht, um die
    // laufende Sendung richtig zu halten, ohne neu zu laden.
    Timer {
        running: true
        repeat: true
        interval: 60000
        onTriggered: seite.ladeHeute()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: spalte.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: qsTr("Über")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: qsTr("Podcasts")
                onClicked: pageStack.push(Qt.resolvedUrl("PodcastsPage.qml"))
            }
            MenuItem {
                text: qsTr("7 Tage")
                onClicked: pageStack.push(Qt.resolvedUrl("SchedulePage.qml"))
            }
            MenuItem {
                text: qsTr("Neu laden")
                onClicked: seite.ladeHeute()
            }
        }

        Column {
            id: spalte
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: "Ö1" }

            // --- Was gerade laeuft ---------------------------------------
            Item {
                width: parent.width
                height: Theme.itemSizeLarge

                Column {
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: Theme.horizontalPageMargin
                        rightMargin: Theme.horizontalPageMargin
                    }
                    Label {
                        width: parent.width
                        text: seite.laufendeSendung ? seite.laufendeSendung
                                                    : qsTr("Programm wird geladen …")
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.highlightColor
                        truncationMode: TruncationMode.Fade
                    }
                    Label {
                        width: parent.width
                        visible: seite.naechsteSendung !== ""
                        text: qsTr("danach: %1").arg(seite.naechsteSendung)
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        truncationMode: TruncationMode.Fade
                    }
                }
            }

            // --- Livestream ----------------------------------------------
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Spieler.istLive && Spieler.spielt ? qsTr("Live anhalten")
                                                        : qsTr("Live hören")
                onClicked: {
                    if (Spieler.istLive && Spieler.spielt)
                        Spieler.medien.pause()
                    else
                        Spieler.spieleLive()
                }
            }

            ComboBox {
                width: parent.width
                label: qsTr("Güte")
                currentIndex: Spieler.guete === "hoch" ? 2
                            : Spieler.guete === "mittel" ? 1 : 0
                description: qsTr("Die hohe Güte ist ein HLS-Strom — auf dem N9 unbrauchbar, hier nicht.")
                menu: ContextMenu {
                    MenuItem { text: qsTr("niedrig (32 kbit/s)") }
                    MenuItem { text: qsTr("mittel (128 kbit/s)") }
                    MenuItem { text: qsTr("hoch (HLS)") }
                }
                onCurrentIndexChanged: {
                    Spieler.guete = currentIndex === 2 ? "hoch"
                                  : currentIndex === 1 ? "mittel" : "niedrig"
                    // Laeuft gerade live, dann sofort umstellen.
                    if (Spieler.istLive && Spieler.hatQuelle)
                        Spieler.spieleLive()
                }
            }

            Spielleiste { width: parent.width }

            Separator {
                width: parent.width
                color: Theme.secondaryColor
                horizontalAlignment: Qt.AlignHCenter
            }

            // --- Das heutige Programm ------------------------------------
            SectionHeader { text: qsTr("Heute") }

            Repeater {
                model: seite.sendungen
                delegate: SendungsZeile {
                    width: seite.width
                    sendung: modelData
                }
            }

            Item { width: 1; height: Theme.paddingLarge }
        }

        VerticalScrollDecorator {}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: oe1.busy && seite.sendungen.length === 0
    }
}

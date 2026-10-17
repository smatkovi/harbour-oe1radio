import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/*!
 * "JETZT" -- die Spielerseite, die in der Android-App der erste Reiter ist.
 * Deren fuenf Reiter gibt es auf Sailfish nicht; die anderen vier haengen
 * stattdessen im Pulley-Menü und auf der Seite "Mehr".
 */
Item {
    id: ansicht

    property var sendungen: []
    property string laufendeSendung: ""
    property string naechsteSendung: ""
    property int laufendeId: 0
    property bool wartet: false

    Component.onCompleted: ladeHeute()

    function ladeHeute() {
        oe1.ladeTag(oe1.tagVor(0))
    }

    Connections {
        target: oe1
        onTagGeladen: {
            if (datum !== oe1.tagVor(0))
                return
            ansicht.sendungen = sendungen
            ansicht.laufendeSendung = ""
            ansicht.naechsteSendung = ""
            ansicht.laufendeId = 0
            for (var i = 0; i < sendungen.length; i++) {
                if (sendungen[i].laeuftJetzt) {
                    ansicht.laufendeSendung = sendungen[i].titel
                    ansicht.laufendeId = sendungen[i].id
                    if (i + 1 < sendungen.length)
                        ansicht.naechsteSendung = sendungen[i + 1].zeit + "  "
                                              + sendungen[i + 1].titel
                    break
                }
            }
            if (Spieler.istLive)
                Spieler.untertitel = ansicht.laufendeSendung
        }
        onSendungGeladen: {
            if (ansicht.wartet) {
                ansicht.wartet = false
                pageStack.push(Qt.resolvedUrl("../pages/InfoPage.qml"), { sendung: sendung })
            }
        }
    }

    // Das Programm wechselt; einmal in der Minute nachrechnen haelt die
    // laufende Sendung richtig, ohne neu zu laden.
    Timer {
        running: true
        repeat: true
        interval: 60000
        onTriggered: ansicht.ladeHeute()
    }


    SilicaFlickable {
        anchors.fill: parent
        contentHeight: spalte.height + Theme.paddingLarge

        Pulley {
            PulleyEintrag { text: qsTr("Einstellungen"); onClicked: pageStack.push(Qt.resolvedUrl("../pages/EinstellungenPage.qml")) }
            PulleyEintrag { text: qsTr("Mehr"); onClicked: pageStack.push(Qt.resolvedUrl("../pages/MehrPage.qml")) }
            PulleyEintrag { text: qsTr("Suche"); onClicked: pageStack.push(Qt.resolvedUrl("../pages/SuchePage.qml")) }
            PulleyEintrag { text: qsTr("Neu laden"); onClicked: ansicht.ladeHeute() }
        }

        Column {
            id: spalte
            width: parent.width
            spacing: Theme.paddingMedium


            // --- Was gerade laeuft ---------------------------------------
            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall

                Label {
                    text: qsTr("JETZT")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    font.bold: true
                    color: Farben.rot
                }
                // Umbrechen, nicht abschneiden: ein Sendungstitel geht sich
                // in einer Zeile oft nicht aus, und ein ausgeblendetes Ende
                // sagt dem Hoerer nichts.
                Label {
                    width: parent.width
                    text: ansicht.laufendeSendung ? ansicht.laufendeSendung
                                                : qsTr("Programm wird geladen …")
                    font.pixelSize: Theme.fontSizeLarge
                    color: Farben.schrift
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
                Label {
                    width: parent.width
                    visible: ansicht.naechsteSendung !== ""
                    text: qsTr("danach: %1").arg(ansicht.naechsteSendung)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Farben.kuenftig
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall

                Button {
                    palette.primaryColor: Farben.schrift
                    palette.highlightColor: Farben.rot
                    palette.highlightBackgroundColor: Farben.band
                    width: (parent.width - Theme.paddingSmall) / 2
                    text: Spieler.istLive && Spieler.spielt ? qsTr("Anhalten")
                                                            : qsTr("Live hören")
                    onClicked: {
                        if (Spieler.istLive && Spieler.spielt)
                            Spieler.medien.pause()
                        else
                            Spieler.spieleLive()
                    }
                }
                Button {
                    palette.primaryColor: Farben.schrift
                    palette.highlightColor: Farben.rot
                    palette.highlightBackgroundColor: Farben.band
                    width: (parent.width - Theme.paddingSmall) / 2
                    enabled: ansicht.laufendeId > 0
                    text: qsTr("Info")
                    onClicked: {
                        ansicht.wartet = true
                        oe1.ladeSendung(ansicht.laufendeId)
                    }
                }
            }


            Spielleiste { width: parent.width }

            Separator {
                width: parent.width
                color: Farben.linie
                horizontalAlignment: Qt.AlignHCenter
            }

            Abschnitt { text: qsTr("Heute") }

            Repeater {
                model: ansicht.sendungen
                delegate: SendungsZeile {
                    width: ansicht.width
                    sendung: modelData
                }
            }

            Item { width: 1; height: Theme.paddingLarge }
        }

        VerticalScrollDecorator {}
    }

    BusyIndicator {
        // Nicht ueber die palette: der Kringel ist ein HighlightImage
        // im Inneren und nimmt seine Farbe aus dem Theme. Die eigene
        // Eigenschaft "color" wirkt (nachgemessen).
        color: Farben.rot
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: oe1.busy && ansicht.sendungen.length === 0
    }
}

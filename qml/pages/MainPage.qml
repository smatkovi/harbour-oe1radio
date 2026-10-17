import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/*!
 * "JETZT" -- die Spielerseite, die in der Android-App der erste Reiter ist.
 * Deren fuenf Reiter gibt es auf Sailfish nicht; die anderen vier haengen
 * stattdessen im Pulley-Menü und auf der Seite "Mehr".
 */
Page {
    id: seite
    allowedOrientations: Orientation.All

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
            seite.sendungen = sendungen
            seite.laufendeSendung = ""
            seite.naechsteSendung = ""
            seite.laufendeId = 0
            for (var i = 0; i < sendungen.length; i++) {
                if (sendungen[i].laeuftJetzt) {
                    seite.laufendeSendung = sendungen[i].titel
                    seite.laufendeId = sendungen[i].id
                    if (i + 1 < sendungen.length)
                        seite.naechsteSendung = sendungen[i + 1].zeit + "  "
                                              + sendungen[i + 1].titel
                    break
                }
            }
            if (Spieler.istLive)
                Spieler.untertitel = seite.laufendeSendung
        }
        onSendungGeladen: {
            if (seite.wartet) {
                seite.wartet = false
                pageStack.push(Qt.resolvedUrl("InfoPage.qml"), { sendung: sendung })
            }
        }
    }

    // Das Programm wechselt; einmal in der Minute nachrechnen haelt die
    // laufende Sendung richtig, ohne neu zu laden.
    Timer {
        running: true
        repeat: true
        interval: 60000
        onTriggered: seite.ladeHeute()
    }

    Rectangle { anchors.fill: parent; color: Farben.grund }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: spalte.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem { text: qsTr("Mehr"); onClicked: pageStack.push(Qt.resolvedUrl("MehrPage.qml")) }
            MenuItem { text: qsTr("Suche"); onClicked: pageStack.push(Qt.resolvedUrl("SuchePage.qml")) }
            MenuItem { text: qsTr("Journale"); onClicked: pageStack.push(Qt.resolvedUrl("JournalePage.qml")) }
            MenuItem { text: qsTr("Highlights"); onClicked: pageStack.push(Qt.resolvedUrl("BeitraegePage.qml")) }
            MenuItem { text: qsTr("7 Tage"); onClicked: pageStack.push(Qt.resolvedUrl("SchedulePage.qml")) }
        }

        Column {
            id: spalte
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: "Ö1"
                _titleItem.color: Farben.rot
            }

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
                    text: seite.laufendeSendung ? seite.laufendeSendung
                                                : qsTr("Programm wird geladen …")
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.primaryColor
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
                Label {
                    width: parent.width
                    visible: seite.naechsteSendung !== ""
                    text: qsTr("danach: %1").arg(seite.naechsteSendung)
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
                    width: (parent.width - Theme.paddingSmall) / 2
                    enabled: seite.laufendeId > 0
                    text: qsTr("Info")
                    onClicked: {
                        seite.wartet = true
                        oe1.ladeSendung(seite.laufendeId)
                    }
                }
            }

            ComboBox {
                width: parent.width
                label: qsTr("Güte")
                currentIndex: Spieler.guete === "hoch" ? 2
                            : Spieler.guete === "mittel" ? 1 : 0
                menu: ContextMenu {
                    MenuItem { text: qsTr("niedrig (32 kbit/s)") }
                    MenuItem { text: qsTr("mittel (128 kbit/s)") }
                    MenuItem { text: qsTr("hoch (HLS)") }
                }
                onCurrentIndexChanged: {
                    var neu = currentIndex === 2 ? "hoch"
                            : currentIndex === 1 ? "mittel" : "niedrig"
                    if (neu === Spieler.guete)
                        return
                    Spieler.guete = neu
                    if (Spieler.istLive && Spieler.hatQuelle)
                        Spieler.spieleLive()
                }
            }

            Spielleiste { width: parent.width }

            Separator {
                width: parent.width
                color: Farben.linie
                horizontalAlignment: Qt.AlignHCenter
            }

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

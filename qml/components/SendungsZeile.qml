import QtQuick 2.6
import Sailfish.Silica 1.0
// Das Singleton liegt im selben Ordner -- ein Geschwister wird *nicht*
// von selbst sichtbar, der Ordner muss eigens eingebunden werden.
import "."

/*!
 * Eine Sendung im Tagesprogramm. Antippen holt die Abspieladresse -- die
 * steht nicht im Tagesprogramm, sondern erst in der Einzelabfrage. Was dann
 * damit geschieht, haengt davon ab, was angetippt wurde: Abspielen, Info
 * oder Herunterladen.
 */
ListItem {
    id: zeile

    // Das Band beim Antippen in Ö1-Rot statt in der Ambience-Farbe.
    palette.highlightBackgroundColor: Farben.band

    property var sendung
    readonly property bool abrufbar: sendung && sendung.abrufbar
    readonly property bool laeuft: sendung && sendung.laeuftJetzt
    readonly property bool dieseSpielt: sendung && sendung.id
                                        && Spieler.sendungId === sendung.id
    readonly property string kennung: "sendung:" + (sendung ? sendung.id : 0)
    readonly property double anteil: lader.aufnahmen.length >= 0
                                     ? lader.fortschritt(kennung) : -1

    // Was nach dem Laden geschehen soll: "spielen", "info" oder "laden".
    property string absicht: ""

    contentHeight: Math.max(inhalt.height, Theme.itemSizeExtraSmall)
                   + Theme.paddingMedium
    enabled: abrufbar || laeuft

    Connections {
        target: oe1
        onSendungGeladen: {
            if (!zeile.sendung || zeile.absicht === ""
                    || sendung.id !== zeile.sendung.id)
                return
            var was = zeile.absicht
            zeile.absicht = ""
            if (was === "info") {
                pageStack.push(Qt.resolvedUrl("../pages/InfoPage.qml"),
                               { sendung: sendung })
            } else if (was === "laden") {
                if (sendung.adresse)
                    lader.hole(zeile.kennung, sendung.titel, sendung.adresse)
                else
                    Spieler.fehler = qsTr("Diese Sendung ist nicht zum Nachhören da.")
            } else {
                if (sendung.adresse) {
                    // Liegt sie schon auf dem Geraet, von dort.
                    var da = lader.dateiAdresse(zeile.kennung)
                    Spieler.spieleSendung(sendung.id, sendung.titel, sendung.zeit,
                                          da !== "" ? da : sendung.adresse)
                } else {
                    Spieler.fehler = qsTr("Diese Sendung ist nicht zum Nachhören da.")
                }
            }
        }
    }

    function anstossen(was) {
        zeile.absicht = was
        oe1.ladeSendung(sendung.id)
    }

    menu: ContextMenu {
        backgroundColor: Farben.flaeche
        // Dasselbe wie beim Pulley: das Band unter dem Finger liegt mit
        // 30 % ueber dem Grund und muss sich davon abheben.
        palette.highlightBackgroundColor: Farben.band
        MenuEintrag {
            text: qsTr("Info")
            onClicked: zeile.anstossen("info")
        }
        MenuEintrag {
            visible: zeile.abrufbar && zeile.anteil < 0
            text: qsTr("Herunterladen")
            onClicked: zeile.anstossen("laden")
        }
        MenuEintrag {
            visible: zeile.anteil >= 0 && zeile.anteil < 1
            text: qsTr("Abbruch")
            onClicked: lader.abbrechen(zeile.kennung)
        }
        MenuEintrag {
            visible: zeile.anteil === 1
            text: qsTr("Aufnahme löschen")
            onClicked: lader.loeschen(zeile.kennung)
        }
        MenuEintrag {
            text: merker.gemerkt(zeile.kennung) ? qsTr("Nicht mehr merken")
                                                : qsTr("Als Favorit merken")
            onClicked: merker.umschalten(zeile.kennung, {
                titel: zeile.sendung.titel,
                untertitel: zeile.sendung.zeit || "",
                art: "sendung",
                id: zeile.sendung.id
            })
        }
    }

    onClicked: {
        if (dieseSpielt)
            Spieler.umschalten()
        else if (abrufbar)
            anstossen("spielen")
        else if (laeuft)
            Spieler.spieleLive()
    }

    Rectangle {
        anchors { left: parent.left; bottom: parent.bottom }
        height: Theme.paddingSmall / 2
        width: parent.width * (zeile.anteil > 0 ? zeile.anteil : 0)
        visible: zeile.anteil >= 0 && zeile.anteil < 1
        color: Farben.rot
    }

    Row {
        id: inhalt
        anchors {
            left: parent.left; right: parent.right
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }
        spacing: Theme.paddingMedium

        Label {
            id: uhrzeit
            width: Theme.itemSizeExtraSmall
            anchors.verticalCenter: parent.verticalCenter
            text: sendung ? sendung.zeit : ""
            font.pixelSize: Theme.fontSizeSmall
            color: zeile.laeuft ? Farben.rot
                 : zeile.enabled ? Farben.schriftMatt : Farben.kuenftig
        }

        // Das quadratische Bild der Sendung. Nicht jede hat eines, dann
        // rueckt der Text einfach auf.
        Image {
            id: bild
            width: Theme.itemSizeExtraSmall
            height: width
            anchors.verticalCenter: parent.verticalCenter
            fillMode: Image.PreserveAspectCrop
            clip: true
            asynchronous: true
            source: sendung && sendung.bild ? sendung.bild : ""
            visible: source != "" && status === Image.Ready
            opacity: zeile.enabled ? 1.0 : 0.4
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - uhrzeit.width - marke.width
                   - (bild.visible ? bild.width + Theme.paddingMedium : 0)
                   - 2 * Theme.paddingMedium

            Label {
                width: parent.width
                text: sendung ? sendung.titel : ""
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: zeile.dieseSpielt ? Farben.rot
                     : zeile.enabled ? Farben.schrift : Farben.kuenftig
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: sendung && sendung.untertitel ? sendung.untertitel : ""
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Farben.schriftMatt
                truncationMode: TruncationMode.Fade
            }
        }

        // Waehrend des Abrufs der Anteil in Prozent, danach das Zeichen.
        // Vorher stand hier bis zum Schluss nichts, und ein Abruf von einer
        // halben Minute sah aus wie ein toter Menuepunkt.
        Label {
            id: marke
            anchors.verticalCenter: parent.verticalCenter
            text: zeile.anteil >= 0 && zeile.anteil < 1
                    ? Math.round(zeile.anteil * 100) + " %"
                : zeile.dieseSpielt && Spieler.spielt ? "▮▮"
                : zeile.laeuft ? qsTr("live")
                : zeile.anteil === 1 ? "↓" : ""
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Farben.rot
        }
    }
}

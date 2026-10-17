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

    contentHeight: inhalt.height + Theme.paddingMedium
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
        MenuItem {
            visible: zeile.abrufbar && zeile.anteil < 0
            text: qsTr("Herunterladen")
            onClicked: zeile.anstossen("laden")
        }
        MenuItem {
            visible: zeile.anteil >= 0 && zeile.anteil < 1
            text: qsTr("Abbruch")
            onClicked: lader.abbrechen(zeile.kennung)
        }
        MenuItem {
            visible: zeile.anteil === 1
            text: qsTr("Aufnahme löschen")
            onClicked: lader.loeschen(zeile.kennung)
        }
        MenuItem {
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
            text: sendung ? sendung.zeit : ""
            font.pixelSize: Theme.fontSizeSmall
            color: zeile.laeuft ? Farben.rot
                 : zeile.enabled ? Farben.schriftMatt : Farben.kuenftig
        }

        Column {
            width: parent.width - uhrzeit.width - marke.width - 2 * Theme.paddingMedium

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

        Label {
            id: marke
            anchors.verticalCenter: parent.verticalCenter
            text: zeile.dieseSpielt && Spieler.spielt ? "▮▮"
                : zeile.laeuft ? qsTr("live")
                : zeile.anteil === 1 ? "↓" : ""
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Farben.rot
        }
    }
}

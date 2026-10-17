import QtQuick 2.6
import Sailfish.Silica 1.0
// Das Singleton liegt im selben Ordner -- ein Geschwister wird *nicht*
// von selbst sichtbar, der Ordner muss eigens eingebunden werden.
import "."

/*!
 * Eine Sendung im Tagesprogramm. Antippen holt die Abspieladresse -- die
 * steht nicht im Tagesprogramm, sondern erst in der Einzelabfrage.
 */
ListItem {
    id: zeile

    property var sendung
    readonly property bool abrufbar: sendung && sendung.abrufbar
    readonly property bool laeuft: sendung && sendung.laeuftJetzt
    readonly property bool dieseSpielt: sendung && Spieler.sendungId === sendung.id

    contentHeight: inhalt.height + Theme.paddingMedium
    enabled: abrufbar || laeuft

    Connections {
        target: oe1
        onSendungGeladen: {
            if (!zeile.sendung || sendung.id !== zeile.sendung.id)
                return
            if (sendung.adresse)
                Spieler.spieleSendung(sendung.id, sendung.titel,
                                      sendung.zeit, sendung.adresse)
            else
                Spieler.fehler = qsTr("Diese Sendung ist nicht zum Nachhören da.")
        }
    }

    onClicked: {
        if (dieseSpielt) {
            Spieler.umschalten()
        } else if (abrufbar) {
            oe1.ladeSendung(sendung.id)
        } else if (laeuft) {
            Spieler.spieleLive()
        }
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
            color: zeile.laeuft ? Theme.highlightColor : Theme.secondaryColor
        }

        Column {
            width: parent.width - uhrzeit.width - marke.width - 2 * Theme.paddingMedium

            Label {
                width: parent.width
                text: sendung ? sendung.titel : ""
                truncationMode: TruncationMode.Fade
                color: zeile.dieseSpielt ? Theme.highlightColor
                     : zeile.enabled ? Theme.primaryColor : Theme.secondaryColor
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: sendung && sendung.untertitel ? sendung.untertitel : ""
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                truncationMode: TruncationMode.Fade
            }
        }

        Label {
            id: marke
            anchors.verticalCenter: parent.verticalCenter
            text: zeile.dieseSpielt && Spieler.spielt ? "▮▮"
                : zeile.laeuft ? qsTr("live") : ""
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.highlightColor
        }
    }
}

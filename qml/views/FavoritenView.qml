import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/*! Favoriten. Die Android-App hat kein Konto, also bleibt die Liste hier. */
Item {
    id: ansicht
    property bool wartet: false

    Connections {
        target: oe1
        onSendungGeladen: {
            if (ansicht.wartet) {
                ansicht.wartet = false
                pageStack.push(Qt.resolvedUrl("../pages/InfoPage.qml"), { sendung: sendung })
            }
        }
    }


    SilicaListView {
        anchors.fill: parent

        Pulley {
            PulleyEintrag { text: qsTr("Einstellungen"); onClicked: pageStack.push(Qt.resolvedUrl("../pages/EinstellungenPage.qml")) }
            PulleyEintrag { text: qsTr("Mehr"); onClicked: pageStack.push(Qt.resolvedUrl("../pages/MehrPage.qml")) }
            PulleyEintrag { text: qsTr("Suche"); onClicked: pageStack.push(Qt.resolvedUrl("../pages/SuchePage.qml")) }
        }
        model: merker.eintraege

        delegate: ListItem {
            // Das Band beim Antippen in Ö1-Rot statt in der Ambience-Farbe.
            palette.highlightBackgroundColor: Farben.rot
            id: zeile
            contentHeight: inhalt.height + Theme.paddingMedium

            function entfernen() {
                remorseAction(qsTr("Entfernen"),
                              function() { merker.vergessen(modelData.kennung) })
            }

            menu: ContextMenu {
                backgroundColor: Farben.flaeche
                palette.highlightBackgroundColor: Farben.rot
                MenuEintrag { text: qsTr("Entfernen"); onClicked: zeile.entfernen() }
            }

            onClicked: {
                if (modelData.art === "sendung" && modelData.id) {
                    ansicht.wartet = true
                    oe1.ladeSendung(modelData.id)
                } else if (modelData.adresse) {
                    Spieler.spieleSendung(0, modelData.titel,
                                          modelData.untertitel || "", modelData.adresse)
                }
            }

            Column {
                id: inhalt
                anchors {
                    left: parent.left; right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                Label {
                    width: parent.width
                    text: modelData.titel || ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Label {
                    width: parent.width
                    visible: text !== ""
                    text: modelData.untertitel || ""
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Farben.schriftMatt
                    truncationMode: TruncationMode.Fade
                }
            }
        }

        ViewPlaceholder {
            palette.primaryColor: Farben.schrift
            palette.secondaryColor: Farben.schriftMatt
            palette.highlightColor: Farben.rot
            enabled: merker.eintraege.length === 0
            text: qsTr("Keine Favoriten")
            hintText: qsTr("In der Info einer Sendung oder Folge „Als Favorit merken“.")
        }
        VerticalScrollDecorator {}
    }
}

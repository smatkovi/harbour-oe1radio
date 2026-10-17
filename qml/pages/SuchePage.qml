import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/*!
 * Suche. Die ORF-Schnittstelle kann keine -- gesucht wird in den sieben
 * Tagen, die sie vorhaelt, und zwar im Hintergrund (api.cpp holt die noch
 * fehlenden Tage nach und meldet sich dann).
 */
Page {
    id: seite
    allowedOrientations: Orientation.All

    property var treffer: []
    property bool gesucht: false
    property bool wartet: false

    Connections {
        target: oe1
        onSucheFertig: {
            seite.treffer = treffer
            seite.gesucht = true
        }
        onSendungGeladen: {
            if (seite.wartet) {
                seite.wartet = false
                pageStack.push(Qt.resolvedUrl("InfoPage.qml"), { sendung: sendung })
            }
        }
    }

    Rectangle { anchors.fill: parent; color: Farben.grund }

    SilicaListView {
        anchors.fill: parent
        model: seite.treffer

        header: Column {
            width: seite.width
            Titel {
                title: qsTr("Suche")
            }
            SearchField {
                palette.primaryColor: Farben.schrift
                palette.secondaryColor: Farben.schriftMatt
                palette.highlightColor: Farben.rot
                width: parent.width
                placeholderText: qsTr("Sendung suchen")
                inputMethodHints: Qt.ImhNoPredictiveText
                EnterKey.onClicked: { focus = false; oe1.suche(text) }
                onTextChanged: {
                    seite.gesucht = false
                    suchUhr.restart()
                }
                Timer {
                    id: suchUhr
                    interval: 500   // nicht bei jedem Tastendruck sieben Tage filtern
                    onTriggered: oe1.suche(parent.text)
                }
            }
        }

        delegate: ListItem {
            // Das Band beim Antippen in Ö1-Rot statt in der Ambience-Farbe.
            palette.highlightBackgroundColor: Farben.rot
            contentHeight: inhalt.height + Theme.paddingMedium
            onClicked: {
                seite.wartet = true
                oe1.ladeSendung(modelData.id)
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
                    text: (modelData.zeit || "")
                          + (modelData.untertitel ? "  ·  " + modelData.untertitel : "")
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
            enabled: seite.gesucht && seite.treffer.length === 0
            text: qsTr("Nichts gefunden")
            hintText: qsTr("Gesucht wird in den sieben Tagen, die der ORF vorhält.")
        }
        VerticalScrollDecorator {}
    }

    BusyIndicator {
        palette.highlightColor: Farben.rot
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: oe1.busy && !seite.gesucht
    }
}

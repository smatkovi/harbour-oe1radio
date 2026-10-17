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
            PageHeader {
                title: qsTr("Suche")
                _titleItem.color: Farben.rot
            }
            SearchField {
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
                    color: Theme.secondaryColor
                    truncationMode: TruncationMode.Fade
                }
            }
        }

        ViewPlaceholder {
            enabled: seite.gesucht && seite.treffer.length === 0
            text: qsTr("Nichts gefunden")
            hintText: qsTr("Gesucht wird in den sieben Tagen, die der ORF vorhält.")
        }
        VerticalScrollDecorator {}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: oe1.busy && !seite.gesucht
    }
}

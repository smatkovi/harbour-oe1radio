import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/*! "Highlights" der Android-App: die Beitraege der Ö1-Startseite. */
Page {
    id: seite
    allowedOrientations: Orientation.All

    property var beitraege: []

    Component.onCompleted: oe1.ladeBeitraege(0)

    Connections {
        target: oe1
        onBeitraegeGeladen: seite.beitraege = beitraege
        onSendungGeladen: {
            if (seite.status === PageStatus.Active && seite.wartet) {
                seite.wartet = false
                pageStack.push(Qt.resolvedUrl("InfoPage.qml"), { sendung: sendung })
            }
        }
    }
    property bool wartet: false

    Rectangle { anchors.fill: parent; color: Farben.grund }

    SilicaListView {
        anchors.fill: parent
        model: seite.beitraege
        header: PageHeader {
            title: qsTr("Highlights")
            _titleItem.color: Farben.rot
        }

        PullDownMenu {
            MenuItem { text: qsTr("Neu laden"); onClicked: oe1.ladeBeitraege(0) }
        }

        delegate: ListItem {
            contentHeight: inhalt.height + Theme.paddingLarge

            onClicked: {
                // Der Beitrag nennt den Programmschluessel, nicht die
                // Sendungsnummer -- erst aufloesen, dann die Infoseite.
                if (modelData.schluessel && modelData.tag) {
                    seite.wartet = true
                    oe1.ladeSendungNachSchluessel(modelData.tag, modelData.schluessel)
                } else if (modelData.seite) {
                    Qt.openUrlExternally(modelData.seite)
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

                Image {
                    id: bild
                    width: Theme.itemSizeLarge
                    height: width * 0.66
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    asynchronous: true
                    source: modelData.bild || ""
                    visible: source != ""
                }

                Column {
                    width: parent.width - (bild.visible ? bild.width + Theme.paddingMedium : 0)

                    Label {
                        width: parent.width
                        visible: text !== ""
                        text: modelData.stichwort || ""
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Farben.rot
                    }
                    Label {
                        width: parent.width
                        text: modelData.titel || ""
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }
        }

        ViewPlaceholder {
            enabled: seite.beitraege.length === 0 && !oe1.busy
            text: qsTr("Keine Beiträge")
        }
        VerticalScrollDecorator {}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: oe1.busy && seite.beitraege.length === 0
    }
}

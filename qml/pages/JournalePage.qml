import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/*!
 * Die Journale, nach Tag und Sendung gruppiert. Ein Stueck verweist ueber
 * Tag + Programmschluessel auf die Sendung -- die Schnittstelle gibt dafuer
 * keine fertige Tonadresse her, sie muss erst aufgeloest werden.
 */
Page {
    id: seite
    allowedOrientations: Orientation.All

    property var tage: []
    property bool wartet: false

    Component.onCompleted: oe1.ladeJournale()

    Connections {
        target: oe1
        onJournaleGeladen: seite.tage = tage
        onSendungGeladen: {
            if (seite.wartet) {
                seite.wartet = false
                pageStack.push(Qt.resolvedUrl("InfoPage.qml"), { sendung: sendung })
            }
        }
    }

    Rectangle { anchors.fill: parent; color: Farben.grund }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: spalte.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem { text: qsTr("Neu laden"); onClicked: oe1.ladeJournale() }
        }

        Column {
            id: spalte
            width: parent.width

            PageHeader {
                title: qsTr("Journale")
                _titleItem.color: Farben.rot
            }

            Repeater {
                model: seite.tage
                delegate: Column {
                    width: spalte.width
                    property var tagDaten: modelData

                    SectionHeader { text: modelData.name || "" }

                    Repeater {
                        model: modelData.journale
                        delegate: Column {
                            width: spalte.width
                            property var journal: modelData

                            Item {
                                width: parent.width
                                height: kopf.height + Theme.paddingMedium
                                Label {
                                    id: kopf
                                    x: Theme.horizontalPageMargin
                                    width: parent.width - 2 * Theme.horizontalPageMargin
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (journal.zeit ? journal.zeit + "  " : "") + journal.titel
                                    color: Theme.highlightColor
                                    truncationMode: TruncationMode.Fade
                                }
                            }

                            Repeater {
                                model: journal.stuecke
                                delegate: ListItem {
                                    width: spalte.width
                                    contentHeight: zeile.height + Theme.paddingSmall

                                    onClicked: {
                                        if (modelData.tag && modelData.schluessel) {
                                            seite.wartet = true
                                            oe1.ladeSendungNachSchluessel(
                                                modelData.tag, modelData.schluessel)
                                        }
                                    }

                                    Row {
                                        id: zeile
                                        anchors {
                                            left: parent.left; right: parent.right
                                            leftMargin: Theme.horizontalPageMargin
                                            rightMargin: Theme.horizontalPageMargin
                                            verticalCenter: parent.verticalCenter
                                        }
                                        spacing: Theme.paddingMedium

                                        Label {
                                            id: uhr
                                            width: Theme.itemSizeExtraSmall
                                            text: modelData.zeit || ""
                                            font.pixelSize: Theme.fontSizeExtraSmall
                                            color: Farben.rot
                                        }
                                        Label {
                                            width: parent.width - uhr.width - Theme.paddingMedium
                                            text: modelData.titel || ""
                                            wrapMode: Text.Wrap
                                            maximumLineCount: 2
                                            elide: Text.ElideRight
                                            font.pixelSize: Theme.fontSizeSmall
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ViewPlaceholder {
                enabled: seite.tage.length === 0 && !oe1.busy
                text: qsTr("Keine Journale")
            }
        }
        VerticalScrollDecorator {}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: oe1.busy && seite.tage.length === 0
    }
}

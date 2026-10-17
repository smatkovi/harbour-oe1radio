import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

Page {
    id: seite
    allowedOrientations: Orientation.All

    Grund {}

    property var podcasts: []

    Component.onCompleted: oe1.ladePodcasts()

    Connections {
        target: oe1
        onPodcastsGeladen: seite.podcasts = podcasts
    }

    SilicaListView {
        anchors.fill: parent
        model: seite.podcasts
        header: Titel {
            title: qsTr("Podcasts")
        }

        Pulley {
            PulleyEintrag {
                text: qsTr("Neu laden")
                onClicked: oe1.ladePodcasts()
            }
        }

        delegate: ListItem {
            // Das Band beim Antippen in Ö1-Rot statt in der Ambience-Farbe.
            palette.highlightBackgroundColor: Farben.band
            contentHeight: Math.max(zeilen.height, Theme.itemSizeSmall)
                           + Theme.paddingMedium

            onClicked: pageStack.push(Qt.resolvedUrl("PodcastPage.qml"), {
                podcastId: modelData.id,
                podcastTitel: modelData.titel
            })

            Row {
                id: zeilen
                anchors {
                    left: parent.left; right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                spacing: Theme.paddingMedium

                Image {
                    id: bild
                    width: Theme.itemSizeSmall
                    height: width
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    asynchronous: true
                    source: modelData.bild || ""
                    visible: source != "" && status === Image.Ready
                }

                Column {
                    width: parent.width
                           - (bild.visible ? bild.width + Theme.paddingMedium : 0)
                    anchors.verticalCenter: parent.verticalCenter

                    Label {
                        width: parent.width
                        text: modelData.titel
                        truncationMode: TruncationMode.Fade
                        color: Farben.schrift
                    }
                    Label {
                        width: parent.width
                        visible: text !== ""
                        text: modelData.text || ""
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Farben.schriftMatt
                    }
                    Label {
                        width: parent.width
                        text: qsTr("%1 Folgen").arg(modelData.anzahl)
                        font.pixelSize: Theme.fontSizeTiny
                        color: Farben.kuenftig
                    }
                }
            }
        }

        ViewPlaceholder {
            palette.primaryColor: Farben.schrift
            palette.secondaryColor: Farben.schriftMatt
            palette.highlightColor: Farben.rot
            enabled: seite.podcasts.length === 0 && !oe1.busy
            text: qsTr("Keine Podcasts")
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
        running: oe1.busy && seite.podcasts.length === 0
    }
}

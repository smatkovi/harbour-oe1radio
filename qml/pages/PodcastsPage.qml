import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

Page {
    id: seite
    allowedOrientations: Orientation.All

    Rectangle { anchors.fill: parent; color: Farben.grund }

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
            palette.highlightBackgroundColor: Farben.rot
            contentHeight: zeilen.height + Theme.paddingMedium

            onClicked: pageStack.push(Qt.resolvedUrl("PodcastPage.qml"), {
                podcastId: modelData.id,
                podcastTitel: modelData.titel
            })

            Column {
                id: zeilen
                anchors {
                    left: parent.left; right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                Label {
                    width: parent.width
                    text: modelData.titel
                    truncationMode: TruncationMode.Fade
                }
                Label {
                    width: parent.width
                    text: qsTr("%1 Folgen").arg(modelData.anzahl)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Farben.schriftMatt
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
        palette.highlightColor: Farben.rot
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: oe1.busy && seite.podcasts.length === 0
    }
}

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/*!
 * Die Folgen eines Podcasts. Sie stehen nicht in der JSON-Schnittstelle --
 * die nennt nur die Adresse des RSS-Feeds, und den liest api.cpp.
 */
Page {
    id: seite
    allowedOrientations: Orientation.All

    property int podcastId: 0
    property string podcastTitel: ""
    property var folgen: []

    Component.onCompleted: oe1.ladeFolgen(podcastId)

    Connections {
        target: oe1
        onFolgenGeladen: seite.folgen = folgen
    }

    SilicaListView {
        anchors.fill: parent
        model: seite.folgen

        header: Column {
            width: seite.width
            PageHeader { title: seite.podcastTitel }
            Spielleiste { width: parent.width }
        }

        delegate: ListItem {
            id: zeile
            contentHeight: zeilen.height + Theme.paddingMedium

            readonly property bool dieseSpielt:
                Spieler.hatQuelle && Spieler.titel === modelData.titel

            onClicked: {
                if (dieseSpielt)
                    Spieler.umschalten()
                else
                    Spieler.spieleSendung(0, modelData.titel,
                                          modelData.datum, modelData.adresse)
            }

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
                    color: zeile.dieseSpielt ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    text: modelData.datum
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }
        }

        ViewPlaceholder {
            enabled: seite.folgen.length === 0 && !oe1.busy
            text: qsTr("Keine Folgen")
        }

        VerticalScrollDecorator {}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: oe1.busy && seite.folgen.length === 0
    }
}

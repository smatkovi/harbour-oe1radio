import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/*!
 * Alles, was der Dienst ueber einen Podcast hergibt, auf einer eigenen
 * Seite -- erreichbar aus der Liste (Kontextmenü) und aus der Folgenliste
 * (Pulley).
 *
 * Die Seite holt die Angaben selbst nach (`ladePodcast`), denn aus der
 * Liste heraus sind nur Titel, Bild und Zahl der Folgen bekannt; Autor,
 * Rechte, Sprache und die Adressen stehen erst in der Einzelabfrage.
 */
Page {
    id: seite
    allowedOrientations: Orientation.All

    property int podcastId: 0
    //! Was aus der Liste schon bekannt ist -- damit die Seite nicht leer
    //! aufgeht, waehrend der Rest noch unterwegs ist.
    property var podcast: ({})

    Component.onCompleted: oe1.ladePodcast(podcastId)

    Connections {
        target: oe1
        onPodcastGeladen: seite.podcast = podcast
    }

    Grund {}

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: spalte.height + Theme.paddingLarge

        Pulley {
            PulleyEintrag {
                visible: !!seite.podcast.seite
                text: qsTr("Im Browser öffnen")
                onClicked: Qt.openUrlExternally(seite.podcast.seite)
            }
            PulleyEintrag {
                visible: !!seite.podcast.spotify
                text: qsTr("Bei Spotify öffnen")
                onClicked: Qt.openUrlExternally(seite.podcast.spotify)
            }
            PulleyEintrag {
                visible: !!seite.podcast.feed
                text: qsTr("Feed-Adresse kopieren")
                onClicked: Clipboard.text = seite.podcast.feed
            }
        }

        Column {
            id: spalte
            width: parent.width
            spacing: Theme.paddingMedium

            Titel {
                title: seite.podcast.titel || qsTr("Podcast")
                description: seite.podcast.autor || ""
            }

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width - 2 * Theme.horizontalPageMargin,
                                Theme.itemSizeHuge * 2)
                height: width
                fillMode: Image.PreserveAspectCrop
                clip: true
                asynchronous: true
                source: seite.podcast.bild || ""
                visible: source != "" && status === Image.Ready
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: text !== ""
                text: seite.podcast.text || ""
                wrapMode: Text.Wrap
                textFormat: Text.StyledText
                font.pixelSize: Theme.fontSizeSmall
                color: Farben.schrift
                linkColor: Farben.rot
                onLinkActivated: Qt.openUrlExternally(link)
            }

            Abschnitt { text: qsTr("Angaben") }

            Repeater {
                model: [
                    { name: qsTr("Folgen"),  wert: seite.podcast.anzahl > 0
                                                   ? String(seite.podcast.anzahl) : "" },
                    { name: qsTr("Fächer"),  wert: seite.podcast.faecher || "" },
                    { name: qsTr("Sprache"), wert: seite.podcast.sprache || "" },
                    { name: qsTr("Inhaber"), wert: seite.podcast.inhaber || "" },
                    { name: qsTr("Post"),    wert: seite.podcast.post || "" },
                    { name: qsTr("Rechte"),  wert: seite.podcast.rechte || "" }
                ]
                delegate: Item {
                    width: spalte.width
                    height: modelData.wert !== "" ? reihe.height + Theme.paddingSmall : 0
                    visible: modelData.wert !== ""

                    Row {
                        id: reihe
                        anchors {
                            left: parent.left; right: parent.right
                            leftMargin: Theme.horizontalPageMargin
                            rightMargin: Theme.horizontalPageMargin
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Theme.paddingMedium

                        Label {
                            id: schild
                            width: Theme.itemSizeSmall
                            text: modelData.name
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Farben.schriftMatt
                        }
                        Label {
                            width: parent.width - schild.width - Theme.paddingMedium
                            text: modelData.wert
                            wrapMode: Text.Wrap
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Farben.schrift
                        }
                    }
                }
            }

            Button {
                palette.primaryColor: Farben.schrift
                palette.highlightColor: Farben.rot
                palette.highlightBackgroundColor: Farben.band
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Folgen anzeigen")
                onClicked: pageStack.push(Qt.resolvedUrl("PodcastPage.qml"), {
                    podcastId: seite.podcastId,
                    podcastTitel: seite.podcast.titel || ""
                })
            }
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
        running: oe1.busy && !seite.podcast.titel
    }
}

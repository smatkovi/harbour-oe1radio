import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/*! "Mehr" wie in der Android-App: was nicht auf die Hauptseite passt. */
Page {
    allowedOrientations: Orientation.All

    Rectangle { anchors.fill: parent; color: Farben.grund }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: spalte.height + Theme.paddingLarge

        Column {
            id: spalte
            width: parent.width

            PageHeader {
                title: qsTr("Mehr")
                _titleItem.color: Farben.rot
            }

            Repeater {
                // Highlights, Journale und Favoriten sind jetzt eigene
                // Reiter unten -- hier steht nur noch, was dort nicht
                // hinpasst. Genau wie "Mehr" in der Android-App.
                model: [
                    { name: qsTr("Podcasts"),      ziel: "PodcastsPage.qml" },
                    { name: qsTr("Suche"),         ziel: "SuchePage.qml" },
                    { name: qsTr("Aufnahmen"),     ziel: "AufnahmenPage.qml" },
                    { name: qsTr("Einstellungen"), ziel: "EinstellungenPage.qml" },
                    { name: qsTr("Über"),          ziel: "AboutPage.qml" }
                ]
                delegate: ListItem {
                    width: spalte.width
                    onClicked: pageStack.push(Qt.resolvedUrl(modelData.ziel))
                    Label {
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: Farben.schrift
                    }
                }
            }
        }
        VerticalScrollDecorator {}
    }
}

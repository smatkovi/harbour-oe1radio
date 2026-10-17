import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

Page {
    allowedOrientations: Orientation.All

    Rectangle { anchors.fill: parent; color: Farben.grund }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: spalte.height + Theme.paddingLarge

        Column {
            id: spalte
            width: parent.width
            spacing: Theme.paddingMedium

            Titel {
                title: qsTr("Über")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("Ö1 Radio %1").arg(appVersion)
                color: Farben.rot
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Farben.schriftMatt
                text: qsTr("Der Livestream, die sieben Tage zum Nachhören und die \
Podcasts von Ö1. Die Sendungsdaten kommen von der offenen Schnittstelle des ORF \
(audioapi.orf.at).\n\nWeder vom ORF herausgegeben noch unterstützt.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Farben.schriftMatt
                text: qsTr("Die Schwesterfassung für MeeGo Harmattan (Nokia N9/N950) \
braucht ein fremdes wget und einen Vermittler auf der Rückschleife, weil Qt 4.7 und \
gstreamer dort kein TLS können. Auf Sailfish fällt beides weg.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Farben.schriftMatt
                text: "GPL-3.0-or-later\ngithub.com/smatkovi/harbour-oe1radio"
            }
        }
        VerticalScrollDecorator {}
    }
}

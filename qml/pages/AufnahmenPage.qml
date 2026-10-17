import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/*!
 * Was auf dem Geraet liegt. Die Android-App kann das nicht -- hier schon,
 * weil ein Zug durch Oesterreich mehr Funkloecher hat als die Sendung Pausen.
 */
Page {
    id: seite
    allowedOrientations: Orientation.All

    Rectangle { anchors.fill: parent; color: Farben.grund }

    SilicaListView {
        anchors.fill: parent
        model: lader.aufnahmen
        header: PageHeader {
            title: qsTr("Aufnahmen")
            _titleItem.color: Farben.rot
        }

        delegate: ListItem {
            id: zeile
            contentHeight: inhalt.height + Theme.paddingMedium

            menu: ContextMenu {
                MenuItem {
                    visible: modelData.laeuft
                    text: qsTr("Abbrechen")
                    onClicked: lader.abbrechen(modelData.kennung)
                }
                MenuItem {
                    visible: !modelData.laeuft
                    text: qsTr("Löschen")
                    onClicked: zeile.remorseAction(qsTr("Löschen"), function() {
                        lader.loeschen(modelData.kennung)
                    })
                }
            }

            onClicked: {
                if (!modelData.laeuft)
                    Spieler.spieleSendung(0, modelData.titel, "",
                                          lader.dateiAdresse(modelData.kennung))
            }

            Column {
                id: inhalt
                anchors {
                    left: parent.left; right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                spacing: Theme.paddingSmall

                Label {
                    width: parent.width
                    text: modelData.titel || ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                ProgressBar {
                    width: parent.width
                    visible: modelData.laeuft
                    minimumValue: 0
                    maximumValue: 1
                    value: modelData.anteil
                    label: Math.round(modelData.anteil * 100) + " %"
                }
                Label {
                    width: parent.width
                    visible: !modelData.laeuft
                    text: (modelData.groesse / 1048576).toFixed(1) + " MB"
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Farben.schriftMatt
                }
            }
        }

        ViewPlaceholder {
            enabled: lader.aufnahmen.length === 0
            text: qsTr("Keine Aufnahmen")
            hintText: qsTr("In der Info einer Sendung oder bei einer Podcastfolge „Herunterladen“.")
        }
        VerticalScrollDecorator {}
    }
}

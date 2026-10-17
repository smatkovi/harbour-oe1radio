import QtQuick 2.6
import Sailfish.Silica 1.0
// Das Singleton liegt im selben Ordner -- ein Geschwister wird *nicht*
// von selbst sichtbar, der Ordner muss eigens eingebunden werden.
import "."

/*!
 * Die Steuerung dessen, was gerade laeuft: Titel, Fortschritt, Spulen,
 * Einschlafzeit. Steht auf jeder Seite, die sie braucht, und liest alles
 * aus dem Singleton -- so zeigen alle dasselbe an.
 */
Column {
    id: leiste
    spacing: Theme.paddingSmall
    visible: Spieler.hatQuelle

    Separator {
        width: parent.width
        color: Theme.secondaryColor
        horizontalAlignment: Qt.AlignHCenter
    }

    Item {
        width: parent.width
        height: zeilen.height + Theme.paddingMedium

        Column {
            id: zeilen
            anchors {
                left: parent.left; right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.horizontalPageMargin
            }

            Label {
                width: parent.width
                text: Spieler.titel
                color: Theme.highlightColor
                truncationMode: TruncationMode.Fade
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: Spieler.untertitel
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                truncationMode: TruncationMode.Fade
            }
        }
    }

    // Fortschritt gibt es nur bei einer Aufzeichnung; ein Livestrom hat
    // weder Laenge noch Position.
    Slider {
        width: parent.width
        visible: Spieler.spulbar && Spieler.dauer > 0
        minimumValue: 0
        maximumValue: Spieler.dauer > 0 ? Spieler.dauer : 1
        value: Spieler.position
        valueText: zeitText(Spieler.position) + " / " + zeitText(Spieler.dauer)
        onReleased: Spieler.setzePosition(value)

        function zeitText(ms) {
            if (!ms || ms < 0) return "0:00"
            var s = Math.floor(ms / 1000)
            var h = Math.floor(s / 3600)
            var m = Math.floor((s % 3600) / 60)
            s = s % 60
            if (h > 0)
                return h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
            return m + ":" + (s < 10 ? "0" : "") + s
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.paddingLarge

        // Die Sprungweite richtet sich nach dem Symbol: Silica hat nur ein
        // Zehn-Sekunden-Paar (icon-m-backward gibt es gar nicht), und ein
        // Symbol, auf dem "10s" steht, soll nicht 30 s springen.
        IconButton {
            icon.source: "image://theme/icon-m-10s-back"
            visible: Spieler.spulbar
            onClicked: Spieler.spulen(-10000)
        }
        IconButton {
            icon.source: Spieler.spielt ? "image://theme/icon-l-pause"
                                        : "image://theme/icon-l-play"
            onClicked: Spieler.umschalten()
        }
        IconButton {
            icon.source: "image://theme/icon-m-10s-forward"
            visible: Spieler.spulbar
            onClicked: Spieler.spulen(10000)
        }
        IconButton {
            icon.source: "image://theme/icon-m-clear"
            onClicked: Spieler.anhalten()
        }
    }

    BusyIndicator {
        anchors.horizontalCenter: parent.horizontalCenter
        size: BusyIndicatorSize.Small
        running: Spieler.laedt
    }

    // --- Einschlafzeit ----------------------------------------------------
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.paddingMedium
        visible: !Spieler.schlaeft

        Repeater {
            model: [15, 30, 60]
            delegate: Button {
                text: qsTr("%1 min").arg(modelData)
                onClicked: Spieler.schlafStarten(modelData)
            }
        }
    }

    Button {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: Spieler.schlaeft
        text: qsTr("Schlaf in %1:%2 — abbrechen")
                .arg(Math.floor(Spieler.schlafRest / 60))
                .arg(("0" + (Spieler.schlafRest % 60)).slice(-2))
        onClicked: Spieler.schlafAbbrechen()
    }
}

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
        color: Farben.schriftMatt
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

            // Umbrechen statt abschneiden: Sendungstitel wie
            // "Ö1 Kulturjournal: Die Diagonale in Graz" gehen sich in einer
            // Zeile nicht aus, und ein ausgeblendetes Ende sagt nichts.
            Label {
                width: parent.width
                text: Spieler.titel
                color: Farben.rot
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: Spieler.untertitel
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Farben.schriftMatt
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
    }

    // Fortschritt gibt es nur bei einer Aufzeichnung; ein Livestrom hat
    // weder Laenge noch Position.
    Slider {
        palette.primaryColor: Farben.schrift
        palette.secondaryColor: Farben.schriftMatt
        palette.highlightColor: Farben.rot
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

        // Die Android-App springt 15 Minuten ("15 Minuten zurueck springen"
        // steht so in ihren Zeichenketten), also hier auch. Silica hat dafuer
        // kein Symbol -- das Zehn-Sekunden-Paar waere gelogen, deshalb die
        // schlichten Pfeile mit der Weite als Beschriftung daneben.
        IconButton {
            palette.primaryColor: Farben.schrift
            palette.highlightColor: Farben.rot
            icon.source: "image://theme/icon-m-previous"
            visible: Spieler.spulbar
            onClicked: Spieler.spulen(-15 * 60000)
        }
        IconButton {
            palette.primaryColor: Farben.schrift
            palette.highlightColor: Farben.rot
            icon.source: Spieler.spielt ? "image://theme/icon-l-pause"
                                        : "image://theme/icon-l-play"
            // Der einzige Ort, an dem die Android-App ihr Rot auf ein
            // Bedienelement legt.
            icon.highlightColor: Farben.rot
            highlighted: true
            onClicked: Spieler.umschalten()
        }
        IconButton {
            palette.primaryColor: Farben.schrift
            palette.highlightColor: Farben.rot
            icon.source: "image://theme/icon-m-next"
            visible: Spieler.spulbar
            onClicked: Spieler.spulen(15 * 60000)
        }
        IconButton {
            palette.primaryColor: Farben.schrift
            palette.highlightColor: Farben.rot
            icon.source: "image://theme/icon-m-clear"
            onClicked: Spieler.anhalten()
        }
    }

    BusyIndicator {
        // Nicht ueber die palette: der Kringel ist ein HighlightImage
        // im Inneren und nimmt seine Farbe aus dem Theme. Die eigene
        // Eigenschaft "color" wirkt (nachgemessen).
        color: Farben.rot
        anchors.horizontalCenter: parent.horizontalCenter
        size: BusyIndicatorSize.Small
        running: Spieler.laedt
    }

    // --- Einschlafzeit ----------------------------------------------------
    // Die drei Knoepfe muessen sich die Zeile *teilen*: ein Row mit
    // Vorgabebreite laeuft bei drei Silica-Buttons rechts und links aus
    // dem Schirm. Also die Breite ausrechnen und jedem ein Drittel geben.
    Row {
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * Theme.horizontalPageMargin
        spacing: Theme.paddingSmall
        visible: !Spieler.schlaeft

        Repeater {
            model: [15, 30, 60]
            delegate: Button {
                palette.primaryColor: Farben.schrift
                palette.highlightColor: Farben.rot
                palette.highlightBackgroundColor: Farben.band
                width: (parent.width - 2 * Theme.paddingSmall) / 3
                text: qsTr("%1 min").arg(modelData)
                onClicked: Spieler.schlafStarten(modelData)
            }
        }
    }

    Button {
        palette.primaryColor: Farben.schrift
        palette.highlightColor: Farben.rot
        palette.highlightBackgroundColor: Farben.band
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * Theme.horizontalPageMargin
        visible: Spieler.schlaeft
        text: qsTr("Schlaf %1:%2 — abbrechen")
                .arg(Math.floor(Spieler.schlafRest / 60))
                .arg(("0" + (Spieler.schlafRest % 60)).slice(-2))
        onClicked: Spieler.schlafAbbrechen()
    }
}

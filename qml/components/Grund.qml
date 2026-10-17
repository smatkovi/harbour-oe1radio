import QtQuick 2.6
import Sailfish.Silica 1.0
import "."

/*!
 * Die Grundflaeche einer Seite. Bei "ambience" unsichtbar -- dort soll das
 * Hintergrundbild der Ambience stehenbleiben, statt von einem Rechteck
 * uebermalt zu werden.
 */
Rectangle {
    anchors.fill: parent
    z: -1
    visible: Farben.eigen
    color: Farben.grund
}

pragma Singleton
import QtQuick 2.6

/*!
 * Attrappe fuer den QML-Pruefer. Den echten Singleton meldet main.cpp an;
 * qmlscene kennt das Modul nicht, und ohne diese Attrappe scheitert schon
 * der Verzeichnis-Import von "components" -- womit der Pruefer auch das
 * Spieler-Singleton nicht mehr sieht und seine eigentliche Aufgabe verliert.
 *
 * Die Werte muessen zu den Vorgaben in src/einstellungen.cpp passen.
 */
QtObject {
    property string farbschema: "ambience"
    property bool   oe1Rot: true
    property string guete: "niedrig"
    property bool   autoplay: false
}

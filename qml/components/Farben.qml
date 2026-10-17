pragma Singleton
import QtQuick 2.6
import Sailfish.Silica 1.0
import harbour.oe1radio 1.0

/*!
 * Das Farbschema. Drei Einstellungen, wie gewuenscht:
 *
 *   "dunkel"   -- schwarzer Grund (#000000), helle Schrift
 *   "hell"     -- weisser Grund, dunkle Schrift
 *   "ambience" -- folgt dem, was das System gerade eingestellt hat
 *
 * Die Werte des Akzents stammen aus der Android-App
 * (`res/values/colors.xml`, `oe1_red`). Ob er genommen wird oder die
 * Akzentfarbe der Ambience, steht ebenfalls in den Einstellungen -- eine
 * App, die sich stur ueber jede Ambience legt, ist auf Sailfish ein
 * Fremdkoerper, aber das Ö1-Rot ist nun einmal die Hausfarbe.
 */
QtObject {
    //! Das Ö1-Rot der Android-App.
    readonly property color oe1Rot: "#b61f24"
    //! Der dunkle Rotton, mit dem die App ihre Titelflaechen hinterlegt.
    readonly property color rotDunkel: "#3f0a0c"
    //! Die rote Leiste unten und ihre nicht gewaehlten Symbole.
    readonly property color leiste: "#b61f24"
    readonly property color leisteMatt: "#e7a9a7"

    //! Der Akzent -- entweder die Hausfarbe oder die der Ambience.
    readonly property color rot: Einstellungen.oe1Rot ? oe1Rot : Theme.highlightColor

    //! Ist der Grund dunkel? Entweder weil es so eingestellt ist, oder
    //! weil die Ambience es ist.
    readonly property bool dunkel: Einstellungen.farbschema === "dunkel" ? true
                                 : Einstellungen.farbschema === "hell" ? false
                                 : Theme.colorScheme === Theme.LightOnDark

    //! Der Grund. Bei "dunkel" ausdruecklich #000000, nicht das dunkle Grau
    //! der Ambience.
    readonly property color grund: dunkel ? "#000000" : "#ffffff"

    //! Flaechen, die sich leicht abheben sollen (Karten, der Minispieler).
    readonly property color flaeche: dunkel ? "#121212" : "#f3f4f6"

    //! Trennlinien -- die Graustufen der Android-App.
    readonly property color linie: dunkel ? "#2a2a2a" : "#d5d8df"

    //! Haupt- und Nebenschrift. Bei "ambience" aus dem Theme, sonst
    //! passend zum selbst gesetzten Grund -- sonst stuende dunkle Schrift
    //! auf schwarzem Grund.
    readonly property color schrift: Einstellungen.farbschema === "ambience"
            ? Theme.primaryColor : (dunkel ? "#ffffff" : "#1a1a1a")
    readonly property color schriftMatt: Einstellungen.farbschema === "ambience"
            ? Theme.secondaryColor : (dunkel ? "#999999" : "#4e4e4e")

    //! Was noch nicht gesendet wurde, schreibt die Android-App grau.
    readonly property color kuenftig: "#9b9b9b"
}

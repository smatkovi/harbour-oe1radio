pragma Singleton
import QtQuick 2.6
import Sailfish.Silica 1.0
import harbour.oe1radio 1.0

/*!
 * Das Farbschema. Drei Einstellungen:
 *
 *   "dunkel"   -- schwarzer Grund (#000000), helle Schrift, Ö1-Rot
 *   "hell"     -- weisser Grund, dunkle Schrift, Ö1-Rot
 *   "ambience" -- die Ambience des Geraets, unveraendert
 *
 * Ein eigener Schalter fuer "Ö1-Rot als Akzent" waere ueberfluessig: wer
 * die Ambience waehlt, will deren Farben, und wer dunkel oder hell waehlt,
 * will das Erscheinungsbild der App. Beides haengt deshalb an derselben
 * Entscheidung -- `eigen`.
 *
 * **Bei "ambience" wird nichts uebermalt**: jede Farbe gibt dann das
 * zurueck, was das Theme ohnehin liefert. Nur so folgt auch das
 * Pulley-Menü der Ambience, statt stur rot zu bleiben.
 *
 * Warum ueberhaupt jedes Bedienelement eigens gefaerbt werden muss: Silica
 * reicht die palette zwar an *direkte* Kinder weiter, aber ein
 * gewoehnliches QtQuick-Element dazwischen (Column, Row, Item)
 * **unterbricht die Kette** -- nachgemessen. Hier steht fast alles in
 * einer Column, also genuegt das Setzen an der Seite allein nicht.
 */
QtObject {
    //! Die Hausfarbe der Android-App (res/values/colors.xml, oe1_red).
    readonly property color oe1Rot: "#b61f24"
    //! Der dunkle Rotton, mit dem sie ihre Titelflaechen hinterlegt.
    readonly property color rotDunkel: "#3f0a0c"

    //! Faerbt die App selbst, oder folgt sie der Ambience?
    readonly property bool eigen: Einstellungen.farbschema !== "ambience"

    //! Ist der Grund dunkel?
    readonly property bool dunkel: Einstellungen.farbschema === "dunkel" ? true
                                 : Einstellungen.farbschema === "hell" ? false
                                 : Theme.colorScheme === Theme.LightOnDark

    //! Der Akzent.
    readonly property color rot: eigen ? oe1Rot : Theme.highlightColor

    //! Das Band unter dem Finger (Pulley, Kontextmenü, Listenzeile).
    readonly property color band: eigen ? oe1Rot : Theme.highlightBackgroundColor

    //! Der Grund. Bei "ambience" malt die App gar keinen, siehe Grund.qml.
    readonly property color grund: dunkel ? "#000000" : "#ffffff"

    //! Flaechen, die sich leicht abheben (Kontextmenü, Minispieler).
    readonly property color flaeche: eigen ? (dunkel ? "#121212" : "#f3f4f6")
                                           : Theme.highlightDimmerColor

    //! Trennlinien -- die Graustufen der Android-App.
    readonly property color linie: eigen ? (dunkel ? "#2a2a2a" : "#d5d8df")
                                         : Theme.secondaryColor

    //! Haupt- und Nebenschrift.
    readonly property color schrift: eigen ? (dunkel ? "#ffffff" : "#1a1a1a")
                                           : Theme.primaryColor
    readonly property color schriftMatt: eigen ? (dunkel ? "#999999" : "#4e4e4e")
                                               : Theme.secondaryColor

    //! Was noch nicht gesendet wurde, schreibt die Android-App grau.
    readonly property color kuenftig: eigen ? "#9b9b9b" : Theme.secondaryColor
}

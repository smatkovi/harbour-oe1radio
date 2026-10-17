pragma Singleton
import QtQuick 2.6
import Sailfish.Silica 1.0

/*!
 * Das Farbschema der Android-App, auf Sailfish uebersetzt.
 *
 * Die Werte stammen aus deren `res/values/colors.xml` (`oe1_red` und die
 * Graustufen). Uebernommen wird aber nur der **Akzent** -- alles Uebrige
 * kommt aus dem Theme, damit die App der eingestellten Ambience folgt
 * statt sie zu uebermalen. Der Grund ist schwarz bzw. weiss, je nachdem ob
 * die Ambience hell oder dunkel ist.
 */
QtObject {
    //! Das Ö1-Rot, Akzent und Primaerfarbe der Android-App.
    readonly property color rot: "#b61f24"
    //! Dasselbe halbdurchsichtig -- dort, wo die Android-App `oe1_red_60` nimmt.
    readonly property color rotMatt: Qt.rgba(0.714, 0.122, 0.141, 0.6)
    //! Der dunkle Rotton, mit dem die App ihre Titelflaechen hinterlegt.
    readonly property color rotDunkel: "#3f0a0c"

    readonly property bool dunkel: Theme.colorScheme === Theme.LightOnDark

    //! Der Grund: schwarz im dunklen, weiss im hellen Schema.
    readonly property color grund: dunkel ? "#000000" : "#ffffff"

    //! Flaechen, die sich leicht vom Grund abheben sollen (Karten, Zeilen).
    readonly property color flaeche: dunkel ? "#121212" : "#f3f4f6"

    //! Trennlinien -- die Graustufen der Android-App.
    readonly property color linie: dunkel ? "#2a2a2a" : "#d5d8df"

    //! Was noch nicht gesendet wurde, schreibt die App grau.
    readonly property color kuenftig: "#9b9b9b"
}

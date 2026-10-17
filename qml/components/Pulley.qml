import QtQuick 2.6
import Sailfish.Silica 1.0
import "."

/*!
 * Ein Pulley-Menü in den Farben der App -- und bei "ambience" eben in
 * denen der Ambience: dann bleibt alles auf den Vorgaben des Themes,
 * sonst traegt das Menü stur das Ö1-Rot, egal was eingestellt ist.
 *
 * Das Band unter dem gewaehlten Eintrag legt Silica mit 30 % Deckung
 * ueber den Grund (Theme.highlightBackgroundOpacity). Es muss deshalb
 * *heller* sein als der Grund -- ein dunkles Rot ueber dem roten Grund
 * verschwindet darin spurlos.
 */
PullDownMenu {
    backgroundColor: Farben.eigen ? Farben.oe1Rot : palette.highlightBackgroundColor
    highlightColor: Farben.eigen ? "#ffffff" : palette.highlightColor
}

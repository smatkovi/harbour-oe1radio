import QtQuick 2.6
import Sailfish.Silica 1.0
import "."

/*!
 * Ein Pulley-Menü in den Farben der App.
 *
 * Silica faerbt seine Bedienelemente **nicht** nach einer vererbten Palette:
 * `palette` ist je Element eigen, schreibgeschuetzt als Ganzes, und ein Kind
 * erbt sie nicht vom Elternteil (nachgemessen). Die Werte muessen also an
 * jedem Element einzeln stehen -- dafuer gibt es diese Huelle und
 * PulleyEintrag.qml, damit sie nur an einer Stelle gepflegt werden.
 *
 * Der Grund ist das Ö1-Rot, wie die untere Leiste der Android-App.
 */
PullDownMenu {
    backgroundColor: Farben.oe1Rot
    highlightColor: Farben.rotDunkel
}

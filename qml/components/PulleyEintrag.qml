import QtQuick 2.6
import Sailfish.Silica 1.0
import "."

/*!
 * Ein Eintrag im Pulley-Menü: weiss auf dem roten Grund -- und bei
 * "ambience" unangetastet, damit er die Ambience-Farben behaelt.
 */
MenuItem {
    palette.primaryColor: Farben.eigen ? "#ffffff" : Theme.primaryColor
    palette.secondaryColor: Farben.eigen ? "#e7a9a7" : Theme.secondaryColor
    palette.highlightColor: Farben.eigen ? "#ffffff" : Theme.highlightColor
}

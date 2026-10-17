import QtQuick 2.6
import Sailfish.Silica 1.0
import "../qml/components"

// Prueft, dass das Singleton wirklich aufgeloest wird -- ein fehlendes
// qmldir faellt beim blossen Laden der Seiten *nicht* auf, der Fehler
// kaeme erst zur Laufzeit als ReferenceError.
Item {
    width: 100; height: 100
    Component.onCompleted: {
        console.log("PROBE guete      =", Spieler.guete)
        console.log("PROBE medien     =", Spieler.medien)
        console.log("PROBE mpris      =", Spieler.fern)
        console.log("PROBE dienstname =", Spieler.fern ? Spieler.fern.serviceName : "-")
        console.log("PROBE live-adr   =", oe1 ? "oe1 da" : "oe1 fehlt (erwartet ohne App)")
    }
}

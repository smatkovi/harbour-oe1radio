#!/bin/sh
# Prueft die QML auf Typ- und Syntaxfehler, ohne zu bauen. Laeuft auf dem
# Sailfish-Geraet selbst -- nur dort liegen Silica, QtMultimedia und
# Amber.Mpris. Eine Runde hier kostet Sekunden, eine ueber den Baurechner
# Minuten.
#
# Drei Dinge, die hier leicht schiefgehen:
#  * Ohne QT_LOGGING_TO_CONSOLE=1 landet jede Meldung im Journal, und der
#    Lauf sieht fehlerfrei aus, auch wenn er es nicht ist.
#  * "Failed to create OpenGL context" ist kein Befund, sondern die Folge
#    der Ausgabe ohne Schirm -- geladen war da schon alles.
#  * Eine Seite allein geladen hat weder ApplicationWindow noch die
#    Kontext-Eigenschaften der App. Diese Meldungen sind erwartbar und
#    werden unten ausgefiltert, sonst gehen die echten darin unter.
cd "$(dirname "$0")/.."
FEHLER=0
MUSTER="is not a type|Expected token|Unexpected token|Syntax error|Cannot assign|is not installed|No such file|has no qmldir|ReferenceError"
# Erwartbar, wenn eine Seite ohne die App geladen wird:
RAUSCHEN="__silica_applicationwindow_instance|ReferenceError: oe1 |ReferenceError: appVersion |Cannot assign to non-existent property \"onTagGeladen\"|Cannot assign to non-existent property \"onSendungGeladen\"|Cannot assign to non-existent property \"onPodcastsGeladen\"|Cannot assign to non-existent property \"onFolgenGeladen\""

for f in qml/harbour-oe1radio.qml qml/cover/*.qml qml/pages/*.qml; do
    [ -f "$f" ] || continue
    AUS=$(QT_LOGGING_TO_CONSOLE=1 QT_QPA_PLATFORM=minimal qmlscene --quit "$f" 2>&1)
    ECHT=$(echo "$AUS" | grep -E "$MUSTER" | grep -vE "$RAUSCHEN")
    if [ -n "$ECHT" ]; then
        echo "=== $f"; echo "$ECHT" | sed 's/^/    /'; FEHLER=1
    fi
done

# Das Singleton eigens: ein fehlendes qmldir oder ein vergessenes
# import "." faellt oben nicht auf, der Fehler kaeme erst zur Laufzeit.
AUS=$(QT_LOGGING_TO_CONSOLE=1 QT_QPA_PLATFORM=minimal qmlscene --quit tests/singleton-probe.qml 2>&1)
echo "$AUS" | grep -q "PROBE medien     = QDeclarativeAudio" || {
    echo "=== Singleton Spieler loest nicht auf:"
    echo "$AUS" | grep -E "$MUSTER" | sed 's/^/    /' | head -6; FEHLER=1; }
echo "$AUS" | grep -q "PROBE mpris      = Amber::DeclarativeMprisPlayer" || {
    echo "=== Amber.Mpris fehlt -- die App wuerde im Hintergrund weggeraeumt"; FEHLER=1; }

[ $FEHLER -eq 0 ] && echo "QML in Ordnung (Seiten laden, Singleton und Mpris loesen auf)"
exit $FEHLER

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
MUSTER="is not a type|Binding loop detected|Expected token|Unexpected token|Syntax error|Cannot assign|Unable to assign|is not installed|No such file|has no qmldir|ReferenceError"
# Erwartbar, wenn eine Seite ohne die App geladen wird:
# Die Kontext-Eigenschaften (oe1, lader, merker) und die Signale darauf gibt
# es nur in der laufenden App; einzeln geladen fehlen sie zwangslaeufig.
# Den Singleton-Typ Einstellungen aus "harbour.oe1radio" meldet erst
# main.cpp an. Fuer den Pruefer liegt in tests/attrappen eine Attrappe --
# ohne sie scheitert schon der Verzeichnis-Import von "components", und
# der Pruefer verlaere seine eigentliche Aufgabe.
RAUSCHEN="__silica_applicationwindow_instance|ReferenceError: (oe1|lader|merker|Einstellungen|appVersion) |Cannot assign to non-existent property \"on(TagGeladen|SendungGeladen|PodcastsGeladen|FolgenGeladen|BeitraegeGeladen|JournaleGeladen|SucheFertig|AufnahmenChanged|EintraegeChanged|Fehler|Fertig|PodcastGeladen)\""

for f in qml/harbour-oe1radio.qml qml/cover/*.qml qml/pages/*.qml; do
    [ -f "$f" ] || continue
    AUS=$(QT_LOGGING_TO_CONSOLE=1 QT_QPA_PLATFORM=minimal qmlscene -I tests/attrappen --quit "$f" 2>&1)
    ECHT=$(echo "$AUS" | grep -E "$MUSTER" | grep -vE "$RAUSCHEN")
    if [ -n "$ECHT" ]; then
        echo "=== $f"; echo "$ECHT" | sed 's/^/    /'; FEHLER=1
    fi
done

# Nackte MenuItem in Pulley- und Kontextmenues: die tragen dann die Farben
# der Ambience statt die des Schemas. Zweimal uebersehen, weil ein
# Suchausdruck am ersten schliessenden Klammerpaar endete.
for f in $(find qml -name '*.qml'); do
    NACKT=$(python3 - "$f" <<'PYEOF'
import re, sys
s = open(sys.argv[1], encoding='utf-8').read()
n = 0
for m in re.finditer(r'(Pulley|ContextMenu) \{', s):
    tiefe, i = 0, m.end() - 1
    while i < len(s):
        if s[i] == '{': tiefe += 1
        elif s[i] == '}':
            tiefe -= 1
            if tiefe == 0: break
        i += 1
    n += len(re.findall(r'\bMenuItem \{', s[m.end():i]))
print(n)
PYEOF
)
    [ "$NACKT" = "0" ] || { echo "=== $f: $NACKT nacktes MenuItem im Menü (Farben!)"; FEHLER=1; }
done

# Das Singleton eigens: ein fehlendes qmldir oder ein vergessenes
# import "." faellt oben nicht auf, der Fehler kaeme erst zur Laufzeit.
AUS=$(QT_LOGGING_TO_CONSOLE=1 QT_QPA_PLATFORM=minimal qmlscene -I tests/attrappen --quit tests/singleton-probe.qml 2>&1)
echo "$AUS" | grep -q "PROBE medien     = QDeclarativeAudio" || {
    echo "=== Singleton Spieler loest nicht auf:"
    echo "$AUS" | grep -E "$MUSTER" | sed 's/^/    /' | head -6; FEHLER=1; }
echo "$AUS" | grep -q "PROBE mpris      = Amber::DeclarativeMprisPlayer" || {
    echo "=== Amber.Mpris fehlt -- die App wuerde im Hintergrund weggeraeumt"; FEHLER=1; }

# Jedes image://theme/<name> gegen den Themenordner halten. Ein fehlendes
# Symbol ist nur eine Warnung im Protokoll und sonst ein leerer Knopf --
# icon-m-forward gibt es, icon-m-backward nicht.
# Ueber *alle* Groessenstufen suchen: z1.0 enthaelt nur eine Handvoll
# Ueberschreibungen, der volle Satz liegt in der Stufe des Geraets.
THEMEN=$(ls -d /usr/share/themes/sailfish-default/silica/z*/icons-monochrome 2>/dev/null)
if [ -n "$THEMEN" ]; then
    # Zwei Schreibweisen: die volle Adresse, und blosse Symbolnamen, die
    # erst zur Laufzeit zusammengesetzt werden (die Reiterleiste tut das,
    # um die Farbe anzuhaengen) -- die faenge die erste Form nicht.
    NAMEN=$( { grep -rhoE 'image://theme/[a-z0-9-]+' qml/ | sed 's|image://theme/||'
               grep -rhoE '"icon-[a-z0-9-]+"' qml/ | tr -d '"'; } | sort -u )
    for name in $NAMEN; do
        DA=0
        for t in $THEMEN; do [ -f "$t/$name.png" ] && { DA=1; break; }; done
        [ $DA -eq 1 ] || { echo "=== Symbol fehlt im Thema: $name"; FEHLER=1; }
    done
else
    echo "(Themenordner nicht gefunden -- Symbole ungeprueft)"
fi

[ $FEHLER -eq 0 ] && echo "QML in Ordnung (Seiten laden, Singleton, Mpris und Symbole)"
exit $FEHLER

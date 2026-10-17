#!/bin/sh
# Veroeffentlicht die RPMs einer Fassung als Release dieses Repositoriums.
#
#   tools/release.sh 0.1.0 ~/ps/rpms/oe1radio/*.rpm
#
# gh ist auf dem Arch-Rechner angemeldet, nicht hier -- die Dateien gehen
# also erst dorthin. /tmp hat dort eine Benutzerquote, deshalb /dev/shm.
set -e
cd "$(dirname "$0")/.."

VERSION=$1
shift 2>/dev/null || true
if [ -z "$VERSION" ] || [ $# -eq 0 ]; then
    echo "usage: tools/release.sh <version> <rpm> [<rpm> ...]" >&2
    exit 2
fi
for F in "$@"; do [ -f "$F" ] || { echo "kein Paket: $F" >&2; exit 2; }; done

if [ -n "$BUILD_HOST" ]; then
    HOST=$BUILD_HOST
elif ssh -o BatchMode=yes -o ConnectTimeout=4 sebastian@192.168.1.21 true 2>/dev/null; then
    HOST=sebastian@192.168.1.21
else
    HOST=arch
fi
REPO=${REPO:-smatkovi/harbour-oe1radio}
TAG=v$VERSION
WORK=/dev/shm/oe1radio-release

NOTES=$(mktemp)
cat > "$NOTES" <<NOTE
Ö1 Radio $VERSION für Sailfish OS.

Livestream (drei Güten, die beste per HLS), sieben Tage zum Nachhören mit
Spulen, die Podcasts samt Folgen, Einschlafzeit, Cover und Bedienung vom
Sperrbildschirm.

    sudo rpm -Uvh harbour-oe1radio-$VERSION-1.<arch>.rpm

\`aarch64\` für die neueren Geräte, \`armv7hl\` für die älteren.

Die Schwesterfassung für MeeGo Harmattan (Nokia N9/N950) liegt in
[smatkovi/oe1-radio](https://github.com/smatkovi/oe1-radio) — sie braucht
dort ein fremdes wget und einen Vermittler auf der Rückschleife, weil Qt 4.7
und gstreamer kein TLS können. Auf Sailfish fällt beides weg.
NOTE

ssh -oConnectTimeout=20 "$HOST" "mkdir -p $WORK"
scp -oConnectTimeout=20 "$@" "$NOTES" "$HOST:$WORK/" >/dev/null
NBASE=$(basename "$NOTES")

# Pruefsummen vergleichen -- scp legt bei erschoepfter Quote stumm
# abgeschnittene Dateien an.
for F in "$@"; do
    B=$(basename "$F")
    H=$(md5sum "$F" | cut -d' ' -f1)
    T=$(ssh -oConnectTimeout=20 "$HOST" "md5sum $WORK/$B | cut -d' ' -f1")
    [ "$H" = "$T" ] || { echo "Pruefsumme passt nicht bei $B" >&2; exit 1; }
done

LISTE=$(for F in "$@"; do printf '%s ' "$(basename "$F")"; done)
ssh -oConnectTimeout=120 "$HOST" \
    "cd $WORK && gh release create $TAG $LISTE --repo $REPO --title 'Ö1 Radio $VERSION' --notes-file $NBASE"
ssh -oConnectTimeout=20 "$HOST" "rm -rf $WORK"
rm -f "$NOTES"
echo "fertig: $TAG"

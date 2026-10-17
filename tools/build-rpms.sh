#!/bin/sh
# Builds the Sailfish RPMs for every architecture on the Arch build machine.
#
# Each target is unpacked into its own tree inside the SDK container. That is
# the point of the script: building two targets one after the other in the
# same tree leaves qmake's object files lying around, and the second package
# then carries the first one's binary. The RPM header still says armv7hl, and
# only `file` on the unpacked binary tells the truth -- so this checks it.
#
#   sh tools/build-rpms.sh              # build, verify, fetch
#   ARCHS="aarch64" sh tools/build-rpms.sh
#   BUILD_HOST=sebastian@192.168.1.21 sh tools/build-rpms.sh
set -e

SRC=$(cd "$(dirname "$0")/.." && pwd)
ARCHS=${ARCHS:-"aarch64 armv7hl"}
TARGET=${TARGET:-SailfishOS-5.2.0.15}
CONTAINER=${CONTAINER:-sfossdk52}
OUT=${OUT:-$HOME/ps/rpms/oe1radio}
REMOTE=/tmp/oe1radio-build

if [ -n "$BUILD_HOST" ]; then
    HOST=$BUILD_HOST
elif ssh -o BatchMode=yes -o ConnectTimeout=4 sebastian@192.168.1.21 true 2>/dev/null; then
    HOST=sebastian@192.168.1.21
else
    HOST=arch
fi
echo "Baurechner: $HOST"
echo "Fassung:    $(grep -m1 '^Version:' "$SRC/rpm/harbour-oe1radio.spec")"

ssh "$HOST" "mkdir -p $REMOTE/src"
rsync -a --partial --delete --exclude .git --exclude /build --exclude '*.o' \
    "$SRC/" "$HOST:$REMOTE/src/"

ssh "$HOST" "cat > $REMOTE/run.sh" <<REMOTE_SCRIPT
set -e
cd $REMOTE/src
tar czf $REMOTE/src.tgz --exclude=.git .
docker cp $REMOTE/src.tgz $CONTAINER:/tmp/oe1radio-src.tgz
docker exec $CONTAINER bash -lc '
set -e
rm -rf ~/oe1radio-out && mkdir -p ~/oe1radio-out
for a in $ARCHS; do
    echo "=== \$a ==="
    rm -rf ~/oe1radiobuild-\$a && mkdir -p ~/oe1radiobuild-\$a
    tar xzf /tmp/oe1radio-src.tgz -C ~/oe1radiobuild-\$a
    cd ~/oe1radiobuild-\$a
    nice mb2 -t $TARGET-\$a build
    for r in RPMS/*.\$a.rpm; do
        case \$r in *debuginfo*|*debugsource*) continue;; esac
        cp "\$r" ~/oe1radio-out/
    done
    cd ~ && rm -rf ~/oe1radiobuild-\$a
done'
rm -rf $REMOTE/out
docker cp $CONTAINER:/home/mersdk/oe1radio-out $REMOTE/out
echo "FERTIG"
REMOTE_SCRIPT

ssh "$HOST" "tmux kill-session -t oe1radio 2>/dev/null; \
    tmux new-session -d -s oe1radio 'sh $REMOTE/run.sh > $REMOTE/build.log 2>&1'"
echo "tmux-Sitzung oe1radio laeuft, Log $REMOTE/build.log"

while ssh "$HOST" "tmux has-session -t oe1radio 2>/dev/null"; do
    sleep 30
done
ssh "$HOST" "tail -5 $REMOTE/build.log"
ssh "$HOST" "grep -q FERTIG $REMOTE/build.log" || { echo "Bau fehlgeschlagen"; exit 1; }

# What is actually inside the package.
ssh "$HOST" "cd $REMOTE/out && rm -rf ../check && for r in *.rpm; do
    a=\${r##*-}; a=\${a%.rpm}; a=\${a##*.}
    mkdir -p ../check/\$a && (cd ../check/\$a && rpm2cpio ../../out/\$r | cpio -idm 2>/dev/null)
    printf '%s: ' \"\$r\"; file -b ../check/\$a/usr/bin/harbour-oe1radio
done"

mkdir -p "$OUT"
rsync -a --partial "$HOST:$REMOTE/out/*.rpm" "$OUT/"
ls -l "$OUT"

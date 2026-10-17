pragma Singleton
import QtQuick 2.6
import QtMultimedia 5.6
import Amber.Mpris 1.0

/*!
 * Alles, was gerade klingt -- als Singleton, damit der Ton beim Blaettern
 * zwischen den Seiten nicht abreisst und Cover wie Seiten denselben Zustand
 * sehen.
 *
 * Auf Harmattan musste hier ein Vermittler auf der Rueckschleife stehen, weil
 * gstreamer dort kein TLS kann. Auf Sailfish bekommt der MediaPlayer die
 * https-Adresse der ORF-Schnittstelle unverändert.
 */
QtObject {
    id: wurzel

    property string titel: ""
    property string untertitel: ""
    property bool   istLive: false
    property int    sendungId: 0
    property string fehler: ""

    readonly property bool spielt: medien.playbackState === MediaPlayer.PlayingState
    readonly property bool pausiert: medien.playbackState === MediaPlayer.PausedState
    readonly property bool hatQuelle: medien.source != ""
    readonly property bool laedt: medien.status === MediaPlayer.Loading
                                  || medien.status === MediaPlayer.Buffering
                                  || medien.status === MediaPlayer.Stalled

    readonly property int position: medien.position
    readonly property int dauer: medien.duration
    readonly property bool spulbar: medien.seekable && !istLive

    // Guete des Livestroms: niedrig | mittel | hoch
    property string guete: "niedrig"

    property MediaPlayer medien: MediaPlayer {
        autoPlay: false
        onError: wurzel.fehler = errorString ? errorString
                                             : qsTr("Wiedergabe fehlgeschlagen")
        onPlaybackStateChanged: fern.playbackStatus =
            playbackState === MediaPlayer.PlayingState ? Mpris.Playing
          : playbackState === MediaPlayer.PausedState  ? Mpris.Paused
                                                       : Mpris.Stopped
    }

    function spieleLive() {
        titel = qsTr("Ö1 Livestream")
        istLive = true
        sendungId = 0
        fehler = ""
        medien.source = oe1.liveAdresse(guete)
        medien.play()
        melde()
    }

    function spieleSendung(id, derTitel, derUntertitel, adresse) {
        titel = derTitel
        untertitel = derUntertitel ? derUntertitel : ""
        istLive = false
        sendungId = id
        fehler = ""
        medien.source = adresse
        medien.play()
        melde()
    }

    function umschalten() {
        if (spielt)
            medien.pause()
        else if (hatQuelle)
            medien.play()
        else
            spieleLive()
    }

    function anhalten() {
        medien.stop()
        medien.source = ""
        titel = ""
        untertitel = ""
        sendungId = 0
    }

    function spulen(ms) {
        if (spulbar)
            medien.seek(Math.max(0, Math.min(medien.duration, medien.position + ms)))
    }

    function setzePosition(ms) {
        if (spulbar)
            medien.seek(ms)
    }

    // --- Einschlafzeit ----------------------------------------------------
    property int schlafRest: 0
    readonly property bool schlaeft: schlafRest > 0

    function schlafStarten(minuten) { schlafRest = minuten * 60 }
    function schlafAbbrechen()      { schlafRest = 0 }

    property Timer schlafUhr: Timer {
        running: wurzel.schlafRest > 0
        interval: 1000
        repeat: true
        onTriggered: {
            wurzel.schlafRest--
            if (wurzel.schlafRest <= 0)
                wurzel.anhalten()
        }
    }

    // --- Sperrbildschirm und Medientasten ---------------------------------
    // Nicht nur Bequemlichkeit: ohne angemeldeten Mpris-Dienst raeumt das
    // System die App im Hintergrund irgendwann weg, und ein Radio, das beim
    // Wegblenden verstummt, ist keines.
    property MprisPlayer fern: MprisPlayer {
        id: fern
        serviceName: "harbour-oe1radio"
        identity: "Ö1 Radio"
        desktopEntry: "harbour-oe1radio"

        canControl: true
        canPlay: true
        canPause: true
        canGoNext: false
        canGoPrevious: false
        canSeek: wurzel.spulbar
        canQuit: false
        canRaise: true

        onPlayRequested:      wurzel.medien.play()
        onPauseRequested:     wurzel.medien.pause()
        onPlayPauseRequested: wurzel.umschalten()
        onStopRequested:      wurzel.anhalten()
        onSeekRequested:      wurzel.spulen(offset / 1000)
    }

    function melde() {
        fern.metaData.title = titel
        fern.metaData.artist = untertitel ? untertitel : "Ö1"
    }
}

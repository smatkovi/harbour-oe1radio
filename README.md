# Ö1 Radio for Sailfish OS

The Austrian public radio station **Ö1** on Sailfish: the live stream, the
seven-day catch-up archive, the podcasts with their episodes, a sleep timer,
and playback control from the cover and the lock screen.

Qt 5 with a Silica interface. Built for `aarch64` and `armv7hl`.

![icon](icons/172x172/harbour-oe1radio.png)

This is the Sailfish side of
**[smatkovi/oe1-radio](https://github.com/smatkovi/oe1-radio)**, the same app
for MeeGo Harmattan on the Nokia N9 and N950. The two share the ORF endpoints
and nothing else — and the reason is worth writing down.

Since 0.2.0 the feature set follows the official Android app **Radio Ö1
5.8.8**: live, 7 Tage, Highlights, Journale, Favoriten, Suche and the "Info"
page of a broadcast. Downloading is the one thing here that the Android app
cannot do.

## What the port could throw away

The Harmattan version is built around two platform defects, and almost all of
its machinery exists to work around them:

| on Harmattan | why | on Sailfish |
| --- | --- | --- |
| fetch JSON by running `/opt/wunderw/bin/wget` as a subprocess | Qt 4.7 links an OpenSSL from 2011 and never completes a TLS 1.2 handshake | `QNetworkAccessManager`, directly |
| download audio to a cache file and re-serve it from a loopback HTTP server | gstreamer's `souphttpsrc` was built without SSL and answers every `https://` URI with `SSL support not available` | hand the `https://` URL straight to `MediaPlayer` |
| skip the HLS stream, use the 32 kbit/s Shoutcast one | no usable HLS | `hlsdemux` plays it, so the best quality is available |

Verified on the device before a line was written — both the catch-up stream
(`https://loopstream01.apa.at/…`) and the live stream decode straight through
`souphttpsrc ! decodebin`. So this port has **no helper process and no proxy**;
`src/api.cpp` is a plain REST client. That is the whole difference, and it
removes about two thirds of the original's code.

What the port *adds*, because Sailfish offers it and Harmattan did not:

- **MPRIS** (`Amber.Mpris`) — lock-screen controls and media keys. It is not
  only convenience: without a registered MPRIS service the system eventually
  reclaims a backgrounded app, and a radio that goes quiet when you swipe away
  is not a radio.
- **A cover** with play/pause, the current title and the sleep countdown.
- **Seeking** inside a catch-up broadcast, with a position slider.

## How the data is put together

Three endpoints, all under `audioapi.orf.at`:

- `oe1/api/json/5.0/broadcasts/<YYYYMMDD>` — one day's schedule. `payload` is a
  flat list; the app marks the entry whose `start`/`end` bracket the current
  time as the one on air.
- `oe1/api/json/5.0/broadcast/<id>` — a single broadcast. The playable address
  is **not** in the day listing; it appears here as `streams[0].loopStreamId`,
  which becomes `https://loopstream01.apa.at/?channel=oe1&shoutcast=0&id=…`.
- `radiothek/api/2.0/podcasts` — all stations at once, keyed by station;
  the app takes `payload.oe1`.

The episodes of a podcast are the awkward one: the JSON API does not carry
them. `radiothek/api/2.0/podcast/<id>` only names `urls.feed`, and the episodes
live in that RSS document — so `ladeFolgen()` makes two requests and parses the
feed with `QXmlStreamReader`, taking the `<enclosure url=…>` of each item.

## Three things that would have cost an evening each

**`Audio` in the Sailjail permissions.** Without it `MediaPlayer` plays
*silently* inside the sandbox — no error, no warning, just no sound. The
permission block in the `.desktop` file is not boilerplate.

**A sibling singleton is not automatic.** `Spieler.qml` is the singleton that
holds the player; `Spielleiste.qml` sits in the same directory and uses it, and
still needs an explicit `import "."`. Loading a page on its own does not reveal
this — the failure is a runtime `ReferenceError`. `tools/qml-pruefen.sh` checks
for it on purpose.

**A missing theme icon is only a warning.** `image://theme/icon-m-forward`
exists; `icon-m-backward`, its apparent counterpart, does not — the button
simply renders empty and the log mentions it once. The real pair is
`icon-m-10s-back` / `icon-m-10s-forward`, so the seek step is ten seconds, to
match what the icon claims. The checker now resolves every
`image://theme/…` against the theme, across all scale directories: `z1.0`
holds only a handful of overrides, and checking just the first one reports
everything as missing.

## Layout

| path | what |
| --- | --- |
| `src/api.cpp` | the ORF client: schedule, broadcast, podcasts, RSS episodes |
| `qml/components/Spieler.qml` | singleton: `MediaPlayer`, MPRIS, sleep timer |
| `qml/components/Spielleiste.qml` | the transport controls, shown on every page |
| `qml/components/SendungsZeile.qml` | one broadcast in a schedule list |
| `qml/pages/` | main page, 7 Tage, podcasts, episodes, about |
| `tools/qml-pruefen.sh` | loads every QML file on the device, before any build |
| `tools/build-rpms.sh` | builds both architectures on the Arch machine |
| `tools/release.sh` | publishes the RPMs as a GitHub release |

## Building

```sh
sh tools/qml-pruefen.sh          # on the Sailfish device, seconds
sh tools/build-rpms.sh           # on the Arch machine, both architectures
sudo rpm -Uvh harbour-oe1radio-0.1.0-1.aarch64.rpm
```

`build-rpms.sh` unpacks each target into its own tree inside the SDK
container. Building two targets in one tree leaves qmake's object files
behind and the second package then ships the first one's binary — the RPM
header still claims the right architecture, so the script runs `file` on the
unpacked binary and prints what is actually inside.

## Following the Android app

The official app was the reference for 0.2.0. Its APK decodes with `apktool`
(the run ends in an OutOfMemoryError, but `res` is finished by then), and two
files in it settle most design questions:

- `res/menu/bottom_nav_menu.xml` — **five tabs**: Player, 7 Tage, Stories,
  Journale, Favoriten; `res/navigation/mobile_navigation.xml` adds Info,
  Suche, Podcasts and the sleep timer under "Mehr". Silica has no bottom
  tabs, so the player is the main page and the rest hangs in its pulley menu
  and on a "Mehr" page.
- `res/values/colors.xml` — `oe1_red` **#b61f24**. That is taken as the only
  accent; everything else comes from the ambience, so the app still looks
  like the device it runs on. The ground is `#000000` on a dark ambience and
  `#ffffff` on a light one.

Its strings settle a detail that would otherwise have been guesswork: the
skip button is **15 minutes** (`backward_label`), not the ten seconds Silica's
icon set suggests.

**The endpoints are not guessable, and two services are involved.** The
programme comes from `audioapi.orf.at`, but Highlights and Journale come from
`oe1.orf.at/api/v1/app/` — `article`, `article-info/{id}` and `journale`. The
paths live in Retrofit *annotations*, not in plain string constants, so
`strings | grep` finds nothing; `baksmali` and
`grep -A4 'Lretrofit2/http/GET;'` find them, and the base URL sits in
`at/orf/oe1/di/StoryNetworkModuleKt`. The stream URLs likewise come from the
app's own config at `appmeta.orf.at/configs/oe1/android/config.json` rather
than from guessing.

Two joins are needed because the feeds speak a different language than the
programme API: Highlights and Journale identify a broadcast by its
**programKey**, not by the id the audio API wants, so `ladeSendungNachSchluessel()`
fetches that day's schedule and matches. Search is local across the seven days
the API holds — the service has no search of its own.

## Downloading

Sendungen and podcast episodes can be put on the device
(`~/Downloads/Ö1`, which is what the Sailjail `Downloads` permission opens).
Anything already downloaded is played from disk instead of the network.
A download in flight is a `QSaveFile`, so an abort or a crash leaves no
half file that later looks like a finished recording.

## Not yet

The alarm clock (an Ö3 feature in the shared codebase), push topics, traffic
and sharing.

## License

GPL-3.0-or-later, see [LICENSE](LICENSE). Not published or endorsed by the ORF.

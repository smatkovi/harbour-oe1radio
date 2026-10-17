Name:       harbour-oe1radio
Summary:    Ö1 Radio
Version:    0.7.1
Release:    1
Group:      Qt/Qt
License:    GPLv3+
URL:        https://github.com/smatkovi/harbour-oe1radio
Source0:    %{name}-%{version}.tar.bz2

Requires:   sailfishsilica-qt5 >= 0.10.9
# Der Spieler ist ein QML-MediaPlayer; ohne das gstreamer-Backend bleibt er
# stumm, ohne eine Fehlermeldung abzugeben.
Requires:   qt5-qtdeclarative-import-multimedia
Requires:   qt5-qtmultimedia-plugin-mediaservice-gstmediaplayer
# Sperrbildschirm und Medientasten -- und der Grund, warum die App im
# Hintergrund weiterspielen darf, statt weggeraeumt zu werden.
Requires:   amber-qml-plugin-mpris
# Die Beitragsseite zeigt die fertige HTML-Ansicht des ORF, so wie die
# Android-App es in ihrem story_detail_dest tut.
Requires:   sailfish-components-webview-qt5

BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Gui)
BuildRequires:  pkgconfig(Qt5Network)
BuildRequires:  desktop-file-utils

%description
Der Livestream von Ö1, die sieben Tage zum Nachhoeren und die Podcasts des
Senders, mit Einschlafzeit und Bedienung vom Sperrbildschirm aus.

Die Sendungsdaten kommen von der offenen Schnittstelle des ORF
(audioapi.orf.at). Weder vom ORF herausgegeben noch unterstuetzt.

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5 VERSION=%{version}
%make_build

%install
rm -rf %{buildroot}
%qmake5_install

desktop-file-install --delete-original \
  --dir %{buildroot}%{_datadir}/applications \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png

%changelog
* Sat Oct 17 2026 smatkovi <sebastian.matkovich@gmail.com> 0.7.1-1
- Langes Druecken auf einen Podcast zeigte nichts: modelData ist im
  Kontextmenü nicht verlaesslich sichtbar, es wird in einem eigenen
  Kontext erzeugt. Das Menü ging auf, der Eintrag tat nur nichts. Die
  Zeilen halten ihre Daten jetzt in einer eigenen Eigenschaft fest --
  dieselbe Falle steckte auch in den Menues der Aufnahmen, der
  Podcastfolgen und der Favoriten.
- Bilder bei den Journalen: der Feed kennt keine, deshalb werden die Tage
  des Journals nachgeladen und ueber den Programmschluessel zugeordnet.
- Highlights hatten ihre Bilder schon; sie erscheinen jetzt erst, wenn
  sie geladen sind, statt als leerer Rahmen.

* Sat Oct 17 2026 smatkovi <sebastian.matkovich@gmail.com> 0.7.0-1
- Eine eigene Infoseite zum Podcast: grosses Bild, Beschreibung, Autor,
  Faecher, Sprache, Inhaber samt Post, Rechte und Zahl der Folgen, dazu
  die Adressen (Browser, Spotify, Feed kopieren) und ein Knopf zu den
  Folgen. Erreichbar aus der Liste ueber das Kontextmenü und aus der
  Folgenliste ueber das Pulley.
- Dafuer holt ladePodcast() die Angaben eigens: aus der Liste heraus sind
  nur Titel, Bild und Zahl der Folgen bekannt, alles Weitere steht erst in
  der Einzelabfrage.

* Sat Oct 17 2026 smatkovi <sebastian.matkovich@gmail.com> 0.6.1-1
- Bilder bei den Sendungen: im Tagesprogramm als quadratisches Vorschaubild
  in der Zeile, auf der Infoseite das breite Kopfbild. Bei den Sendungen ist
  "versions" uebrigens eine *Liste* (nach Breite absteigend), bei den
  Podcasts ein Objekt -- dieselbe Schnittstelle, zwei Formen.
- Die Podcastliste zeigt jetzt Bild und Beschreibung, nicht nur Titel und
  Zahl der Folgen.
- Jede Folge zeigt ihre Beschreibung (im Kontextmenü aufklappbar) und
  waehrend eines Abrufs den Anteil in Prozent. Die Beschreibung stand
  laengst im RSS und wurde eingelesen, aber nie angezeigt.

* Sat Oct 17 2026 smatkovi <sebastian.matkovich@gmail.com> 0.6.0-1
- Angaben zum Podcast: Bild, Autor, Beschreibung (antippen klappt sie auf),
  Zahl der Folgen und Rechte. Die Daten kamen beim Laden der Folgen ohnehin
  mit und wurden bisher weggeworfen. Dazu im Pulley, was auch die
  Android-App dort anbietet: im Browser oeffnen, bei Spotify oeffnen,
  Feed-Adresse kopieren.
- Die Bilder der Radiothek waren ueberall leer: sie stehen nicht unter
  image.url, sondern als benannte Fassungen unter
  image.versions.<name>.path -- und zwischen den Fassungen liegt ein
  "hashCode", der keine ist. Betraf auch die Podcastliste.
- Der drehende Kringel ist jetzt rot: beim BusyIndicator traegt die palette
  nicht (innen sitzt ein HighlightImage, das seine Farbe aus dem Theme
  nimmt), er hat dafuer eine eigene Eigenschaft "color".

* Sat Oct 17 2026 smatkovi <sebastian.matkovich@gmail.com> 0.5.2-1
- Herunterladen sah aus, als taete es nichts: in der Zeile stand bis zum
  Schluss gar nichts, und erst am Ende erschien das Zeichen. Jetzt zeigt
  sie waehrenddessen den Anteil in Prozent und einen duennen Balken am
  unteren Rand.
- Der Lader meldete bisher ins Leere -- weder ein gescheiterter noch ein
  geglueckter Abruf war zu sehen. Beides steht jetzt im Band unten.
- Podcastfolgen wurden nach einem Neustart nicht wiedergefunden: ihre
  Kennung ist die Adresse, und in einem QSettings-Schluessel ist "/" ein
  Gruppentrenner. Das Verzeichnis der Aufnahmen steht deshalb jetzt als
  JSON in einem einzigen Feld.

* Sat Oct 17 2026 smatkovi <sebastian.matkovich@gmail.com> 0.5.1-1
- Die untere Leiste hatte ihre Farbe verloren: beim Umbau in 0.5.0 sind
  Farben.leiste und leisteMatt verschwunden, und eine fehlende Eigenschaft
  gibt in QML stillschweigend undefined. Sie sind wieder da und folgen nun
  ebenfalls dem Farbschema -- bei "ambience" nimmt die Leiste deren
  Hervorhebungsfarbe statt stur das Ö1-Rot.
- tools/qml-pruefen.sh achtet jetzt auch auf "Unable to assign": genau das
  meldet Qt bei einer entfernten Eigenschaft, und genau das hat der
  Pruefer bisher durchgelassen. Er fand damit sofort einen zweiten Fall --
  "undefined && ..." ergibt undefined und laesst sich keinem bool
  zuweisen (InfoPage) -- und drei Pulley-Eintraege, die beim Umbau nicht
  mitumbenannt worden waren und deshalb die falschen Farben trugen.

* Sat Oct 17 2026 smatkovi <sebastian.matkovich@gmail.com> 0.5.0-1
- "Der Ambience folgen" tut das jetzt wirklich: Pulley-Menü, Baender,
  Flaechen und Schrift geben dort zurueck, was das Theme liefert, statt
  stur das Ö1-Rot zu tragen. Die App malt in dieser Einstellung auch
  keinen eigenen Grund mehr -- das Hintergrundbild der Ambience bleibt
  stehen.
- Der Schalter "Ö1-Rot als Akzent" ist weg. Er war ueberfluessig: die
  Entscheidung steckt schon in der Wahl des Farbschemas.

* Sat Oct 17 2026 smatkovi <sebastian.matkovich@gmail.com> 0.4.1-1
- Im Pulley-Menü war nicht mehr zu sehen, auf welchem Eintrag der Finger
  steht: Silica legt das Band mit 30 % Deckung ueber den Grund, und ein
  dunkles Rot ueber dem roten Grund verschwindet darin (#92191d gegen
  #b61f24). Das Band ist jetzt weiss, also #cc6266 ueber dem Grund.
  Kontextmenues bekommen aus demselben Grund ein rotes Band, und auch die
  Listenzeilen heben sich beim Antippen jetzt in Ö1-Rot hervor statt in
  der Farbe der Ambience.

* Sat Oct 17 2026 smatkovi <sebastian.matkovich@gmail.com> 0.4.0-1
- Das Farbschema greift jetzt wirklich ueberall, auch im Pulley-Menü, in
  Kontextmenues, Knoepfen, Schaltern und Auswahlfeldern. Silica vererbt
  seine Palette naemlich **nicht**: sie ist je Bedienelement eigen und als
  Ganzes schreibgeschuetzt (nachgemessen). Die Werte stehen deshalb an
  jedem Element -- gebuendelt in den Huellen Pulley, PulleyEintrag,
  MenuEintrag, Titel und Abschnitt.
- Das Pulley-Menü ist Ö1-rot mit weisser Schrift, wie die untere Leiste.
- Highlights oeffnen in der App statt im Browser, mit der HTML-Ansicht des
  ORF (article-view/...) -- so wie es die Android-App in ihrem
  story_detail_dest tut. Darunter zwei Knoepfe: zur Sendung, oder doch im
  Browser.

* Sat Oct 17 2026 smatkovi <sebastian.matkovich@gmail.com> 0.3.0-1
- Die Anordnung der Android-App: untere Reiterleiste in Ö1-Rot
  (JETZT, 7 TAGE, HIGHLIGHTS, JOURNALE, FAVORITEN), darueber der
  Minispieler, sobald etwas laeuft. Wie dort traegt nur der gewaehlte
  Reiter seine Beschriftung.
- Einstellungen: Farbschema (dunkel #000000 / hell / der Ambience folgen),
  Ö1-Rot als Akzent an oder aus, Guete des Livestroms, Autoplay.
- Das Farbschema greift jetzt ueberall, auch auf Cover und Minispieler --
  vorher hat an manchen Stellen die Ambience durchgeschlagen.

* Sat Oct 17 2026 smatkovi <sebastian.matkovich@gmail.com> 0.2.0-1
- Nach dem Vorbild der Android-App "Radio Ö1" 5.8.8: Highlights, Journale,
  Favoriten, Suche und "Info" zur Sendung. Deren fuenf Reiter gibt es auf
  Sailfish nicht -- sie haengen im Pulley-Menü und auf der Seite "Mehr".
- Herunterladen von Sendungen und Podcastfolgen nach ~/Downloads/Ö1; was
  auf dem Geraet liegt, wird von dort gespielt. Das kann die Android-App
  nicht.
- Farben aus deren colors.xml: Ö1-Rot #b61f24 als einziger Akzent, Grund
  schwarz bzw. weiss je nach Ambience, alles Uebrige aus dem Theme.
- Sprung 15 Minuten statt 10 Sekunden, wie dort.
- Laufende Titel brechen um statt abzuschneiden.

* Sat Oct 17 2026 smatkovi <sebastian.matkovich@gmail.com> 0.1.0-1
- Erste Fassung: Livestream in drei Rohrweiten, 7 Tage zum Nachhoeren mit
  Spulen, Podcasts samt Folgen, Einschlafzeit, Cover und Sperrbildschirm.
- Gegenueber der Harmattan-Fassung entfallen das fremde wget und der
  Vermittler auf der Rueckschleife: Qt 5 spricht TLS selbst, und gstreamer
  nimmt die https-Adressen des ORF unveraendert.

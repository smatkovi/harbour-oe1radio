Name:       harbour-oe1radio
Summary:    Ö1 Radio
Version:    0.2.0
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

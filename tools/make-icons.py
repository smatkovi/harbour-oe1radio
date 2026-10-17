#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Erzeugt die Sailfish-Symbole aus demselben Bild wie die MeeGo-Fassung.

    python3 tools/make-icons.py            # schreibt icons/<n>x<n>/
    python3 tools/make-icons.py --pruefen  # baut die 80er nach und vergleicht

Das MeeGo-Symbol (`smatkovi/oe1-radio`, `icons/oe1-radio-80.png`) liegt nur in
80x80 vor -- fuer Sailfish werden bis zu 172 gebraucht. Es einfach
hochzurechnen gaebe weiche Kanten, deshalb wird es **nachgezeichnet**: die
Form ist eine rote Raute, deren Spitzen die vier Seitenmitten beruehren, mit
einem senkrechten weissen Spalt darin. Lauter gerade Kanten, also bei jeder
Groesse scharf.

Nur die Silhouette (das abgerundete Quadrat von Harmattan) stammt weiter aus
der 80er-Maske von meego-icon-tool -- eine weiche, runde Form vertraegt das
Hochrechnen, anders als Zeichnung mit Kanten.

Die Masse sind am Original abgelesen (Rote Laeufe je Zeile) und mit
--pruefen gegengerechnet.
"""

import os
import sys
from PIL import Image, ImageDraw

HIER = os.path.dirname(os.path.abspath(__file__))
WURZEL = os.path.dirname(HIER)
MASKE = os.path.join(os.path.dirname(WURZEL), "meego-icon-tool", "mask-icon-l.png")
ORIGINAL = os.path.join(os.path.dirname(WURZEL), "oe1-radio", "icons", "oe1-radio-80.png")

ROT = (183, 10, 7, 255)
WEISS = (255, 255, 255, 255)

# Der weisse Spalt ist kein glattes Band: seine linke Kante faellt von
# (56,17) schraeg auf (46,27), steht dort acht Zeilen senkrecht, geht auf
# (51,40) zurueck und laeuft von da gerade nach unten. Rechts begrenzt ihn
# x=61. Alle Werte am 80er-Original Zeile fuer Zeile abgelesen; --pruefen
# rechnet sie gegen.
SPALT = [(56, 17), (61, 17), (61, 80), (51, 80), (51, 40), (46, 35), (46, 27)]

GROESSEN = (86, 108, 128, 172)
UEBER = 4  # vierfach zeichnen, dann herunterrechnen -- glatte Schraegen


def zeichne(n):
    """Das Symbol in n x n Pixeln."""
    gross = n * UEBER
    bild = Image.new("RGBA", (gross, gross), (0, 0, 0, 0))
    d = ImageDraw.Draw(bild)

    # Weisser Grund in der Silhouette
    d.rectangle([0, 0, gross - 1, gross - 1], fill=WEISS)

    # Rote Raute: Spitzen auf den vier Seitenmitten
    m = gross / 2.0
    d.polygon([(m, 0), (gross, m), (m, gross), (0, m)], fill=ROT)

    # Weisser Spalt
    k = gross / 80.0
    d.polygon([(x * k, y * k) for x, y in SPALT], fill=WEISS)

    bild = bild.resize((n, n), Image.LANCZOS)

    # Silhouette als Alphakanal. Die Maske ist nur 80 gross, aber eine
    # weiche runde Form vertraegt das Hochrechnen.
    alpha = Image.open(MASKE).convert("RGBA").split()[3].resize((n, n), Image.LANCZOS)
    bild.putalpha(alpha)
    return bild


def pruefen():
    """Die 80er nachbauen und mit dem MeeGo-Original vergleichen."""
    neu = zeichne(80).convert("RGBA")
    alt = Image.open(ORIGINAL).convert("RGBA")
    np, ap = neu.load(), alt.load()
    gleich = abweichend = 0
    for y in range(80):
        for x in range(80):
            a, b = np[x, y], ap[x, y]
            # Nur dort vergleichen, wo beide deckend sind; die Kantenglaettung
            # am Rand der Silhouette darf abweichen.
            if a[3] > 200 and b[3] > 200:
                if max(abs(a[i] - b[i]) for i in range(3)) <= 40:
                    gleich += 1
                else:
                    abweichend += 1
    anteil = 100.0 * gleich / max(1, gleich + abweichend)
    print("Deckungsgleich: %.1f %% (%d von %d deckenden Pixeln)"
          % (anteil, gleich, gleich + abweichend))
    return anteil >= 98.0


def main():
    if "--pruefen" in sys.argv:
        return 0 if pruefen() else 1
    for n in GROESSEN:
        ordner = os.path.join(WURZEL, "icons", "%dx%d" % (n, n))
        os.makedirs(ordner, exist_ok=True)
        ziel = os.path.join(ordner, "harbour-oe1radio.png")
        zeichne(n).save(ziel)
        print("%s  %d B" % (ziel, os.path.getsize(ziel)))
    return 0


if __name__ == "__main__":
    sys.exit(main())

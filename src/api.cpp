#include "api.h"

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QXmlStreamReader>
#include <QDateTime>
#include <QLocale>
#include <QUrl>
#include <QHash>

namespace {

const char *API_OE1  = "https://audioapi.orf.at/oe1/api/json/5.0";
const char *API_RTHK = "https://audioapi.orf.at/radiothek/api/2.0";

// Beitraege und Journale liegen auf einem *anderen* Dienst als das Programm.
// Steht so in der Android-App (StoryNetworkModule); auf dem Programmdienst
// antworten dieselben Pfade mit 404.
const char *API_APP = "https://oe1.orf.at/api/v1/app";

// Der Strom einer vergangenen Sendung. Dieselbe Adresse wie auf Harmattan --
// nur muss sie hier nicht erst durch einen Vermittler, gstreamer nimmt https.
QString loopAdresse(const QString &loopStreamId)
{
    return QStringLiteral("https://loopstream01.apa.at/?channel=oe1&shoutcast=0&id=%1")
            .arg(QString::fromLatin1(QUrl::toPercentEncoding(loopStreamId)));
}

// Die Bilder der Radiothek stehen nicht unter "url", sondern als benannte
// Fassungen unter image.versions.<name>.path -- und zwischen den Fassungen
// liegt noch ein "hashCode", der keine ist. 400x400 ("id3art") reicht fuer
// ein Telefon; sonst die erste brauchbare.
QString bildAus(const QJsonObject &bild)
{
    const QJsonObject fassungen = bild.value(QStringLiteral("versions")).toObject();
    const QJsonObject bevorzugt = fassungen.value(QStringLiteral("id3art")).toObject();
    if (!bevorzugt.isEmpty())
        return bevorzugt.value(QStringLiteral("path")).toString();
    for (auto it = fassungen.constBegin(); it != fassungen.constEnd(); ++it) {
        if (!it.value().isObject())
            continue;       // hashCode
        const QString pfad = it.value().toObject()
                .value(QStringLiteral("path")).toString();
        if (!pfad.isEmpty())
            return pfad;
    }
    return QString();
}

} // namespace

Api::Api(QObject *parent)
    : QObject(parent), m_netz(new QNetworkAccessManager(this))
{
}

QNetworkReply *Api::hole(const QString &url)
{
    QNetworkRequest r{QUrl(url)};
    // Weiterleitungen selbst folgen zu lassen spart eine Runde: podcast.orf.at
    // schickt http auf https, und die Feed-Adressen wandern gelegentlich.
    r.setAttribute(QNetworkRequest::FollowRedirectsAttribute, true);
    m_offen++;
    if (m_offen == 1)
        emit busyChanged();
    return m_netz->get(r);
}

void Api::fertig()
{
    if (m_offen > 0)
        m_offen--;
    if (m_offen == 0)
        emit busyChanged();
}

QString Api::tagVor(int tage) const
{
    return QDate::currentDate().addDays(-tage).toString(QStringLiteral("yyyyMMdd"));
}

QString Api::tagName(int tage) const
{
    if (tage == 0)
        return tr("Heute");
    if (tage == 1)
        return tr("Gestern");
    const QDate d = QDate::currentDate().addDays(-tage);
    return QLocale::system().dayName(d.dayOfWeek(), QLocale::LongFormat);
}

QString Api::liveAdresse(const QString &guete) const
{
    // Die Adressen stehen so in der Einstellungsdatei der ORF-App selbst
    // (appmeta.orf.at/configs/oe1/android/config.json): HLS als beste Guete,
    // Shoutcast auf orf-live.ors-shoutcast.at. Der aeltere Name ors-sn10
    // antwortet zwar noch, ist aber nicht mehr der genannte.
    // Auf Harmattan war HLS unbrauchbar; hier spielt gstreamer ihn mit
    // hlsdemux ohne Zutun.
    if (guete == QLatin1String("hoch"))
        return QStringLiteral("https://orf-live-oe1.mdn.ors.at/out/u/oe1/qxa/manifest.m3u8");
    if (guete == QLatin1String("mittel"))
        return QStringLiteral("https://orf-live.ors-shoutcast.at/oe1-q2a");
    return QStringLiteral("https://orf-live.ors-shoutcast.at/oe1-q1a");
}

QVariantMap Api::sendungAusJson(const QJsonObject &o) const
{
    QVariantMap m;
    m[QStringLiteral("id")]       = o.value(QStringLiteral("id")).toInt();
    m[QStringLiteral("titel")]    = o.value(QStringLiteral("title")).toString();
    m[QStringLiteral("untertitel")] = o.value(QStringLiteral("subtitle")).toString();
    m[QStringLiteral("text")]     = o.value(QStringLiteral("description")).toString();
    m[QStringLiteral("dauer")]    = o.value(QStringLiteral("duration")).toInt();
    m[QStringLiteral("abrufbar")] = o.value(QStringLiteral("isOnDemand")).toBool();
    // Beitraege und Journale verweisen ueber den Programmschluessel, nicht
    // ueber die id -- ohne ihn liesse sich von dort nichts abspielen.
    m[QStringLiteral("schluessel")] = o.value(QStringLiteral("programKey")).toString();
    m[QStringLiteral("tag")]        = QString::number(
                o.value(QStringLiteral("broadcastDay")).toInt());

    // start/end kommen als UTC; die Uhrzeit soll die oertliche sein.
    const QDateTime start = QDateTime::fromString(
                o.value(QStringLiteral("start")).toString(), Qt::ISODate).toLocalTime();
    const QDateTime ende = QDateTime::fromString(
                o.value(QStringLiteral("end")).toString(), Qt::ISODate).toLocalTime();
    m[QStringLiteral("beginn")]   = start;
    m[QStringLiteral("ende")]     = ende;
    m[QStringLiteral("zeit")]     = start.isValid()
            ? start.toString(QStringLiteral("HH:mm")) : QString();

    // Laeuft die Sendung gerade? Daran haengt die Marke im Tagesprogramm.
    const QDateTime jetzt = QDateTime::currentDateTime();
    m[QStringLiteral("laeuftJetzt")] = start.isValid() && ende.isValid()
            && start <= jetzt && jetzt < ende;

    // Das erste Bild reicht; die Schnittstelle legt mehrere Groessen ab.
    QString bild;
    const QJsonArray bilder = o.value(QStringLiteral("images")).toArray();
    if (!bilder.isEmpty()) {
        const QJsonArray fassungen = bilder.first().toObject()
                .value(QStringLiteral("versions")).toArray();
        if (!fassungen.isEmpty())
            bild = fassungen.last().toObject().value(QStringLiteral("path")).toString();
    }
    m[QStringLiteral("bild")] = bild;
    return m;
}

void Api::ladeTag(const QString &datum)
{
    QNetworkReply *a = hole(QStringLiteral("%1/broadcasts/%2").arg(API_OE1, datum));
    connect(a, &QNetworkReply::finished, this, [this, a, datum]() {
        a->deleteLater();
        fertig();
        if (a->error() != QNetworkReply::NoError) {
            emit fehler(a->errorString());
            return;
        }
        const QJsonObject wurzel = QJsonDocument::fromJson(a->readAll()).object();
        QVariantList aus;
        // payload ist die flache Liste der Sendungen dieses Tages.
        const QJsonArray nutz = wurzel.value(QStringLiteral("payload")).toArray();
        for (const QJsonValue &v : nutz)
            aus << sendungAusJson(v.toObject());
        m_tage.insert(datum, aus);
        emit tagGeladen(datum, aus);

        // Laeuft gerade eine Suche, pruefen ob der letzte Tag da ist.
        if (m_sucheOffen > 0 && --m_sucheOffen == 0)
            suche(m_suchText);
    });
}

void Api::ladeSendung(int id)
{
    QNetworkReply *a = hole(QStringLiteral("%1/broadcast/%2").arg(API_OE1).arg(id));
    connect(a, &QNetworkReply::finished, this, [this, a, id]() {
        a->deleteLater();
        fertig();
        if (a->error() != QNetworkReply::NoError) {
            emit fehler(a->errorString());
            return;
        }
        const QJsonObject nutz = QJsonDocument::fromJson(a->readAll())
                .object().value(QStringLiteral("payload")).toObject();
        QVariantMap m = sendungAusJson(nutz);
        m[QStringLiteral("id")] = id;

        // Die Abspieladresse steckt in streams[0].loopStreamId. Fehlt sie,
        // ist die Sendung (noch) nicht zum Nachhoeren da.
        const QJsonArray stroeme = nutz.value(QStringLiteral("streams")).toArray();
        if (!stroeme.isEmpty()) {
            const QJsonObject s = stroeme.first().toObject();
            const QString lid = s.value(QStringLiteral("loopStreamId")).toString();
            if (!lid.isEmpty())
                m[QStringLiteral("adresse")] = loopAdresse(lid);
            // offsetEnd ist die Laenge in ms -- verlaesslicher als duration,
            // wenn die Sendung vorzeitig endete.
            const int laenge = s.value(QStringLiteral("offsetEnd")).toInt();
            if (laenge > 0)
                m[QStringLiteral("dauer")] = laenge;
        }
        emit sendungGeladen(m);
    });
}

void Api::ladePodcasts()
{
    QNetworkReply *a = hole(QStringLiteral("%1/podcasts").arg(API_RTHK));
    connect(a, &QNetworkReply::finished, this, [this, a]() {
        a->deleteLater();
        fertig();
        if (a->error() != QNetworkReply::NoError) {
            emit fehler(a->errorString());
            return;
        }
        // payload ist nach Sender geschluesselt; uns geht nur "oe1" an.
        const QJsonObject nutz = QJsonDocument::fromJson(a->readAll())
                .object().value(QStringLiteral("payload")).toObject();
        QVariantList aus;
        for (const QJsonValue &v : nutz.value(QStringLiteral("oe1")).toArray()) {
            const QJsonObject p = v.toObject();
            QVariantMap m;
            m[QStringLiteral("id")]     = p.value(QStringLiteral("id")).toInt();
            m[QStringLiteral("titel")]  = p.value(QStringLiteral("title")).toString();
            m[QStringLiteral("text")]   = p.value(QStringLiteral("description")).toString();
            m[QStringLiteral("anzahl")] = p.value(QStringLiteral("episodeCount")).toInt();
            m[QStringLiteral("bild")]   = bildAus(p.value(QStringLiteral("image")).toObject());
            aus << m;
        }
        emit podcastsGeladen(aus);
    });
}

void Api::ladeFolgen(int podcastId)
{
    // Zwei Schritte: die JSON-Schnittstelle kennt die Folgen nicht, sie nennt
    // nur die Adresse des RSS-Feeds, und dort stehen sie.
    QNetworkReply *a = hole(QStringLiteral("%1/podcast/%2").arg(API_RTHK).arg(podcastId));
    connect(a, &QNetworkReply::finished, this, [this, a]() {
        a->deleteLater();
        fertig();
        if (a->error() != QNetworkReply::NoError) {
            emit fehler(a->errorString());
            return;
        }
        const QJsonObject nutz = QJsonDocument::fromJson(a->readAll())
                .object().value(QStringLiteral("payload")).toObject();
        const QJsonObject adressen = nutz.value(QStringLiteral("urls")).toObject();

        // Die Beschreibung faellt hier ohnehin an -- sie gehoert auf die
        // Seite, nicht in den Papierkorb.
        QVariantMap p;
        p[QStringLiteral("titel")]   = nutz.value(QStringLiteral("title")).toString();
        p[QStringLiteral("text")]    = nutz.value(QStringLiteral("description")).toString();
        p[QStringLiteral("autor")]   = nutz.value(QStringLiteral("author")).toString();
        p[QStringLiteral("rechte")]  = nutz.value(QStringLiteral("copyright")).toString();
        p[QStringLiteral("anzahl")]  = nutz.value(QStringLiteral("episodeCount")).toInt();
        p[QStringLiteral("bild")]    = bildAus(nutz.value(QStringLiteral("image")).toObject());
        p[QStringLiteral("feed")]    = adressen.value(QStringLiteral("feed")).toString();
        p[QStringLiteral("spotify")] = adressen.value(QStringLiteral("spotify")).toString();
        p[QStringLiteral("seite")]   = nutz.value(QStringLiteral("link")).toObject()
                .value(QStringLiteral("url")).toString();
        emit podcastGeladen(p);

        const QString feed = adressen.value(QStringLiteral("feed")).toString();
        if (feed.isEmpty()) {
            emit folgenGeladen({});
            return;
        }

        QNetworkReply *b = hole(feed);
        connect(b, &QNetworkReply::finished, this, [this, b]() {
            b->deleteLater();
            fertig();
            if (b->error() != QNetworkReply::NoError) {
                emit fehler(b->errorString());
                return;
            }
            QVariantList aus;
            QXmlStreamReader x(b->readAll());
            QVariantMap jetzt;
            bool imItem = false;
            while (!x.atEnd()) {
                x.readNext();
                if (x.isStartElement()) {
                    const QStringRef n = x.name();
                    if (n == QLatin1String("item")) {
                        imItem = true;
                        jetzt.clear();
                    } else if (imItem && n == QLatin1String("title")) {
                        jetzt[QStringLiteral("titel")] = x.readElementText();
                    } else if (imItem && n == QLatin1String("pubDate")) {
                        const QString roh = x.readElementText();
                        const QDateTime d = QDateTime::fromString(roh, Qt::RFC2822Date);
                        jetzt[QStringLiteral("datum")] = d.isValid()
                                ? d.toLocalTime().toString(QStringLiteral("dd.MM.yyyy"))
                                : roh;
                    } else if (imItem && n == QLatin1String("description")) {
                        jetzt[QStringLiteral("text")] = x.readElementText();
                    } else if (imItem && n == QLatin1String("enclosure")) {
                        // Hier steht die eigentliche Tondatei.
                        jetzt[QStringLiteral("adresse")] =
                                x.attributes().value(QStringLiteral("url")).toString();
                    }
                } else if (x.isEndElement() && x.name() == QLatin1String("item")) {
                    imItem = false;
                    if (!jetzt.value(QStringLiteral("adresse")).toString().isEmpty())
                        aus << jetzt;
                }
            }
            emit folgenGeladen(aus);
        });
    });
}

void Api::ladeBeitraege(int seite)
{
    QNetworkReply *a = hole(QStringLiteral("%1/article?page=%2").arg(API_APP).arg(seite));
    connect(a, &QNetworkReply::finished, this, [this, a]() {
        a->deleteLater();
        fertig();
        if (a->error() != QNetworkReply::NoError) {
            emit fehler(a->errorString());
            return;
        }
        const QJsonObject wurzel = QJsonDocument::fromJson(a->readAll()).object();
        QVariantList aus;
        for (const QJsonValue &v : wurzel.value(QStringLiteral("stories")).toArray()) {
            const QJsonObject b = v.toObject();
            QVariantMap m;
            // Die id ist hier der Programmschluessel, nicht die Sendungsnummer.
            m[QStringLiteral("schluessel")] = b.value(QStringLiteral("id")).toString();
            m[QStringLiteral("titel")]      = b.value(QStringLiteral("title")).toString();
            m[QStringLiteral("untertitel")] = b.value(QStringLiteral("subTitle")).toString();
            m[QStringLiteral("stichwort")]  = b.value(QStringLiteral("keyword")).toString();
            m[QStringLiteral("text")]       = b.value(QStringLiteral("teaser")).toString();
            m[QStringLiteral("art")]        = b.value(QStringLiteral("type")).toString();
            m[QStringLiteral("seite")]      = b.value(QStringLiteral("originalUrl")).toString();
            m[QStringLiteral("bild")]       = b.value(QStringLiteral("titleImage"))
                    .toObject().value(QStringLiteral("src")).toString();
            // Aus der Programmadresse laesst sich der Tag ablesen:
            // .../programm/20261017/846257/...
            const QString u = m[QStringLiteral("seite")].toString();
            const int i = u.indexOf(QStringLiteral("/programm/"));
            if (i >= 0)
                m[QStringLiteral("tag")] = u.mid(i + 10, 8);
            aus << m;
        }
        emit beitraegeGeladen(aus);
    });
}

void Api::ladeJournale()
{
    QNetworkReply *a = hole(QStringLiteral("%1/journale?page=0").arg(API_APP));
    connect(a, &QNetworkReply::finished, this, [this, a]() {
        a->deleteLater();
        fertig();
        if (a->error() != QNetworkReply::NoError) {
            emit fehler(a->errorString());
            return;
        }
        const QJsonObject wurzel = QJsonDocument::fromJson(a->readAll()).object();
        QVariantList tage;
        for (const QJsonValue &dv : wurzel.value(QStringLiteral("journalDays")).toArray()) {
            const QJsonObject d = dv.toObject();
            QVariantMap tag;
            const QDateTime t = QDateTime::fromString(
                        d.value(QStringLiteral("day")).toString(), Qt::ISODate);
            tag[QStringLiteral("tag")] = t.isValid()
                    ? t.toString(QStringLiteral("yyyyMMdd")) : QString();
            tag[QStringLiteral("name")] = t.isValid()
                    ? QLocale::system().toString(t.date(), QStringLiteral("dddd, d. MMMM"))
                    : QString();

            QVariantList journale;
            for (const QJsonValue &jv : d.value(QStringLiteral("journals")).toArray()) {
                const QJsonObject j = jv.toObject();
                QVariantMap journal;
                journal[QStringLiteral("titel")] = j.value(QStringLiteral("title")).toString();
                const QDateTime sendezeit = QDateTime::fromString(
                            j.value(QStringLiteral("airdate")).toString(), Qt::ISODate);
                journal[QStringLiteral("zeit")] = sendezeit.isValid()
                        ? sendezeit.toLocalTime().toString(QStringLiteral("HH:mm")) : QString();

                QVariantList stuecke;
                for (const QJsonValue &ev : j.value(QStringLiteral("elements")).toArray()) {
                    const QJsonObject e = ev.toObject();
                    QVariantMap stueck;
                    stueck[QStringLiteral("zeit")]  = e.value(QStringLiteral("time")).toString();
                    stueck[QStringLiteral("titel")] = e.value(QStringLiteral("title")).toString();
                    // Die Adresse hat die Form
                    // .../player/<tag>/<schluessel>/<beginn in ms>
                    const QString u = e.value(QStringLiteral("url")).toString();
                    const QStringList teile = u.split(QLatin1Char('/'), QString::SkipEmptyParts);
                    if (teile.size() >= 3) {
                        stueck[QStringLiteral("tag")]        = teile.at(teile.size() - 3);
                        stueck[QStringLiteral("schluessel")] = teile.at(teile.size() - 2);
                        stueck[QStringLiteral("beginn")]     = teile.last().toLongLong();
                    }
                    stuecke << stueck;
                }
                journal[QStringLiteral("stuecke")] = stuecke;
                journale << journal;
            }
            tag[QStringLiteral("journale")] = journale;
            tage << tag;
        }
        emit journaleGeladen(tage);
    });
}

void Api::ladeSendungNachSchluessel(const QString &datum, const QString &programKey,
                                    int versatzMs)
{
    // Der Tag ist vielleicht schon geladen -- dann ohne Netz auskommen.
    if (m_tage.contains(datum)) {
        for (const QVariant &v : m_tage.value(datum)) {
            const QVariantMap s = v.toMap();
            if (s.value(QStringLiteral("schluessel")).toString() == programKey) {
                ladeSendung(s.value(QStringLiteral("id")).toInt());
                return;
            }
        }
    }

    QNetworkReply *a = hole(QStringLiteral("%1/broadcasts/%2").arg(API_OE1, datum));
    connect(a, &QNetworkReply::finished, this, [this, a, datum, programKey, versatzMs]() {
        a->deleteLater();
        fertig();
        if (a->error() != QNetworkReply::NoError) {
            emit fehler(a->errorString());
            return;
        }
        const QJsonArray nutz = QJsonDocument::fromJson(a->readAll())
                .object().value(QStringLiteral("payload")).toArray();
        QVariantList tag;
        int treffer = -1;
        for (const QJsonValue &v : nutz) {
            const QVariantMap s = sendungAusJson(v.toObject());
            tag << s;
            if (s.value(QStringLiteral("schluessel")).toString() == programKey)
                treffer = s.value(QStringLiteral("id")).toInt();
        }
        m_tage.insert(datum, tag);
        if (treffer > 0) {
            Q_UNUSED(versatzMs)
            ladeSendung(treffer);
        } else {
            emit fehler(tr("Diese Sendung steht nicht mehr zum Nachhören bereit."));
        }
    });
}

void Api::suche(const QString &text)
{
    const QString gesucht = text.trimmed();
    if (gesucht.length() < 2) {
        emit sucheFertig(gesucht, {});
        return;
    }

    // Die Schnittstelle kennt keine Suche. Also die sieben vorgehaltenen Tage
    // holen (die meisten liegen ohnehin schon da) und oertlich filtern --
    // dasselbe Vorgehen wie in der MeeGo-Fassung.
    m_suchText = gesucht;
    int fehlen = 0;
    for (int i = 0; i < 7; ++i) {
        const QString d = tagVor(i);
        if (!m_tage.contains(d)) {
            fehlen++;
            ladeTag(d);
        }
    }
    if (fehlen > 0) {
        m_sucheOffen = fehlen;
        return;         // ladeTag() ruft suche() erneut, sobald alle da sind
    }

    QVariantList treffer;
    for (int i = 0; i < 7; ++i) {
        for (const QVariant &v : m_tage.value(tagVor(i))) {
            const QVariantMap s = v.toMap();
            if (s.value(QStringLiteral("titel")).toString().contains(gesucht, Qt::CaseInsensitive)
                || s.value(QStringLiteral("untertitel")).toString().contains(gesucht, Qt::CaseInsensitive)
                || s.value(QStringLiteral("text")).toString().contains(gesucht, Qt::CaseInsensitive)) {
                treffer << s;
            }
        }
    }
    emit sucheFertig(gesucht, treffer);
}

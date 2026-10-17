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

namespace {

const char *API_OE1  = "https://audioapi.orf.at/oe1/api/json/5.0";
const char *API_RTHK = "https://audioapi.orf.at/radiothek/api/2.0";

// Der Strom einer vergangenen Sendung. Dieselbe Adresse wie auf Harmattan --
// nur muss sie hier nicht erst durch einen Vermittler, gstreamer nimmt https.
QString loopAdresse(const QString &loopStreamId)
{
    return QStringLiteral("https://loopstream01.apa.at/?channel=oe1&shoutcast=0&id=%1")
            .arg(QString::fromLatin1(QUrl::toPercentEncoding(loopStreamId)));
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
        emit tagGeladen(datum, aus);
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
            m[QStringLiteral("bild")]   = p.value(QStringLiteral("image")).toObject()
                    .value(QStringLiteral("url")).toString();
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
        const QString feed = nutz.value(QStringLiteral("urls")).toObject()
                .value(QStringLiteral("feed")).toString();
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

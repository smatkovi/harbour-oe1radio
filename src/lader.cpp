#include "lader.h"

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSaveFile>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>
#include <QSettings>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrl>

Lader::Lader(QObject *parent)
    : QObject(parent), m_netz(new QNetworkAccessManager(this))
{
    einlesen();
}

Lader::~Lader()
{
    // Laufende Abrufe abbrechen; QSaveFile wird nicht beendet, die halben
    // Dateien verschwinden damit von selbst.
    for (auto it = m_laufend.begin(); it != m_laufend.end(); ++it) {
        if (it->antwort)
            it->antwort->abort();
        delete it->datei;
    }
}

QString Lader::ordner() const
{
    const QString basis = QStandardPaths::writableLocation(
                QStandardPaths::DownloadLocation);
    return basis + QStringLiteral("/Ö1");
}

QString Lader::pfadFuer(const QString &kennung, const QString &titel) const
{
    QString name = titel;
    // Alles, woran ein Dateisystem oder eine spaetere Shell haengenbleibt.
    name.replace(QRegExp(QStringLiteral("[/\\\\:*?\"<>|]")), QStringLiteral("-"));
    name = name.trimmed();
    if (name.isEmpty())
        name = QStringLiteral("Sendung");
    name.truncate(80);
    // Die Kennung mit in den Namen: zwei Folgen duerfen gleich heissen.
    QString sicher = kennung;
    sicher.replace(QRegExp(QStringLiteral("[^A-Za-z0-9_-]")), QStringLiteral("_"));
    sicher.truncate(40);
    return ordner() + QStringLiteral("/%1_%2.mp3").arg(name, sicher);
}

void Lader::einlesen()
{
    // Was schon auf der Platte liegt, merkt sich die App als **ein**
    // JSON-Feld. Die Kennung taugt naemlich nicht als QSettings-Schluessel:
    // dort ist "/" ein Gruppentrenner, und die Kennung einer Podcastfolge
    // ist ihre Adresse -- die zerfiele in ein Dutzend Untergruppen und
    // waere nach einem Neustart nicht wiederzufinden.
    m_fertig.clear();
    const QByteArray roh = QSettings().value(QStringLiteral("aufnahmen"))
            .toByteArray();
    if (roh.isEmpty())
        return;
    const QJsonObject o = QJsonDocument::fromJson(roh).object();
    for (auto it = o.constBegin(); it != o.constEnd(); ++it) {
        const QString pfad = it.value().toString();
        if (QFile::exists(pfad))
            m_fertig.insert(it.key(), pfad);
    }
}

void Lader::sichern()
{
    QJsonObject o;
    for (auto it = m_fertig.constBegin(); it != m_fertig.constEnd(); ++it)
        o.insert(it.key(), it.value());
    QSettings().setValue(QStringLiteral("aufnahmen"),
                         QJsonDocument(o).toJson(QJsonDocument::Compact));
}

QVariantList Lader::aufnahmen() const
{
    QVariantList aus;
    for (auto it = m_laufend.constBegin(); it != m_laufend.constEnd(); ++it) {
        QVariantMap m;
        m[QStringLiteral("kennung")]    = it.key();
        m[QStringLiteral("titel")]      = it->titel;
        m[QStringLiteral("laeuft")]     = true;
        m[QStringLiteral("anteil")]     = it->anteil;
        aus << m;
    }
    for (auto it = m_fertig.constBegin(); it != m_fertig.constEnd(); ++it) {
        QVariantMap m;
        m[QStringLiteral("kennung")] = it.key();
        m[QStringLiteral("titel")]   = QFileInfo(it.value()).completeBaseName()
                                        .section(QLatin1Char('_'), 0, -2);
        m[QStringLiteral("laeuft")]  = false;
        m[QStringLiteral("anteil")]  = 1.0;
        m[QStringLiteral("pfad")]    = it.value();
        m[QStringLiteral("groesse")] = QFileInfo(it.value()).size();
        aus << m;
    }
    return aus;
}

QString Lader::dateiAdresse(const QString &kennung) const
{
    const QString pfad = m_fertig.value(kennung);
    return pfad.isEmpty() ? QString() : QUrl::fromLocalFile(pfad).toString();
}

double Lader::fortschritt(const QString &kennung) const
{
    if (m_laufend.contains(kennung))
        return m_laufend.value(kennung).anteil;
    return m_fertig.contains(kennung) ? 1.0 : -1.0;
}

void Lader::hole(const QString &kennung, const QString &titel, const QString &adresse)
{
    if (m_laufend.contains(kennung) || m_fertig.contains(kennung))
        return;
    if (adresse.isEmpty()) {
        emit fehler(kennung, tr("Keine Adresse zum Herunterladen."));
        return;
    }
    QDir().mkpath(ordner());

    Lauf lauf;
    lauf.titel = titel;
    lauf.pfad = pfadFuer(kennung, titel);
    lauf.datei = new QSaveFile(lauf.pfad);
    if (!lauf.datei->open(QIODevice::WriteOnly)) {
        emit fehler(kennung, lauf.datei->errorString());
        delete lauf.datei;
        return;
    }

    QNetworkRequest r{QUrl(adresse)};
    r.setAttribute(QNetworkRequest::FollowRedirectsAttribute, true);
    lauf.antwort = m_netz->get(r);
    m_laufend.insert(kennung, lauf);
    emit aufnahmenChanged();

    QNetworkReply *antwort = lauf.antwort;

    connect(antwort, &QNetworkReply::downloadProgress, this,
            [this, kennung](qint64 da, qint64 gesamt) {
        auto it = m_laufend.find(kennung);
        if (it == m_laufend.end())
            return;
        it->anteil = gesamt > 0 ? double(da) / double(gesamt) : 0.0;
        emit aufnahmenChanged();
    });

    // Mitschreiben statt am Ende alles auf einmal: eine Sendung hat leicht
    // 60 MB, die muessen nicht erst in den Arbeitsspeicher.
    connect(antwort, &QNetworkReply::readyRead, this, [this, kennung, antwort]() {
        auto it = m_laufend.find(kennung);
        if (it != m_laufend.end() && it->datei)
            it->datei->write(antwort->readAll());
    });

    connect(antwort, &QNetworkReply::finished, this, [this, kennung, antwort]() {
        antwort->deleteLater();
        auto it = m_laufend.find(kennung);
        if (it == m_laufend.end())
            return;
        QSaveFile *datei = it->datei;
        const QString pfad = it->pfad;
        const bool gut = antwort->error() == QNetworkReply::NoError;
        if (gut && datei) {
            datei->write(antwort->readAll());
            datei->commit();        // erst jetzt wird die Datei sichtbar
        }
        const QString meldung = gut ? QString() : antwort->errorString();
        delete datei;
        m_laufend.remove(kennung);

        if (gut) {
            m_fertig.insert(kennung, pfad);
            sichern();
            emit fertig(kennung, pfad);
        } else {
            emit fehler(kennung, meldung);
        }
        emit aufnahmenChanged();
    });
}

void Lader::abbrechen(const QString &kennung)
{
    auto it = m_laufend.find(kennung);
    if (it == m_laufend.end())
        return;
    if (it->antwort)
        it->antwort->abort();       // finished() raeumt den Rest auf
}

void Lader::loeschen(const QString &kennung)
{
    const QString pfad = m_fertig.value(kennung);
    if (pfad.isEmpty())
        return;
    QFile::remove(pfad);
    m_fertig.remove(kennung);
    sichern();
    emit aufnahmenChanged();
}

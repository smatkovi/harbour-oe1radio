#include "merker.h"

#include <QSettings>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>

Merker::Merker(QObject *parent) : QObject(parent)
{
    // Als JSON in einem Schluessel statt als QSettings-Baum: eine Liste von
    // Abbildungen laesst sich so in einem Stueck lesen und schreiben, ohne
    // dass eine abgebrochene Aenderung halbe Eintraege hinterlaesst.
    QSettings s;
    const QByteArray roh = s.value(QStringLiteral("favoriten")).toByteArray();
    if (roh.isEmpty())
        return;
    const QJsonArray a = QJsonDocument::fromJson(roh).array();
    for (const QJsonValue &v : a)
        m_eintraege << v.toObject().toVariantMap();
}

void Merker::sichern()
{
    QJsonArray a;
    for (const QVariant &v : m_eintraege)
        a.append(QJsonObject::fromVariantMap(v.toMap()));
    QSettings s;
    s.setValue(QStringLiteral("favoriten"),
               QJsonDocument(a).toJson(QJsonDocument::Compact));
}

bool Merker::gemerkt(const QString &kennung) const
{
    for (const QVariant &v : m_eintraege)
        if (v.toMap().value(QStringLiteral("kennung")).toString() == kennung)
            return true;
    return false;
}

void Merker::merken(const QString &kennung, const QVariantMap &daten)
{
    if (kennung.isEmpty() || gemerkt(kennung))
        return;
    QVariantMap m = daten;
    m[QStringLiteral("kennung")] = kennung;
    m_eintraege.prepend(m);
    sichern();
    emit eintraegeChanged();
}

void Merker::vergessen(const QString &kennung)
{
    for (int i = 0; i < m_eintraege.size(); ++i) {
        if (m_eintraege.at(i).toMap().value(QStringLiteral("kennung")).toString() == kennung) {
            m_eintraege.removeAt(i);
            sichern();
            emit eintraegeChanged();
            return;
        }
    }
}

void Merker::umschalten(const QString &kennung, const QVariantMap &daten)
{
    if (gemerkt(kennung))
        vergessen(kennung);
    else
        merken(kennung, daten);
}

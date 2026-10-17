#include "einstellungen.h"

#include <QSettings>

Einstellungen::Einstellungen(QObject *parent) : QObject(parent)
{
    QSettings s;
    m_farbschema = s.value(QStringLiteral("farbschema"),
                           QStringLiteral("ambience")).toString();
    m_guete      = s.value(QStringLiteral("guete"),
                           QStringLiteral("niedrig")).toString();
    m_autoplay   = s.value(QStringLiteral("autoplay"), false).toBool();
}

void Einstellungen::setFarbschema(const QString &w)
{
    if (m_farbschema == w)
        return;
    m_farbschema = w;
    QSettings().setValue(QStringLiteral("farbschema"), w);
    emit farbschemaChanged();
}


void Einstellungen::setGuete(const QString &w)
{
    if (m_guete == w)
        return;
    m_guete = w;
    QSettings().setValue(QStringLiteral("guete"), w);
    emit gueteChanged();
}

void Einstellungen::setAutoplay(bool w)
{
    if (m_autoplay == w)
        return;
    m_autoplay = w;
    QSettings().setValue(QStringLiteral("autoplay"), w);
    emit autoplayChanged();
}

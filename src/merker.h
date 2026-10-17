#ifndef MERKER_H
#define MERKER_H

#include <QObject>
#include <QVariantList>

/*!
 * Die Favoriten. Die Android-App hat kein Konto, also bleibt die Liste auf
 * dem Geraet -- in QSettings, deren Kennung zur .desktop-Datei passen muss,
 * sonst merkt sich die App im Sandkasten nichts.
 */
class Merker : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList eintraege READ eintraege NOTIFY eintraegeChanged)

public:
    explicit Merker(QObject *parent = nullptr);

    QVariantList eintraege() const { return m_eintraege; }

    Q_INVOKABLE bool gemerkt(const QString &kennung) const;
    Q_INVOKABLE void merken(const QString &kennung, const QVariantMap &daten);
    Q_INVOKABLE void vergessen(const QString &kennung);
    Q_INVOKABLE void umschalten(const QString &kennung, const QVariantMap &daten);

signals:
    void eintraegeChanged();

private:
    void sichern();

    QVariantList m_eintraege;
};

#endif // MERKER_H

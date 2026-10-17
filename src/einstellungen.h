#ifndef EINSTELLUNGEN_H
#define EINSTELLUNGEN_H

#include <QObject>

/*!
 * Was sich die App merkt. Liegt in QSettings, deren Kennung zur
 * .desktop-Datei passen muss -- sonst vergisst die App im Sandkasten alles,
 * sobald sie ueber das Symbol gestartet wird.
 */
class Einstellungen : public QObject
{
    Q_OBJECT
    //! "ambience" (folgt der Ambience), "dunkel" oder "hell".
    Q_PROPERTY(QString farbschema READ farbschema WRITE setFarbschema NOTIFY farbschemaChanged)
    //! true: Ö1-Rot als Akzent. false: die Akzentfarbe der Ambience.
    Q_PROPERTY(bool oe1Rot READ oe1Rot WRITE setOe1Rot NOTIFY oe1RotChanged)
    //! "niedrig", "mittel" oder "hoch".
    Q_PROPERTY(QString guete READ guete WRITE setGuete NOTIFY gueteChanged)
    //! Beim Start gleich den Livestrom spielen (hat die Android-App auch).
    Q_PROPERTY(bool autoplay READ autoplay WRITE setAutoplay NOTIFY autoplayChanged)

public:
    explicit Einstellungen(QObject *parent = nullptr);

    QString farbschema() const { return m_farbschema; }
    void setFarbschema(const QString &w);

    bool oe1Rot() const { return m_oe1Rot; }
    void setOe1Rot(bool w);

    QString guete() const { return m_guete; }
    void setGuete(const QString &w);

    bool autoplay() const { return m_autoplay; }
    void setAutoplay(bool w);

signals:
    void farbschemaChanged();
    void oe1RotChanged();
    void gueteChanged();
    void autoplayChanged();

private:
    QString m_farbschema;
    bool m_oe1Rot;
    QString m_guete;
    bool m_autoplay;
};

#endif // EINSTELLUNGEN_H

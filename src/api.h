#ifndef API_H
#define API_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class QNetworkAccessManager;
class QNetworkReply;

/*!
 * Der Zugriff auf die ORF-Schnittstellen.
 *
 * Auf Harmattan musste dafuer ein fremdes wget herhalten, weil Qt 4.7 dort an
 * einem OpenSSL von 2011 haengt und der Mediaplayer ueberhaupt kein TLS kann.
 * Auf Sailfish faellt das alles weg: Qt 5 spricht TLS selbst, und gstreamer
 * nimmt eine https-Adresse ohne Umweg. Deshalb gibt es hier weder Hilfsprozess
 * noch Vermittler auf der Rueckschleife -- nur QNetworkAccessManager.
 */
class Api : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

public:
    explicit Api(QObject *parent = nullptr);

    bool busy() const { return m_offen > 0; }

    //! Das Tagesprogramm eines Tages, Datum als JJJJMMTT.
    Q_INVOKABLE void ladeTag(const QString &datum);

    //! Eine Sendung samt Abspieladresse; antwortet mit sendungGeladen().
    Q_INVOKABLE void ladeSendung(int id);

    //! Die Ö1-Podcasts (die Schnittstelle liefert alle Sender auf einmal).
    Q_INVOKABLE void ladePodcasts();

    //! Die Folgen eines Podcasts -- sie stehen nur im RSS-Feed, nicht in der
    //! JSON-Schnittstelle, siehe ladeFolgen().
    Q_INVOKABLE void ladeFolgen(int podcastId);

    //! Datum von heute minus \a tage als JJJJMMTT -- die Schnittstelle haelt
    //! sieben Tage vor.
    Q_INVOKABLE QString tagVor(int tage) const;

    //! Anzeigename eines solchen Datums ("Heute", "Gestern", "Mittwoch").
    Q_INVOKABLE QString tagName(int tage) const;

    //! Die Adresse des Livestroms in der gewuenschten Guete.
    Q_INVOKABLE QString liveAdresse(const QString &guete) const;

signals:
    void busyChanged();
    void tagGeladen(const QString &datum, const QVariantList &sendungen);
    void sendungGeladen(const QVariantMap &sendung);
    void podcastsGeladen(const QVariantList &podcasts);
    void folgenGeladen(const QVariantList &folgen);
    void fehler(const QString &text);

private:
    QNetworkReply *hole(const QString &url);
    void fertig();
    QVariantMap sendungAusJson(const QJsonObject &o) const;

    QNetworkAccessManager *m_netz;
    int m_offen = 0;
};

#endif // API_H

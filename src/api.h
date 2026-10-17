#ifndef API_H
#define API_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class QNetworkAccessManager;
class QNetworkReply;
class QJsonObject;

/*!
 * Der Zugriff auf die ORF-Schnittstellen.
 *
 * Auf Harmattan musste dafuer ein fremdes wget herhalten, weil Qt 4.7 dort an
 * einem OpenSSL von 2011 haengt und der Mediaplayer ueberhaupt kein TLS kann.
 * Auf Sailfish faellt das alles weg: Qt 5 spricht TLS selbst, und gstreamer
 * nimmt eine https-Adresse ohne Umweg. Deshalb gibt es hier weder Hilfsprozess
 * noch Vermittler auf der Rueckschleife -- nur QNetworkAccessManager.
 *
 * Zwei Dienste, nicht einer: das Programm kommt von `audioapi.orf.at`,
 * Beitraege und Journale von `oe1.orf.at/api/v1/app/`. Welcher Pfad wohin
 * gehoert, steht in der Android-App (StoryNetworkModule gegen
 * RadioNetworkModule) -- geraten haette man es nicht, beide antworten auf
 * falsche Pfade mit 404.
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

    //! Die Beitraege ("Highlights") der Startseite.
    Q_INVOKABLE void ladeBeitraege(int seite = 0);

    //! Die Journale der letzten Tage, nach Tag gruppiert.
    Q_INVOKABLE void ladeJournale();

    //! Sucht in den sieben vorgehaltenen Tagen. Die Schnittstelle kann das
    //! nicht, also wird oertlich gefiltert -- wie in der MeeGo-Fassung.
    Q_INVOKABLE void suche(const QString &text);

    //! Loest einen Programmschluessel (aus Beitraegen und Journalen) in die
    //! Sendung dieses Tages auf; antwortet ebenfalls mit sendungGeladen().
    Q_INVOKABLE void ladeSendungNachSchluessel(const QString &datum,
                                               const QString &programKey,
                                               int versatzMs = 0);

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
    void beitraegeGeladen(const QVariantList &beitraege);
    void journaleGeladen(const QVariantList &tage);
    void sucheFertig(const QString &text, const QVariantList &treffer);
    void fehler(const QString &text);

private:
    QNetworkReply *hole(const QString &url);
    void fertig();
    QVariantMap sendungAusJson(const QJsonObject &o) const;

    QNetworkAccessManager *m_netz;
    int m_offen = 0;

    // Fuer die Suche: die geladenen Tage, Datum -> Sendungen.
    QHash<QString, QVariantList> m_tage;
    QString m_suchText;
    int m_sucheOffen = 0;
};

#endif // API_H

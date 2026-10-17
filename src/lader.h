#ifndef LADER_H
#define LADER_H

#include <QObject>
#include <QVariantList>
#include <QHash>

class QNetworkAccessManager;
class QNetworkReply;
class QSaveFile;

/*!
 * Holt Sendungen und Podcastfolgen auf das Geraet.
 *
 * Die Android-App kann das nicht -- hier ist es gewuenscht, weil ein Zug
 * durch Oesterreich mehr Funkloecher hat als die Sendung Pausen.
 *
 * Geschrieben wird nach `~/Downloads/Ö1`, also in das Verzeichnis, das
 * Sailjail mit der Berechtigung `Downloads` freigibt. Waehrend des Ladens
 * liegt die Datei als QSaveFile daneben und wird erst beim Abschluss an
 * ihren Platz gelegt -- ein Abbruch hinterlaesst damit keine halbe Datei,
 * die hinterher als fertige Aufnahme gilt.
 */
class Lader : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList aufnahmen READ aufnahmen NOTIFY aufnahmenChanged)
    Q_PROPERTY(bool laedt READ laedt NOTIFY aufnahmenChanged)

public:
    explicit Lader(QObject *parent = nullptr);
    ~Lader() override;

    QVariantList aufnahmen() const;
    bool laedt() const { return !m_laufend.isEmpty(); }

    //! Beginnt einen Abruf. \a kennung unterscheidet die Aufnahmen
    //! (Sendungsnummer oder Folgenadresse), \a titel benennt die Datei.
    Q_INVOKABLE void hole(const QString &kennung, const QString &titel,
                          const QString &adresse);

    //! Bricht einen laufenden Abruf ab.
    Q_INVOKABLE void abbrechen(const QString &kennung);

    //! Loescht eine fertige Aufnahme.
    Q_INVOKABLE void loeschen(const QString &kennung);

    //! Ist etwas schon da, gibt das die Dateiadresse, sonst leer.
    Q_INVOKABLE QString dateiAdresse(const QString &kennung) const;

    //! Fortschritt 0..1 eines laufenden Abrufs, sonst -1.
    Q_INVOKABLE double fortschritt(const QString &kennung) const;

signals:
    void aufnahmenChanged();
    void fertig(const QString &kennung, const QString &pfad);
    void fehler(const QString &kennung, const QString &text);

private:
    struct Lauf {
        QNetworkReply *antwort = nullptr;
        QSaveFile *datei = nullptr;
        QString titel;
        QString pfad;
        double anteil = 0.0;
    };

    QString ordner() const;
    QString pfadFuer(const QString &kennung, const QString &titel) const;
    void einlesen();
    void sichern();

    QNetworkAccessManager *m_netz;
    QHash<QString, Lauf> m_laufend;
    // kennung -> Pfad der fertigen Datei
    QHash<QString, QString> m_fertig;
};

#endif // LADER_H

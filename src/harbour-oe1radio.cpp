#include <QtQuick>
#include <QGuiApplication>
#include <QQuickView>
#include <QScopedPointer>
#include <sailfishapp.h>

#include "api.h"
#include "lader.h"
#include "merker.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    // Muss zur Kennung in der .desktop-Datei passen, sonst bekommt die App im
    // Sandkasten bei jedem Start einen leeren Speicher und merkt sich nichts.
    app->setOrganizationName(QStringLiteral("harbour-oe1radio"));
    app->setApplicationName(QStringLiteral("harbour-oe1radio"));
    app->setApplicationVersion(QStringLiteral(APP_VERSION));

    QScopedPointer<QQuickView> view(SailfishApp::createView());

    // Als Kontext-Eigenschaft statt als registrierter Typ: so sieht jede
    // QML-Datei dieselbe Instanz, ohne sie durchreichen zu muessen. (Die
    // Harmattan-Fassung macht es mit "oe1" genauso.)
    Api api;
    Lader lader;
    Merker merker;
    view->rootContext()->setContextProperty(QStringLiteral("oe1"), &api);
    view->rootContext()->setContextProperty(QStringLiteral("lader"), &lader);
    view->rootContext()->setContextProperty(QStringLiteral("merker"), &merker);
    view->rootContext()->setContextProperty(QStringLiteral("appVersion"),
                                           QStringLiteral(APP_VERSION));
    view->setSource(SailfishApp::pathTo(QStringLiteral("qml/harbour-oe1radio.qml")));
    view->show();

    return app->exec();
}

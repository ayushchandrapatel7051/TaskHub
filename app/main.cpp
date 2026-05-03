#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>
#include "../cpp/services/LocalCacheService.h"
#include "../cpp/services/TaskService.h"
#include "../cpp/services/AuthService.h"
#include "../cpp/services/FirestoreService.h"
#include "../cpp/services/SyncService.h"
#include "../cpp/viewmodels/TaskListViewModel.h"

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
    app.setOrganizationName("TaskHub");
    app.setOrganizationDomain("taskhub.local");
    app.setApplicationName("TaskHub");

    // Load Firebase Config
    QString apiKey = "";
    QString projectId = "";
    
    QFile configFile(":/resources/firebase_config.json");
    if (configFile.open(QIODevice::ReadOnly)) {
        QByteArray data = configFile.readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        QJsonObject obj = doc.object();
        apiKey = obj["apiKey"].toString();
        projectId = obj["projectId"].toString();
    } else {
        qWarning() << "Could not open firebase_config.json from resources!";
    }

    // Initialize Services
    LocalCacheService localCacheService;
    TaskService taskService(&localCacheService);
    
    AuthService authService(apiKey);
    FirestoreService firestoreService(&authService, projectId);
    SyncService syncService(&localCacheService, &firestoreService);
    QObject::connect(&syncService, &SyncService::tasksChanged,
                     &taskService, &TaskService::tasksChanged);
    
    // Auto-start sync loop
    syncService.startSync();

    // Initialize ViewModels
    TaskListViewModel taskListViewModel(&taskService);

    QQmlApplicationEngine engine;
    
    // Inject ViewModel into QML context
    engine.rootContext()->setContextProperty("taskListViewModel", &taskListViewModel);
    engine.rootContext()->setContextProperty("authService", &authService);
    engine.rootContext()->setContextProperty("syncService", &syncService);

    const QUrl url(u"qrc:/qml/Main.qml"_s);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}

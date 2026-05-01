#ifndef FIRESTORE_SERVICE_H
#define FIRESTORE_SERVICE_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QList>
#include "../models/Task.h"
#include "AuthService.h"

class FirestoreService : public QObject {
    Q_OBJECT
public:
    explicit FirestoreService(AuthService* authService, const QString& projectId, QObject *parent = nullptr);

    // REST API methods for Firestore
    void syncTasksUp(const QList<Task>& tasksToSync);
    void fetchRemoteTasks();

signals:
    void syncCompleted(bool success);
    void remoteTasksFetched(const QList<Task>& tasks);

private slots:
    void onFetchReply(QNetworkReply* reply);
    void onSyncReply(QNetworkReply* reply);

private:
    QNetworkAccessManager m_networkManager;
    AuthService* m_authService;
    QString m_projectId;
};

#endif // FIRESTORE_SERVICE_H

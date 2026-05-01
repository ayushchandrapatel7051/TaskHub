#include "FirestoreService.h"
#include <QNetworkRequest>
#include <QUrl>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

FirestoreService::FirestoreService(AuthService* authService, const QString& projectId, QObject *parent) 
    : QObject(parent), m_authService(authService), m_projectId(projectId) {
}

void FirestoreService::syncTasksUp(const QList<Task>& tasksToSync) {
    if (!m_authService->isAuthenticated()) return;

    // For simplicity in MVP, we patch documents individually
    for (const Task& task : tasksToSync) {
        QString urlStr = QString("https://firestore.googleapis.com/v1/projects/%1/databases/(default)/documents/tasks/%2?updateMask.fieldPaths=title&updateMask.fieldPaths=status")
                             .arg(m_projectId, task.id);
        
        QUrl url(urlStr);
        QNetworkRequest request(url);
        request.setRawHeader("Authorization", QString("Bearer %1").arg(m_authService->getIdToken()).toUtf8());
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

        // Convert task to Firestore Document format
        QJsonObject docJson;
        QJsonObject fields;
        
        QJsonObject titleField; titleField["stringValue"] = task.title;
        fields["title"] = titleField;
        
        QJsonObject statusField; statusField["stringValue"] = task.status;
        fields["status"] = statusField;
        
        docJson["fields"] = fields;
        
        QNetworkReply* reply = m_networkManager.sendCustomRequest(request, "PATCH", QJsonDocument(docJson).toJson());
        connect(reply, &QNetworkReply::finished, this, [this, reply]() { onSyncReply(reply); });
    }
}

void FirestoreService::onSyncReply(QNetworkReply* reply) {
    reply->deleteLater();
    if (reply->error() == QNetworkReply::NoError) {
        emit syncCompleted(true);
    } else {
        qWarning() << "Sync Up Error:" << reply->errorString();
        emit syncCompleted(false);
    }
}

void FirestoreService::fetchRemoteTasks() {
    if (!m_authService->isAuthenticated()) return;

    QString urlStr = QString("https://firestore.googleapis.com/v1/projects/%1/databases/(default)/documents/tasks").arg(m_projectId);
    QUrl url(urlStr);
    QNetworkRequest request(url);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_authService->getIdToken()).toUtf8());

    QNetworkReply* reply = m_networkManager.get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() { onFetchReply(reply); });
}

void FirestoreService::onFetchReply(QNetworkReply* reply) {
    reply->deleteLater();
    QList<Task> remoteTasks;
    
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray response = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(response);
        QJsonArray documents = doc.object()["documents"].toArray();
        
        for (const QJsonValue& val : documents) {
            QJsonObject docObj = val.toObject();
            QJsonObject fields = docObj["fields"].toObject();
            
            Task t;
            // Parse name like "projects/X/databases/(default)/documents/tasks/ID"
            QString name = docObj["name"].toString();
            t.id = name.split("/").last();
            t.title = fields["title"].toObject()["stringValue"].toString();
            t.status = fields["status"].toObject()["stringValue"].toString();
            
            remoteTasks.append(t);
        }
    } else {
        qWarning() << "Fetch Remote Tasks Error:" << reply->errorString();
    }
    
    emit remoteTasksFetched(remoteTasks);
}

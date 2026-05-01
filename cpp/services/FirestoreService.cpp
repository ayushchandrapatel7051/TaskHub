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
    if (!m_authService->isAuthenticated() || tasksToSync.isEmpty()) return;

    QString urlStr = QString("https://firestore.googleapis.com/v1/projects/%1/databases/(default)/documents:commit").arg(m_projectId);
    QUrl url(urlStr);
    QNetworkRequest request(url);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_authService->getIdToken()).toUtf8());
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject commitJson;
    QJsonArray writesArray;
    QStringList taskIds;

    for (const Task& task : tasksToSync) {
        taskIds.append(task.id);
        
        QJsonObject writeObj;
        QJsonObject updateObj;
        updateObj["name"] = QString("projects/%1/databases/(default)/documents/tasks/%2").arg(m_projectId, task.id);
        
        QJsonObject fields;
        QJsonObject titleField; titleField["stringValue"] = task.title;
        fields["title"] = titleField;
        
        QJsonObject statusField; statusField["stringValue"] = task.status;
        fields["status"] = statusField;
        
        updateObj["fields"] = fields;
        writeObj["update"] = updateObj;
        writesArray.append(writeObj);
    }
    
    commitJson["writes"] = writesArray;

    QNetworkReply* reply = m_networkManager.post(request, QJsonDocument(commitJson).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply, taskIds]() { 
        reply->deleteLater();
        if (reply->error() == QNetworkReply::NoError) {
            emit syncCompleted(true, taskIds);
        } else {
            qWarning() << "Sync Up Batch Error:" << reply->errorString();
            emit syncCompleted(false, QStringList());
        }
    });
}

void FirestoreService::onSyncReply(QNetworkReply* reply) {
    // Deprecated, handled by lambda
}

void FirestoreService::fetchRemoteTasks(const QString& pageToken) {
    if (!m_authService->isAuthenticated()) return;

    QString urlStr = QString("https://firestore.googleapis.com/v1/projects/%1/databases/(default)/documents/tasks").arg(m_projectId);
    if (!pageToken.isEmpty()) {
        urlStr += "?pageToken=" + pageToken;
    }
    
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
        
        QString nextPageToken = doc.object()["nextPageToken"].toString();
        if (!nextPageToken.isEmpty()) {
            fetchRemoteTasks(nextPageToken);
        }
    } else {
        qWarning() << "Fetch Remote Tasks Error:" << reply->errorString();
    }
    
    emit remoteTasksFetched(remoteTasks);
}

#include "FirestoreService.h"
#include <QNetworkRequest>
#include <QUrl>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

namespace {
QJsonObject stringField(const QString& value) {
    QJsonObject field;
    field["stringValue"] = value;
    return field;
}

QJsonObject integerField(int value) {
    QJsonObject field;
    field["integerValue"] = QString::number(value);
    return field;
}

QJsonObject booleanField(bool value) {
    QJsonObject field;
    field["booleanValue"] = value;
    return field;
}

QJsonObject stringArrayField(const QStringList& values) {
    QJsonArray arrayValues;
    for (const QString& value : values) {
        arrayValues.append(stringField(value));
    }

    QJsonObject arrayValue;
    arrayValue["values"] = arrayValues;

    QJsonObject field;
    field["arrayValue"] = arrayValue;
    return field;
}

QString readStringField(const QJsonObject& fields, const QString& name, const QString& defaultValue = QString()) {
    QJsonObject field = fields[name].toObject();
    return field.contains("stringValue") ? field["stringValue"].toString() : defaultValue;
}

int readIntegerField(const QJsonObject& fields, const QString& name, int defaultValue = 0) {
    QJsonObject field = fields[name].toObject();
    if (!field.contains("integerValue")) {
        return defaultValue;
    }
    return field["integerValue"].toVariant().toInt();
}

bool readBooleanField(const QJsonObject& fields, const QString& name, bool defaultValue = false) {
    QJsonObject field = fields[name].toObject();
    return field.contains("booleanValue") ? field["booleanValue"].toBool() : defaultValue;
}

QStringList readStringArrayField(const QJsonObject& fields, const QString& name) {
    QStringList values;
    QJsonArray arrayValues = fields[name].toObject()["arrayValue"].toObject()["values"].toArray();
    for (const QJsonValue& value : arrayValues) {
        values.append(value.toObject()["stringValue"].toString());
    }
    return values;
}

QDateTime readDateTimeField(const QJsonObject& fields, const QString& name) {
    return QDateTime::fromString(readStringField(fields, name), Qt::ISODate);
}
}

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
        fields["listId"] = stringField(task.listId);
        fields["title"] = stringField(task.title);
        fields["description"] = stringField(task.description);
        fields["priority"] = integerField(task.priority);
        fields["status"] = stringField(task.status);
        fields["dueAt"] = stringField(task.dueAt.isValid() ? task.dueAt.toString(Qt::ISODate) : "");
        fields["startAt"] = stringField(task.startAt.isValid() ? task.startAt.toString(Qt::ISODate) : "");
        fields["repeatRule"] = stringField(task.repeatRule);
        fields["tags"] = stringArrayField(task.tags);
        fields["isPinned"] = booleanField(task.isPinned);
        fields["isCompleted"] = booleanField(task.isCompleted);
        fields["orderIndex"] = integerField(task.orderIndex);
        fields["createdAt"] = stringField(task.createdAt.isValid() ? task.createdAt.toString(Qt::ISODate) : "");
        fields["updatedAt"] = stringField(task.updatedAt.isValid() ? task.updatedAt.toString(Qt::ISODate) : "");
        
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
            t.listId = readStringField(fields, "listId");
            t.title = readStringField(fields, "title");
            t.description = readStringField(fields, "description");
            t.priority = readIntegerField(fields, "priority");
            t.status = readStringField(fields, "status", "todo");
            t.dueAt = readDateTimeField(fields, "dueAt");
            t.startAt = readDateTimeField(fields, "startAt");
            t.repeatRule = readStringField(fields, "repeatRule");
            t.tags = readStringArrayField(fields, "tags");
            t.isPinned = readBooleanField(fields, "isPinned");
            t.isCompleted = readBooleanField(fields, "isCompleted", t.status == "completed");
            t.orderIndex = readIntegerField(fields, "orderIndex");
            t.createdAt = readDateTimeField(fields, "createdAt");
            t.updatedAt = readDateTimeField(fields, "updatedAt");
            t.isDirty = false;
            
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

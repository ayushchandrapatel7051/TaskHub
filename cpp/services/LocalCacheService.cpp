#include "LocalCacheService.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>

LocalCacheService::LocalCacheService(QObject *parent) : QObject(parent) {
    initializeDB();
}

LocalCacheService::~LocalCacheService() {
    if (m_db.isOpen()) {
        m_db.close();
    }
}

bool LocalCacheService::initializeDB() {
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(dataDir);
    if (!dir.exists()) {
        dir.mkpath(".");
    }
    
    QString dbPath = dir.filePath("taskhub.db");
    
    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName(dbPath);
    
    if (!m_db.open()) {
        qWarning() << "Could not open local database:" << m_db.lastError().text();
        return false;
    }
    
    createTables();
    return true;
}

void LocalCacheService::createTables() {
    QSqlQuery query(m_db);
    query.exec("CREATE TABLE IF NOT EXISTS tasks ("
               "id TEXT PRIMARY KEY, "
               "listId TEXT, "
               "title TEXT, "
               "description TEXT, "
               "priority INTEGER, "
               "status TEXT, "
               "dueAt TEXT, "
               "startAt TEXT, "
               "repeatRule TEXT, "
               "tags TEXT, "
               "isPinned INTEGER, "
               "isCompleted INTEGER, "
               "orderIndex INTEGER DEFAULT 0, "
               "createdAt TEXT, "
               "updatedAt TEXT)");
               
    // Simple migration to add orderIndex if it doesn't exist
    query.exec("ALTER TABLE tasks ADD COLUMN orderIndex INTEGER DEFAULT 0");
}

bool LocalCacheService::saveTask(const Task& task) {
    QSqlQuery query(m_db);
    query.prepare("INSERT OR REPLACE INTO tasks (id, listId, title, description, priority, status, dueAt, startAt, repeatRule, tags, isPinned, isCompleted, orderIndex, createdAt, updatedAt) "
                  "VALUES (:id, :listId, :title, :description, :priority, :status, :dueAt, :startAt, :repeatRule, :tags, :isPinned, :isCompleted, :orderIndex, :createdAt, :updatedAt)");
    
    QVariantMap map = task.toVariantMap();
    query.bindValue(":id", map["id"]);
    query.bindValue(":listId", map["listId"]);
    query.bindValue(":title", map["title"]);
    query.bindValue(":description", map["description"]);
    query.bindValue(":priority", map["priority"]);
    query.bindValue(":status", map["status"]);
    query.bindValue(":dueAt", map["dueAt"]);
    query.bindValue(":startAt", map["startAt"]);
    query.bindValue(":repeatRule", map["repeatRule"]);
    query.bindValue(":tags", task.tags.join(",")); // Simple serialization for tags
    query.bindValue(":isPinned", map["isPinned"].toBool() ? 1 : 0);
    query.bindValue(":isCompleted", map["isCompleted"].toBool() ? 1 : 0);
    query.bindValue(":orderIndex", map["orderIndex"]);
    query.bindValue(":createdAt", map["createdAt"]);
    query.bindValue(":updatedAt", map["updatedAt"]);
    
    if (!query.exec()) {
        qWarning() << "Failed to save task:" << query.lastError().text();
        return false;
    }
    return true;
}

bool LocalCacheService::updateTask(const Task& task) {
    QSqlQuery query(m_db);
    query.prepare("UPDATE tasks SET listId = :listId, title = :title, description = :description, "
                  "priority = :priority, status = :status, dueAt = :dueAt, startAt = :startAt, "
                  "repeatRule = :repeatRule, tags = :tags, isPinned = :isPinned, "
                  "isCompleted = :isCompleted, orderIndex = :orderIndex, updatedAt = :updatedAt "
                  "WHERE id = :id");
    
    QVariantMap map = task.toVariantMap();
    query.bindValue(":listId", map["listId"]);
    query.bindValue(":title", map["title"]);
    query.bindValue(":description", map["description"]);
    query.bindValue(":priority", map["priority"]);
    query.bindValue(":status", map["status"]);
    query.bindValue(":dueAt", map["dueAt"]);
    query.bindValue(":startAt", map["startAt"]);
    query.bindValue(":repeatRule", map["repeatRule"]);
    query.bindValue(":tags", task.tags.join(","));
    query.bindValue(":isPinned", map["isPinned"].toBool() ? 1 : 0);
    query.bindValue(":isCompleted", map["isCompleted"].toBool() ? 1 : 0);
    query.bindValue(":orderIndex", map["orderIndex"]);
    query.bindValue(":updatedAt", map["updatedAt"]);
    query.bindValue(":id", map["id"]);
    
    if (!query.exec()) {
        qWarning() << "[LocalCacheService] Failed to update task:" << query.lastError().text();
        return false;
    }
    
    qDebug() << "[LocalCacheService] updateTask success! Rows affected:" << query.numRowsAffected() << "for ID:" << map["id"];
    return true;
}

bool LocalCacheService::deleteTask(const QString& taskId) {
    QSqlQuery query(m_db);
    query.prepare("DELETE FROM tasks WHERE id = :id");
    query.bindValue(":id", taskId);
    return query.exec();
}

QList<Task> LocalCacheService::getAllTasks() {
    QList<Task> tasks;
    QSqlQuery query("SELECT * FROM tasks WHERE status != 'trashed'", m_db);
    
    while (query.next()) {
        Task task;
        task.id = query.value("id").toString();
        task.listId = query.value("listId").toString();
        task.title = query.value("title").toString();
        task.description = query.value("description").toString();
        task.priority = query.value("priority").toInt();
        task.status = query.value("status").toString();
        task.dueAt = QDateTime::fromString(query.value("dueAt").toString(), Qt::ISODate);
        task.startAt = QDateTime::fromString(query.value("startAt").toString(), Qt::ISODate);
        task.repeatRule = query.value("repeatRule").toString();
        task.tags = query.value("tags").toString().split(",", Qt::SkipEmptyParts);
        task.isPinned = query.value("isPinned").toInt() == 1;
        task.isCompleted = query.value("isCompleted").toInt() == 1;
        task.orderIndex = query.value("orderIndex").toInt();
        task.createdAt = QDateTime::fromString(query.value("createdAt").toString(), Qt::ISODate);
        task.updatedAt = QDateTime::fromString(query.value("updatedAt").toString(), Qt::ISODate);
        
        tasks.append(task);
    }
    
    return tasks;
}

Task LocalCacheService::getTask(const QString& taskId) {
    QSqlQuery query(m_db);
    query.prepare("SELECT * FROM tasks WHERE id = :id");
    query.bindValue(":id", taskId);
    query.exec(); // CRITICAL FIX: The query must be executed!
    
    if (query.next()) {
        Task task;
        task.id = query.value("id").toString();
        task.listId = query.value("listId").toString();
        task.title = query.value("title").toString();
        task.description = query.value("description").toString();
        task.priority = query.value("priority").toInt();
        task.status = query.value("status").toString();
        task.dueAt = QDateTime::fromString(query.value("dueAt").toString(), Qt::ISODate);
        task.startAt = QDateTime::fromString(query.value("startAt").toString(), Qt::ISODate);
        task.repeatRule = query.value("repeatRule").toString();
        task.tags = query.value("tags").toString().split(",", Qt::SkipEmptyParts);
        task.isPinned = query.value("isPinned").toInt() == 1;
        task.isCompleted = query.value("isCompleted").toInt() == 1;
        task.orderIndex = query.value("orderIndex").toInt();
        task.createdAt = QDateTime::fromString(query.value("createdAt").toString(), Qt::ISODate);
        task.updatedAt = QDateTime::fromString(query.value("updatedAt").toString(), Qt::ISODate);
        
        qDebug() << "[LocalCacheService] getTask FETCHED ID:" << task.id;
        return task;
    }
    qDebug() << "[LocalCacheService] getTask COULD NOT FIND ID:" << taskId;
    return Task();
}

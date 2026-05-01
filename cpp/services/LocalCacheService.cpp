#include "LocalCacheService.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QSet>

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
               "updatedAt TEXT, "
               "isDirty INTEGER DEFAULT 1)");

    query.exec("CREATE TABLE IF NOT EXISTS lists ("
               "name TEXT PRIMARY KEY, "
               "color TEXT, "
               "folderName TEXT, "
               "listType TEXT, "
               "createdAt TEXT)");

    query.exec("CREATE TABLE IF NOT EXISTS tags ("
               "name TEXT PRIMARY KEY, "
               "color TEXT, "
               "parentTag TEXT, "
               "createdAt TEXT)");

    query.exec("CREATE TABLE IF NOT EXISTS folders ("
               "name TEXT PRIMARY KEY, "
               "createdAt TEXT)");
               
    // Migrations
    query.exec("ALTER TABLE tasks ADD COLUMN orderIndex INTEGER DEFAULT 0");
    query.exec("ALTER TABLE tasks ADD COLUMN isDirty INTEGER DEFAULT 1");
    query.exec("ALTER TABLE lists ADD COLUMN color TEXT");
    query.exec("ALTER TABLE lists ADD COLUMN folderName TEXT");
    query.exec("ALTER TABLE lists ADD COLUMN listType TEXT");
    query.exec("UPDATE tasks SET isDirty = 1 WHERE status = 'trashed' AND isDirty = 0");

    QSqlQuery listQuery(m_db);
    listQuery.prepare("INSERT OR IGNORE INTO lists (name, color, folderName, listType, createdAt) "
                      "VALUES (:name, :color, :folderName, :listType, :createdAt)");
    listQuery.bindValue(":name", "Inbox");
    listQuery.bindValue(":color", "");
    listQuery.bindValue(":folderName", "");
    listQuery.bindValue(":listType", "Task List");
    listQuery.bindValue(":createdAt", QDateTime::currentDateTime().toString(Qt::ISODate));
    listQuery.exec();
}

QList<Task> LocalCacheService::getDirtyTasks() {
    QList<Task> tasks;
    QSqlQuery query("SELECT * FROM tasks WHERE isDirty = 1", m_db);
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
        task.isDirty = true;
        tasks.append(task);
    }
    return tasks;
}

void LocalCacheService::clearDirtyFlag(const QString& taskId) {
    QSqlQuery query(m_db);
    query.prepare("UPDATE tasks SET isDirty = 0 WHERE id = :id");
    query.bindValue(":id", taskId);
    query.exec();
}

bool LocalCacheService::saveTask(const Task& task, bool isDirty) {
    QSqlQuery query(m_db);
    query.prepare("INSERT OR REPLACE INTO tasks (id, listId, title, description, priority, status, dueAt, startAt, repeatRule, tags, isPinned, isCompleted, orderIndex, createdAt, updatedAt, isDirty) "
                  "VALUES (:id, :listId, :title, :description, :priority, :status, :dueAt, :startAt, :repeatRule, :tags, :isPinned, :isCompleted, :orderIndex, :createdAt, :updatedAt, :isDirty)");
    
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
    query.bindValue(":isDirty", isDirty ? 1 : 0);
    
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
                  "isCompleted = :isCompleted, orderIndex = :orderIndex, updatedAt = :updatedAt, isDirty = :isDirty "
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
    query.bindValue(":isDirty", map.contains("isDirty") ? (map["isDirty"].toBool() ? 1 : 0) : 1);
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
    query.prepare("UPDATE tasks SET status = 'trashed', isDirty = 1 WHERE id = :id");
    query.bindValue(":id", taskId);
    return query.exec();
}

QList<Task> LocalCacheService::getAllTasks(const QString& searchQuery) {
    QList<Task> tasks;
    QSqlQuery query(m_db);
    
    if (searchQuery.trimmed().isEmpty()) {
        query.prepare("SELECT * FROM tasks WHERE status != 'trashed'");
    } else {
        query.prepare("SELECT * FROM tasks WHERE status != 'trashed' AND (title LIKE :search OR description LIKE :search)");
        query.bindValue(":search", "%" + searchQuery.trimmed() + "%");
    }
    
    query.exec();
    
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
        task.isDirty = query.value("isDirty").toBool();
        
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
        task.isDirty = query.value("isDirty").toBool();
        
        qDebug() << "[LocalCacheService] getTask FETCHED ID:" << task.id;
        return task;
    }
    qDebug() << "[LocalCacheService] getTask COULD NOT FIND ID:" << taskId;
    return Task();
}

QStringList LocalCacheService::getAllLists() {
    QSet<QString> names;
    names.insert("Inbox");

    QSqlQuery query("SELECT name FROM lists", m_db);
    while (query.next()) {
        QString name = query.value("name").toString().trimmed();
        if (!name.isEmpty()) {
            names.insert(name);
        }
    }

    QSqlQuery taskQuery("SELECT DISTINCT listId FROM tasks WHERE status != 'trashed'", m_db);
    while (taskQuery.next()) {
        QString name = taskQuery.value("listId").toString().trimmed();
        names.insert(name.isEmpty() ? "Inbox" : name);
    }

    QStringList result = names.values();
    result.sort(Qt::CaseInsensitive);
    result.removeAll("Inbox");
    result.prepend("Inbox");
    return result;
}

QStringList LocalCacheService::getRootLists() {
    QSet<QString> assigned;
    QSqlQuery assignedQuery("SELECT name FROM lists WHERE trim(coalesce(folderName, '')) != ''", m_db);
    while (assignedQuery.next()) {
        assigned.insert(assignedQuery.value("name").toString().trimmed());
    }

    QStringList result;
    const QStringList allLists = getAllLists();
    for (const QString& name : allLists) {
        if (name != "Inbox" && !assigned.contains(name)) {
            result.append(name);
        }
    }
    result.sort(Qt::CaseInsensitive);
    return result;
}

QStringList LocalCacheService::getListsForFolder(const QString& folderName) {
    QStringList result;
    QSqlQuery query(m_db);
    query.prepare("SELECT name FROM lists WHERE folderName = :folderName AND name != 'Inbox' ORDER BY lower(name)");
    query.bindValue(":folderName", folderName.trimmed());
    if (query.exec()) {
        while (query.next()) {
            QString name = query.value("name").toString().trimmed();
            if (!name.isEmpty()) {
                result.append(name);
            }
        }
    }
    return result;
}

bool LocalCacheService::saveList(const QString& listName, const QString& color, const QString& folderName, const QString& listType) {
    QString name = listName.trimmed();
    if (name.isEmpty()) {
        return false;
    }

    QSqlQuery query(m_db);
    query.prepare("INSERT OR REPLACE INTO lists (name, color, folderName, listType, createdAt) "
                  "VALUES (:name, :color, :folderName, :listType, :createdAt)");
    query.bindValue(":name", name);
    query.bindValue(":color", color.trimmed());
    query.bindValue(":folderName", folderName.trimmed());
    query.bindValue(":listType", listType.trimmed().isEmpty() ? QStringLiteral("Task List") : listType.trimmed());
    query.bindValue(":createdAt", QDateTime::currentDateTime().toString(Qt::ISODate));
    if (!query.exec()) {
        qWarning() << "Failed to save list:" << query.lastError().text();
        return false;
    }
    return true;
}

QStringList LocalCacheService::getAllFolders() {
    QStringList result;
    QSqlQuery query("SELECT name FROM folders ORDER BY lower(name)", m_db);
    while (query.next()) {
        QString name = query.value("name").toString().trimmed();
        if (!name.isEmpty()) {
            result.append(name);
        }
    }
    return result;
}

bool LocalCacheService::saveFolder(const QString& folderName) {
    QString name = folderName.trimmed();
    if (name.isEmpty()) {
        return false;
    }

    QSqlQuery query(m_db);
    query.prepare("INSERT OR IGNORE INTO folders (name, createdAt) VALUES (:name, :createdAt)");
    query.bindValue(":name", name);
    query.bindValue(":createdAt", QDateTime::currentDateTime().toString(Qt::ISODate));
    if (!query.exec()) {
        qWarning() << "Failed to save folder:" << query.lastError().text();
        return false;
    }
    return true;
}

QStringList LocalCacheService::getAllTags() {
    QSet<QString> names;

    QSqlQuery query("SELECT name FROM tags", m_db);
    while (query.next()) {
        QString name = query.value("name").toString().trimmed();
        if (!name.isEmpty()) {
            names.insert(name);
        }
    }

    QSqlQuery taskQuery("SELECT tags FROM tasks WHERE status != 'trashed'", m_db);
    while (taskQuery.next()) {
        const QStringList tags = taskQuery.value("tags").toString().split(",", Qt::SkipEmptyParts);
        for (const QString& rawTag : tags) {
            QString tag = rawTag.trimmed();
            if (!tag.isEmpty()) {
                names.insert(tag);
            }
        }
    }

    QStringList result = names.values();
    result.sort(Qt::CaseInsensitive);
    return result;
}

bool LocalCacheService::saveTag(const QString& tagName, const QString& color, const QString& parentTag) {
    QString name = tagName.trimmed();
    if (name.isEmpty()) {
        return false;
    }

    QSqlQuery query(m_db);
    query.prepare("INSERT OR REPLACE INTO tags (name, color, parentTag, createdAt) "
                  "VALUES (:name, :color, :parentTag, :createdAt)");
    query.bindValue(":name", name);
    query.bindValue(":color", color.trimmed());
    query.bindValue(":parentTag", parentTag.trimmed());
    query.bindValue(":createdAt", QDateTime::currentDateTime().toString(Qt::ISODate));
    if (!query.exec()) {
        qWarning() << "Failed to save tag:" << query.lastError().text();
        return false;
    }
    return true;
}

QString LocalCacheService::getTagColor(const QString& tagName) {
    QSqlQuery query(m_db);
    query.prepare("SELECT color FROM tags WHERE name = :name");
    query.bindValue(":name", tagName.trimmed());
    if (query.exec() && query.next()) {
        return query.value("color").toString();
    }
    return QString();
}

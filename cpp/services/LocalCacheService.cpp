#include "LocalCacheService.h"
#include <QDebug>
#include <QDir>
#include <QSet>
#include <QUuid>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>

LocalCacheService::LocalCacheService(QObject *parent) : QObject(parent) {
  initializeDB();
}

LocalCacheService::~LocalCacheService() {
  if (m_db.isOpen()) {
    m_db.close();
  }
}

bool LocalCacheService::initializeDB() {
  QString dataDir =
      QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
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
             "isPinned INTEGER DEFAULT 0, "
             "isArchived INTEGER DEFAULT 0, "
             "updatedAt TEXT, "
             "createdAt TEXT)");

  query.exec("CREATE TABLE IF NOT EXISTS tags ("
             "name TEXT PRIMARY KEY, "
             "color TEXT, "
             "parentTag TEXT, "
             "createdAt TEXT)");

  query.exec("CREATE TABLE IF NOT EXISTS folders ("
             "name TEXT PRIMARY KEY, "
             "isPinned INTEGER DEFAULT 0, "
             "updatedAt TEXT, "
             "createdAt TEXT)");

  // Migrations
  query.exec("ALTER TABLE tasks ADD COLUMN orderIndex INTEGER DEFAULT 0");
  query.exec("ALTER TABLE tasks ADD COLUMN isDirty INTEGER DEFAULT 1");
  query.exec("ALTER TABLE lists ADD COLUMN color TEXT");
  query.exec("ALTER TABLE lists ADD COLUMN folderName TEXT");
  query.exec("ALTER TABLE lists ADD COLUMN listType TEXT");
  query.exec("ALTER TABLE lists ADD COLUMN isPinned INTEGER DEFAULT 0");
  query.exec("ALTER TABLE lists ADD COLUMN isArchived INTEGER DEFAULT 0");
  query.exec("ALTER TABLE lists ADD COLUMN updatedAt TEXT");
  query.exec("ALTER TABLE folders ADD COLUMN isPinned INTEGER DEFAULT 0");
  query.exec("ALTER TABLE folders ADD COLUMN updatedAt TEXT");
  query.exec(
      "UPDATE tasks SET isDirty = 1 WHERE status = 'trashed' AND isDirty = 0");

  QSqlQuery listQuery(m_db);
  listQuery.prepare(
      "INSERT OR IGNORE INTO lists (name, color, folderName, listType, "
      "isPinned, isArchived, updatedAt, createdAt) "
      "VALUES (:name, :color, :folderName, :listType, :isPinned, :isArchived, "
      ":updatedAt, :createdAt)");
  listQuery.bindValue(":name", "Inbox");
  listQuery.bindValue(":color", "");
  listQuery.bindValue(":folderName", "");
  listQuery.bindValue(":listType", "Task List");
  listQuery.bindValue(":isPinned", 0);
  listQuery.bindValue(":isArchived", 0);
  listQuery.bindValue(":updatedAt",
                      QDateTime::currentDateTime().toString(Qt::ISODate));
  listQuery.bindValue(":createdAt",
                      QDateTime::currentDateTime().toString(Qt::ISODate));
  listQuery.exec();
}

namespace {
QString uniqueListName(const QStringList &existing, const QString &base) {
  QString name = base.trimmed();
  if (name.isEmpty())
    return QString();

  auto exists = [&existing](const QString &candidate) {
    for (const QString &item : existing) {
      if (item.compare(candidate, Qt::CaseInsensitive) == 0)
        return true;
    }
    return false;
  };

  if (!exists(name))
    return name;

  int suffix = 2;
  QString candidate = name + QStringLiteral(" Copy");
  while (exists(candidate)) {
    candidate = name + QStringLiteral(" Copy ") + QString::number(suffix++);
  }
  return candidate;
}
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
    task.dueAt =
        QDateTime::fromString(query.value("dueAt").toString(), Qt::ISODate);
    task.startAt =
        QDateTime::fromString(query.value("startAt").toString(), Qt::ISODate);
    task.repeatRule = query.value("repeatRule").toString();
    task.tags = query.value("tags").toString().split(",", Qt::SkipEmptyParts);
    task.isPinned = query.value("isPinned").toInt() == 1;
    task.isCompleted = query.value("isCompleted").toInt() == 1;
    task.orderIndex = query.value("orderIndex").toInt();
    task.createdAt =
        QDateTime::fromString(query.value("createdAt").toString(), Qt::ISODate);
    task.updatedAt =
        QDateTime::fromString(query.value("updatedAt").toString(), Qt::ISODate);
    task.isDirty = true;
    tasks.append(task);
  }
  return tasks;
}

void LocalCacheService::clearDirtyFlag(const QString &taskId) {
  QSqlQuery query(m_db);
  query.prepare("UPDATE tasks SET isDirty = 0 WHERE id = :id");
  query.bindValue(":id", taskId);
  query.exec();
}

bool LocalCacheService::saveTask(const Task &task, bool isDirty) {
  QSqlQuery query(m_db);
  query.prepare("INSERT OR REPLACE INTO tasks (id, listId, title, description, "
                "priority, status, dueAt, startAt, repeatRule, tags, isPinned, "
                "isCompleted, orderIndex, createdAt, updatedAt, isDirty) "
                "VALUES (:id, :listId, :title, :description, :priority, "
                ":status, :dueAt, :startAt, :repeatRule, :tags, :isPinned, "
                ":isCompleted, :orderIndex, :createdAt, :updatedAt, :isDirty)");

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
  query.bindValue(":tags",
                  task.tags.join(",")); // Simple serialization for tags
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
  if (!task.listId.trimmed().isEmpty()) {
    QSqlQuery touchQuery(m_db);
    touchQuery.prepare("UPDATE lists SET updatedAt = :updatedAt WHERE name = :name");
    touchQuery.bindValue(":updatedAt",
                         QDateTime::currentDateTime().toString(Qt::ISODate));
    touchQuery.bindValue(":name", task.listId.trimmed());
    touchQuery.exec();
  }
  return true;
}

bool LocalCacheService::updateTask(const Task &task) {
  QSqlQuery query(m_db);
  query.prepare("UPDATE tasks SET listId = :listId, title = :title, "
                "description = :description, "
                "priority = :priority, status = :status, dueAt = :dueAt, "
                "startAt = :startAt, "
                "repeatRule = :repeatRule, tags = :tags, isPinned = :isPinned, "
                "isCompleted = :isCompleted, orderIndex = :orderIndex, "
                "updatedAt = :updatedAt, isDirty = :isDirty "
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
  query.bindValue(":isDirty", map.contains("isDirty")
                                  ? (map["isDirty"].toBool() ? 1 : 0)
                                  : 1);
  query.bindValue(":id", map["id"]);

  if (!query.exec()) {
    qWarning() << "[LocalCacheService] Failed to update task:"
               << query.lastError().text();
    return false;
  }

  if (!task.listId.trimmed().isEmpty()) {
    QSqlQuery touchQuery(m_db);
    touchQuery.prepare("UPDATE lists SET updatedAt = :updatedAt WHERE name = :name");
    touchQuery.bindValue(":updatedAt",
                         QDateTime::currentDateTime().toString(Qt::ISODate));
    touchQuery.bindValue(":name", task.listId.trimmed());
    touchQuery.exec();
  }

  qDebug() << "[LocalCacheService] updateTask success! Rows affected:"
           << query.numRowsAffected() << "for ID:" << map["id"];
  return true;
}

bool LocalCacheService::deleteTask(const QString &taskId) {
  QSqlQuery query(m_db);
  query.prepare(
      "UPDATE tasks SET status = 'trashed', isDirty = 1 WHERE id = :id");
  query.bindValue(":id", taskId);
  return query.exec();
}

QList<Task> LocalCacheService::getAllTasks(const QString &searchQuery) {
  QList<Task> tasks;
  QSqlQuery query(m_db);

  if (searchQuery.trimmed().isEmpty()) {
    query.prepare("SELECT * FROM tasks WHERE status != 'trashed'");
  } else {
    query.prepare("SELECT * FROM tasks WHERE status != 'trashed' AND (title "
                  "LIKE :search OR description LIKE :search)");
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
    task.dueAt =
        QDateTime::fromString(query.value("dueAt").toString(), Qt::ISODate);
    task.startAt =
        QDateTime::fromString(query.value("startAt").toString(), Qt::ISODate);
    task.repeatRule = query.value("repeatRule").toString();
    task.tags = query.value("tags").toString().split(",", Qt::SkipEmptyParts);
    task.isPinned = query.value("isPinned").toInt() == 1;
    task.isCompleted = query.value("isCompleted").toInt() == 1;
    task.orderIndex = query.value("orderIndex").toInt();
    task.createdAt =
        QDateTime::fromString(query.value("createdAt").toString(), Qt::ISODate);
    task.updatedAt =
        QDateTime::fromString(query.value("updatedAt").toString(), Qt::ISODate);
    task.isDirty = query.value("isDirty").toBool();

    tasks.append(task);
  }

  return tasks;
}

Task LocalCacheService::getTask(const QString &taskId) {
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
    task.dueAt =
        QDateTime::fromString(query.value("dueAt").toString(), Qt::ISODate);
    task.startAt =
        QDateTime::fromString(query.value("startAt").toString(), Qt::ISODate);
    task.repeatRule = query.value("repeatRule").toString();
    task.tags = query.value("tags").toString().split(",", Qt::SkipEmptyParts);
    task.isPinned = query.value("isPinned").toInt() == 1;
    task.isCompleted = query.value("isCompleted").toInt() == 1;
    task.orderIndex = query.value("orderIndex").toInt();
    task.createdAt =
        QDateTime::fromString(query.value("createdAt").toString(), Qt::ISODate);
    task.updatedAt =
        QDateTime::fromString(query.value("updatedAt").toString(), Qt::ISODate);
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

  QSqlQuery seedQuery("SELECT name FROM lists", m_db);
  while (seedQuery.next()) {
    QString name = seedQuery.value("name").toString().trimmed();
    if (!name.isEmpty()) {
      names.insert(name);
    }
  }

  QSqlQuery ensureQuery(m_db);
  ensureQuery.prepare(
      "INSERT OR IGNORE INTO lists (name, color, folderName, listType, isPinned, "
      "isArchived, updatedAt, createdAt) "
      "VALUES (:name, '', '', 'Task List', 0, 0, :updatedAt, :createdAt)");

  QSqlQuery taskQuery(
      "SELECT DISTINCT listId FROM tasks WHERE status != 'trashed'", m_db);
  while (taskQuery.next()) {
    QString name = taskQuery.value("listId").toString().trimmed();
    if (name.isEmpty())
      name = "Inbox";
    names.insert(name);
    ensureQuery.bindValue(":name", name);
    ensureQuery.bindValue(":updatedAt",
                          QDateTime::currentDateTime().toString(Qt::ISODate));
    ensureQuery.bindValue(":createdAt",
                          QDateTime::currentDateTime().toString(Qt::ISODate));
    ensureQuery.exec();
  }

    QSqlQuery listQuery(
      "SELECT name FROM lists "
      "ORDER BY isArchived ASC, isPinned DESC, coalesce(updatedAt, createdAt) DESC",
      m_db);
  QStringList ordered;
  while (listQuery.next()) {
    QString name = listQuery.value("name").toString().trimmed();
    if (!name.isEmpty() && names.contains(name)) {
      ordered.append(name);
    }
  }

  ordered.removeAll("Inbox");
  ordered.prepend("Inbox");
  return ordered;
}

QStringList LocalCacheService::getRootLists() {
  QStringList result;
  QSqlQuery query(m_db);
  query.prepare(
      "SELECT name FROM lists WHERE name != 'Inbox' AND "
      "trim(coalesce(folderName, '')) = '' "
      "ORDER BY isArchived ASC, isPinned DESC, coalesce(updatedAt, createdAt) DESC");
  if (query.exec()) {
    while (query.next()) {
      QString name = query.value("name").toString().trimmed();
      if (!name.isEmpty())
        result.append(name);
    }
  }
  return result;
}

QStringList LocalCacheService::getListsForFolder(const QString &folderName) {
  QStringList result;
  QSqlQuery query(m_db);
  query.prepare("SELECT name FROM lists WHERE folderName = :folderName AND "
                "name != 'Inbox' "
                "ORDER BY isArchived ASC, isPinned DESC, coalesce(updatedAt, createdAt) DESC");
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

QString LocalCacheService::getListType(const QString &listName) {
  QSqlQuery query(m_db);
  query.prepare("SELECT listType FROM lists WHERE name = :name");
  query.bindValue(":name", listName.trimmed());
  if (query.exec() && query.next()) {
    QString type = query.value("listType").toString();
    return type.isEmpty() ? QStringLiteral("Task List") : type;
  }
  return QStringLiteral("Task List");
}

bool LocalCacheService::getListPinned(const QString &listName) {
  QSqlQuery query(m_db);
  query.prepare("SELECT isPinned FROM lists WHERE name = :name");
  query.bindValue(":name", listName.trimmed());
  if (query.exec() && query.next()) {
    return query.value("isPinned").toInt() == 1;
  }
  return false;
}

bool LocalCacheService::getListArchived(const QString &listName) {
  QSqlQuery query(m_db);
  query.prepare("SELECT isArchived FROM lists WHERE name = :name");
  query.bindValue(":name", listName.trimmed());
  if (query.exec() && query.next()) {
    return query.value("isArchived").toInt() == 1;
  }
  return false;
}

bool LocalCacheService::saveList(const QString &listName, const QString &color,
                                 const QString &folderName,
                                 const QString &listType) {
  QString name = listName.trimmed();
  if (name.isEmpty()) {
    return false;
  }

  bool pinned = getListPinned(name);
  bool archived = getListArchived(name);

  QSqlQuery query(m_db);
  query.prepare("INSERT OR REPLACE INTO lists (name, color, folderName, "
                "listType, isPinned, isArchived, updatedAt, createdAt) "
                "VALUES (:name, :color, :folderName, :listType, :isPinned, "
                ":isArchived, :updatedAt, :createdAt)");
  query.bindValue(":name", name);
  query.bindValue(":color", color.trimmed());
  query.bindValue(":folderName", folderName.trimmed());
  query.bindValue(":listType", listType.trimmed().isEmpty()
                                   ? QStringLiteral("Task List")
                                   : listType.trimmed());
  query.bindValue(":isPinned", pinned ? 1 : 0);
  query.bindValue(":isArchived", archived ? 1 : 0);
  query.bindValue(":updatedAt",
                  QDateTime::currentDateTime().toString(Qt::ISODate));
  query.bindValue(":createdAt",
                  QDateTime::currentDateTime().toString(Qt::ISODate));
  if (!query.exec()) {
    qWarning() << "Failed to save list:" << query.lastError().text();
    return false;
  }
  return true;
}

bool LocalCacheService::renameList(const QString &oldName,
                                   const QString &newName) {
  QString from = oldName.trimmed();
  QString to = newName.trimmed();
  if (from.isEmpty() || to.isEmpty() || from == to)
    return false;

  if (!m_db.transaction())
    return false;

  QSqlQuery listQuery(m_db);
  listQuery.prepare("UPDATE lists SET name = :newName, updatedAt = :updatedAt "
                    "WHERE name = :oldName");
  listQuery.bindValue(":newName", to);
  listQuery.bindValue(":updatedAt",
                      QDateTime::currentDateTime().toString(Qt::ISODate));
  listQuery.bindValue(":oldName", from);
  if (!listQuery.exec()) {
    m_db.rollback();
    qWarning() << "Failed to rename list:" << listQuery.lastError().text();
    return false;
  }

  QSqlQuery taskQuery(m_db);
  taskQuery.prepare("UPDATE tasks SET listId = :newName WHERE listId = :oldName");
  taskQuery.bindValue(":newName", to);
  taskQuery.bindValue(":oldName", from);
  if (!taskQuery.exec()) {
    m_db.rollback();
    qWarning() << "Failed to update tasks for list rename:" << taskQuery.lastError().text();
    return false;
  }

  return m_db.commit();
}

bool LocalCacheService::deleteList(const QString &listName) {
  QString name = listName.trimmed();
  if (name.isEmpty() || name == QLatin1String("Inbox"))
    return false;

  if (!m_db.transaction())
    return false;

  QSqlQuery taskQuery(m_db);
  taskQuery.prepare("UPDATE tasks SET listId = 'Inbox' WHERE listId = :name");
  taskQuery.bindValue(":name", name);
  if (!taskQuery.exec()) {
    m_db.rollback();
    qWarning() << "Failed to reassign tasks when deleting list:" << taskQuery.lastError().text();
    return false;
  }

  QSqlQuery listQuery(m_db);
  listQuery.prepare("DELETE FROM lists WHERE name = :name");
  listQuery.bindValue(":name", name);
  if (!listQuery.exec()) {
    m_db.rollback();
    qWarning() << "Failed to delete list:" << listQuery.lastError().text();
    return false;
  }

  return m_db.commit();
}

bool LocalCacheService::moveTasksToList(const QString &fromList,
                                        const QString &toList) {
  QString from = fromList.trimmed();
  QString to = toList.trimmed().isEmpty() ? QStringLiteral("Inbox") : toList.trimmed();
  if (from.isEmpty() || from == to)
    return false;

  QSqlQuery query(m_db);
  query.prepare("UPDATE tasks SET listId = :toList WHERE listId = :fromList");
  query.bindValue(":toList", to);
  query.bindValue(":fromList", from);
  if (!query.exec()) {
    qWarning() << "Failed to move tasks between lists:" << query.lastError().text();
    return false;
  }
  QSqlQuery touchQuery(m_db);
  touchQuery.prepare("UPDATE lists SET updatedAt = :updatedAt WHERE name = :name");
  touchQuery.bindValue(":updatedAt",
                       QDateTime::currentDateTime().toString(Qt::ISODate));
  touchQuery.bindValue(":name", from);
  touchQuery.exec();
  touchQuery.bindValue(":name", to);
  touchQuery.exec();
  return true;
}

bool LocalCacheService::setListPinned(const QString &listName, bool pinned) {
  QString name = listName.trimmed();
  if (name.isEmpty())
    return false;

  QSqlQuery query(m_db);
  query.prepare("UPDATE lists SET isPinned = :pinned, updatedAt = :updatedAt "
                "WHERE name = :name");
  query.bindValue(":pinned", pinned ? 1 : 0);
  query.bindValue(":updatedAt",
                  QDateTime::currentDateTime().toString(Qt::ISODate));
  query.bindValue(":name", name);
  if (!query.exec()) {
    qWarning() << "Failed to pin list:" << query.lastError().text();
    return false;
  }
  return true;
}

bool LocalCacheService::setListArchived(const QString &listName, bool archived) {
  QString name = listName.trimmed();
  if (name.isEmpty())
    return false;

  QSqlQuery query(m_db);
  query.prepare("UPDATE lists SET isArchived = :archived, updatedAt = :updatedAt "
                "WHERE name = :name");
  query.bindValue(":archived", archived ? 1 : 0);
  query.bindValue(":updatedAt",
                  QDateTime::currentDateTime().toString(Qt::ISODate));
  query.bindValue(":name", name);
  if (!query.exec()) {
    qWarning() << "Failed to archive list:" << query.lastError().text();
    return false;
  }
  return true;
}

bool LocalCacheService::updateListFolder(const QString &listName,
                                         const QString &folderName) {
  QString name = listName.trimmed();
  if (name.isEmpty())
    return false;

  QSqlQuery query(m_db);
  query.prepare("UPDATE lists SET folderName = :folderName, updatedAt = :updatedAt "
                "WHERE name = :name");
  query.bindValue(":folderName", folderName.trimmed());
  query.bindValue(":updatedAt",
                  QDateTime::currentDateTime().toString(Qt::ISODate));
  query.bindValue(":name", name);
  if (!query.exec()) {
    qWarning() << "Failed to update list folder:" << query.lastError().text();
    return false;
  }
  if (!folderName.trimmed().isEmpty()) {
    QSqlQuery touchQuery(m_db);
    touchQuery.prepare("UPDATE folders SET updatedAt = :updatedAt WHERE name = :name");
    touchQuery.bindValue(":updatedAt",
                         QDateTime::currentDateTime().toString(Qt::ISODate));
    touchQuery.bindValue(":name", folderName.trimmed());
    touchQuery.exec();
  }
  return true;
}

bool LocalCacheService::duplicateListWithTasks(const QString &listName,
                                               const QString &newListName) {
  QString from = listName.trimmed();
  QString to = newListName.trimmed();
  if (from.isEmpty() || to.isEmpty())
    return false;

  QSqlQuery existsQuery(m_db);
  existsQuery.prepare("SELECT 1 FROM lists WHERE name = :name");
  existsQuery.bindValue(":name", to);
  bool listExists = existsQuery.exec() && existsQuery.next();

  if (!listExists) {
    QSqlQuery listQuery(m_db);
    listQuery.prepare("SELECT color, folderName, listType FROM lists WHERE name = :name");
    listQuery.bindValue(":name", from);
    if (!listQuery.exec() || !listQuery.next())
      return false;

    QString color = listQuery.value("color").toString();
    QString folderName = listQuery.value("folderName").toString();
    QString listType = listQuery.value("listType").toString();

    if (!saveList(to, color, folderName, listType))
      return false;
  }

  QSqlQuery taskQuery(m_db);
  taskQuery.prepare("SELECT * FROM tasks WHERE listId = :listId AND status != 'trashed'");
  taskQuery.bindValue(":listId", from);
  if (!taskQuery.exec())
    return false;

  while (taskQuery.next()) {
    Task task;
    task.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    task.listId = to;
    task.title = taskQuery.value("title").toString();
    task.description = taskQuery.value("description").toString();
    task.priority = taskQuery.value("priority").toInt();
    task.status = taskQuery.value("status").toString();
    task.dueAt = QDateTime::fromString(taskQuery.value("dueAt").toString(), Qt::ISODate);
    task.startAt = QDateTime::fromString(taskQuery.value("startAt").toString(), Qt::ISODate);
    task.repeatRule = taskQuery.value("repeatRule").toString();
    task.tags = taskQuery.value("tags").toString().split(",", Qt::SkipEmptyParts);
    task.isPinned = taskQuery.value("isPinned").toInt() == 1;
    task.isCompleted = taskQuery.value("isCompleted").toInt() == 1;
    task.orderIndex = taskQuery.value("orderIndex").toInt();
    task.createdAt = QDateTime::currentDateTime();
    task.updatedAt = QDateTime::currentDateTime();
    task.isDirty = true;
    saveTask(task, true);
  }

  return true;
}

QStringList LocalCacheService::getAllFolders() {
  QStringList result;
  QSqlQuery query("SELECT name FROM folders ORDER BY isPinned DESC, coalesce(updatedAt, createdAt) DESC", m_db);
  while (query.next()) {
    QString name = query.value("name").toString().trimmed();
    if (!name.isEmpty()) {
      result.append(name);
    }
  }
  return result;
}

bool LocalCacheService::getFolderPinned(const QString &folderName) {
  QSqlQuery query(m_db);
  query.prepare("SELECT isPinned FROM folders WHERE name = :name");
  query.bindValue(":name", folderName.trimmed());
  if (query.exec() && query.next()) {
    return query.value("isPinned").toInt() == 1;
  }
  return false;
}

bool LocalCacheService::saveFolder(const QString &folderName) {
  QString name = folderName.trimmed();
  if (name.isEmpty()) {
    return false;
  }

  QSqlQuery query(m_db);
  query.prepare("INSERT OR IGNORE INTO folders (name, isPinned, updatedAt, createdAt) VALUES "
                "(:name, :isPinned, :updatedAt, :createdAt)");
  query.bindValue(":name", name);
  query.bindValue(":isPinned", 0);
  query.bindValue(":updatedAt",
                  QDateTime::currentDateTime().toString(Qt::ISODate));
  query.bindValue(":createdAt",
                  QDateTime::currentDateTime().toString(Qt::ISODate));
  if (!query.exec()) {
    qWarning() << "Failed to save folder:" << query.lastError().text();
    return false;
  }
  return true;
}

bool LocalCacheService::renameFolder(const QString &oldName,
                                     const QString &newName) {
  QString from = oldName.trimmed();
  QString to = newName.trimmed();
  if (from.isEmpty() || to.isEmpty() || from == to)
    return false;

  if (!m_db.transaction())
    return false;

  QSqlQuery folderQuery(m_db);
  folderQuery.prepare("UPDATE folders SET name = :newName, updatedAt = :updatedAt "
                      "WHERE name = :oldName");
  folderQuery.bindValue(":newName", to);
  folderQuery.bindValue(":updatedAt",
                        QDateTime::currentDateTime().toString(Qt::ISODate));
  folderQuery.bindValue(":oldName", from);
  if (!folderQuery.exec()) {
    m_db.rollback();
    qWarning() << "Failed to rename folder:" << folderQuery.lastError().text();
    return false;
  }

  QSqlQuery listQuery(m_db);
  listQuery.prepare("UPDATE lists SET folderName = :newName WHERE folderName = :oldName");
  listQuery.bindValue(":newName", to);
  listQuery.bindValue(":oldName", from);
  if (!listQuery.exec()) {
    m_db.rollback();
    qWarning() << "Failed to update lists for folder rename:" << listQuery.lastError().text();
    return false;
  }

  return m_db.commit();
}

bool LocalCacheService::deleteFolder(const QString &folderName) {
  QString name = folderName.trimmed();
  if (name.isEmpty())
    return false;

  if (!m_db.transaction())
    return false;

  QSqlQuery listQuery(m_db);
  listQuery.prepare("UPDATE lists SET folderName = '' WHERE folderName = :name");
  listQuery.bindValue(":name", name);
  if (!listQuery.exec()) {
    m_db.rollback();
    qWarning() << "Failed to ungroup lists when deleting folder:" << listQuery.lastError().text();
    return false;
  }

  QSqlQuery folderQuery(m_db);
  folderQuery.prepare("DELETE FROM folders WHERE name = :name");
  folderQuery.bindValue(":name", name);
  if (!folderQuery.exec()) {
    m_db.rollback();
    qWarning() << "Failed to delete folder:" << folderQuery.lastError().text();
    return false;
  }

  return m_db.commit();
}

bool LocalCacheService::setFolderPinned(const QString &folderName, bool pinned) {
  QString name = folderName.trimmed();
  if (name.isEmpty())
    return false;

  QSqlQuery query(m_db);
  query.prepare("UPDATE folders SET isPinned = :pinned, updatedAt = :updatedAt "
                "WHERE name = :name");
  query.bindValue(":pinned", pinned ? 1 : 0);
  query.bindValue(":updatedAt",
                  QDateTime::currentDateTime().toString(Qt::ISODate));
  query.bindValue(":name", name);
  if (!query.exec()) {
    qWarning() << "Failed to pin folder:" << query.lastError().text();
    return false;
  }
  return true;
}

bool LocalCacheService::ungroupFolder(const QString &folderName) {
  QString name = folderName.trimmed();
  if (name.isEmpty())
    return false;

  QSqlQuery query(m_db);
  query.prepare("UPDATE lists SET folderName = '' WHERE folderName = :name");
  query.bindValue(":name", name);
  if (!query.exec()) {
    qWarning() << "Failed to ungroup folder:" << query.lastError().text();
    return false;
  }
  return true;
}

bool LocalCacheService::duplicateFolder(const QString &folderName,
                                        const QString &newFolderName) {
  QString from = folderName.trimmed();
  QString to = newFolderName.trimmed();
  if (from.isEmpty() || to.isEmpty())
    return false;

  if (!saveFolder(to))
    return false;

  QSqlQuery listQuery(m_db);
  listQuery.prepare("SELECT name, color, listType FROM lists WHERE folderName = :folderName");
  listQuery.bindValue(":folderName", from);
  if (!listQuery.exec())
    return false;

  QStringList existingLists = getAllLists();

  while (listQuery.next()) {
    QString oldListName = listQuery.value("name").toString().trimmed();
    QString color = listQuery.value("color").toString();
    QString listType = listQuery.value("listType").toString();
    QString newListName = uniqueListName(existingLists, oldListName + QStringLiteral(" Copy"));
    if (newListName.isEmpty())
      continue;

    existingLists.append(newListName);
    if (!saveList(newListName, color, to, listType))
      continue;

    duplicateListWithTasks(oldListName, newListName);
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
    const QStringList tags =
        taskQuery.value("tags").toString().split(",", Qt::SkipEmptyParts);
    for (const QString &rawTag : tags) {
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

bool LocalCacheService::saveTag(const QString &tagName, const QString &color,
                                const QString &parentTag) {
  QString name = tagName.trimmed();
  if (name.isEmpty()) {
    return false;
  }

  QSqlQuery query(m_db);
  query.prepare(
      "INSERT OR REPLACE INTO tags (name, color, parentTag, createdAt) "
      "VALUES (:name, :color, :parentTag, :createdAt)");
  query.bindValue(":name", name);
  query.bindValue(":color", color.trimmed());
  query.bindValue(":parentTag", parentTag.trimmed());
  query.bindValue(":createdAt",
                  QDateTime::currentDateTime().toString(Qt::ISODate));
  if (!query.exec()) {
    qWarning() << "Failed to save tag:" << query.lastError().text();
    return false;
  }
  return true;
}

QString LocalCacheService::getTagColor(const QString &tagName) {
  QSqlQuery query(m_db);
  query.prepare("SELECT color FROM tags WHERE name = :name");
  query.bindValue(":name", tagName.trimmed());
  if (query.exec() && query.next()) {
    return query.value("color").toString();
  }
  return QString();
}

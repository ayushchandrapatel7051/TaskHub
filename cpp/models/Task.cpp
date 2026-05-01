#include "Task.h"
#include <QUuid>

Task::Task() 
    : id(QUuid::createUuid().toString(QUuid::WithoutBraces)),
      priority(0),
      status("todo"),
      isPinned(false),
      isCompleted(false),
      orderIndex(0)
{
    createdAt = QDateTime::currentDateTime();
    updatedAt = createdAt;
}

Task Task::fromVariantMap(const QVariantMap& map) {
    Task task;
    task.id = map.value("id").toString();
    task.listId = map.value("listId").toString();
    task.title = map.value("title").toString();
    task.description = map.value("description").toString();
    task.priority = map.value("priority").toInt();
    task.status = map.value("status").toString();
    task.dueAt = QDateTime::fromString(map.value("dueAt").toString(), Qt::ISODate);
    task.startAt = QDateTime::fromString(map.value("startAt").toString(), Qt::ISODate);
    task.repeatRule = map.value("repeatRule").toString();
    task.tags = map.value("tags").toStringList();
    task.isPinned = map.value("isPinned").toBool();
    task.isCompleted = map.value("isCompleted").toBool();
    task.orderIndex = map.value("orderIndex").toInt();
    task.createdAt = QDateTime::fromString(map.value("createdAt").toString(), Qt::ISODate);
    task.updatedAt = QDateTime::fromString(map.value("updatedAt").toString(), Qt::ISODate);
    return task;
}

QVariantMap Task::toVariantMap() const {
    QVariantMap map;
    map["id"] = id;
    map["listId"] = listId;
    map["title"] = title;
    map["description"] = description;
    map["priority"] = priority;
    map["status"] = status;
    map["dueAt"] = dueAt.isValid() ? dueAt.toString(Qt::ISODate) : "";
    map["startAt"] = startAt.isValid() ? startAt.toString(Qt::ISODate) : "";
    map["repeatRule"] = repeatRule;
    map["tags"] = tags;
    map["isPinned"] = isPinned;
    map["isCompleted"] = isCompleted;
    map["orderIndex"] = orderIndex;
    map["createdAt"] = createdAt.isValid() ? createdAt.toString(Qt::ISODate) : "";
    map["updatedAt"] = updatedAt.isValid() ? updatedAt.toString(Qt::ISODate) : "";
    return map;
}

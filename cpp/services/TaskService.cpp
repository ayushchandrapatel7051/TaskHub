#include "TaskService.h"
#include <QDateTime>

TaskService::TaskService(LocalCacheService* cacheService, QObject *parent)
    : QObject(parent), m_cacheService(cacheService) {
}

QList<Task> TaskService::getTasks(const QString& searchQuery) {
    return m_cacheService->getAllTasks(searchQuery);
}

bool TaskService::createTask(const QString& title, const QString& description, int priority, const QString& dueAt, const QStringList& tags, const QString& listName) {
    Task task;
    task.title = title;
    task.description = description;
    task.priority = priority;
    task.tags = tags;
    task.listId = listName.trimmed().isEmpty() ? "Inbox" : listName.trimmed();
    if (!dueAt.isEmpty()) {
        task.dueAt = QDateTime::fromString(dueAt, Qt::ISODate);
        if (!task.dueAt.isValid()) {
            // Try date-only format yyyy-MM-dd
            task.dueAt = QDateTime(QDate::fromString(dueAt, "yyyy-MM-dd"), QTime(0, 0));
        }
    }

    if (m_cacheService->saveTask(task)) {
        emit tasksChanged();
        return true;
    }
    return false;
}

QStringList TaskService::getLists() {
    return m_cacheService->getAllLists();
}

QStringList TaskService::getRootLists() {
    return m_cacheService->getRootLists();
}

QStringList TaskService::getListsForFolder(const QString& folderName) {
    return m_cacheService->getListsForFolder(folderName);
}

bool TaskService::createList(const QString& listName, const QString& color, const QString& folderName, const QString& listType) {
    if (m_cacheService->saveList(listName, color, folderName, listType)) {
        emit tasksChanged();
        return true;
    }
    return false;
}

QStringList TaskService::getFolders() {
    return m_cacheService->getAllFolders();
}

bool TaskService::createFolder(const QString& folderName) {
    if (m_cacheService->saveFolder(folderName)) {
        emit tasksChanged();
        return true;
    }
    return false;
}

QStringList TaskService::getTags() {
    return m_cacheService->getAllTags();
}

bool TaskService::createTag(const QString& tagName, const QString& color, const QString& parentTag) {
    if (m_cacheService->saveTag(tagName, color, parentTag)) {
        emit tasksChanged();
        return true;
    }
    return false;
}

QString TaskService::getTagColor(const QString& tagName) {
    return m_cacheService->getTagColor(tagName);
}

bool TaskService::updateTaskStatus(const QString& taskId, const QString& status) {
    Task task = m_cacheService->getTask(taskId);
    if (task.id.isEmpty()) return false;
    
    task.status = status;
    task.updatedAt = QDateTime::currentDateTime();
    task.isDirty = true;
    if (status == "completed") {
        task.isCompleted = true;
    } else {
        task.isCompleted = false;
    }
    
    if (m_cacheService->updateTask(task)) {
        emit tasksChanged();
        return true;
    }
    return false;
}

bool TaskService::deleteTask(const QString& taskId) {
    Task task = m_cacheService->getTask(taskId);
    if (task.id.isEmpty()) return false;
    
    task.status = "trashed";
    task.updatedAt = QDateTime::currentDateTime();
    task.isDirty = true;
    
    if (m_cacheService->updateTask(task)) {
        emit tasksChanged();
        return true;
    }
    return false;
}

bool TaskService::updateTask(const Task& task) {
    Task updatedTask = task;
    updatedTask.updatedAt = QDateTime::currentDateTime();
    updatedTask.isDirty = true;
    
    if (m_cacheService->updateTask(updatedTask)) {
        emit tasksChanged();
        return true;
    }
    return false;
}

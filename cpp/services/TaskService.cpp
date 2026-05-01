#include "TaskService.h"
#include <QDateTime>

TaskService::TaskService(LocalCacheService* cacheService, QObject *parent)
    : QObject(parent), m_cacheService(cacheService) {
}

QList<Task> TaskService::getTasks(const QString& searchQuery) {
    return m_cacheService->getAllTasks(searchQuery);
}

bool TaskService::createTask(const QString& title, const QString& description, int priority, const QString& dueAt, const QStringList& tags) {
    Task task;
    task.title = title;
    task.description = description;
    task.priority = priority;
    task.tags = tags;
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

bool TaskService::updateTaskStatus(const QString& taskId, const QString& status) {
    Task task = m_cacheService->getTask(taskId);
    if (task.id.isEmpty()) return false;
    
    task.status = status;
    task.updatedAt = QDateTime::currentDateTime();
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
    
    if (m_cacheService->updateTask(task)) {
        emit tasksChanged();
        return true;
    }
    return false;
}

bool TaskService::updateTask(const Task& task) {
    Task updatedTask = task;
    updatedTask.updatedAt = QDateTime::currentDateTime();
    
    if (m_cacheService->updateTask(updatedTask)) {
        emit tasksChanged();
        return true;
    }
    return false;
}

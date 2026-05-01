#include "TaskService.h"

TaskService::TaskService(LocalCacheService* cacheService, QObject *parent)
    : QObject(parent), m_cacheService(cacheService) {
}

QList<Task> TaskService::getTasks(const QString& searchQuery) {
    return m_cacheService->getAllTasks(searchQuery);
}

bool TaskService::createTask(const QString& title, const QString& description) {
    Task task;
    task.title = title;
    task.description = description;
    
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

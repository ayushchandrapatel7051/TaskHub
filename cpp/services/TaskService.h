#ifndef TASK_SERVICE_H
#define TASK_SERVICE_H

#include <QObject>
#include <QList>
#include "LocalCacheService.h"
#include "../models/Task.h"

class TaskService : public QObject {
    Q_OBJECT
public:
    explicit TaskService(LocalCacheService* cacheService, QObject *parent = nullptr);

    Q_INVOKABLE QList<Task> getTasks(const QString& searchQuery = "");
    Q_INVOKABLE bool createTask(const QString& title, const QString& description);
    Q_INVOKABLE bool updateTaskStatus(const QString& taskId, const QString& status);
    Q_INVOKABLE bool deleteTask(const QString& taskId);
    bool updateTask(const Task& task);

signals:
    void tasksChanged();

private:
    LocalCacheService* m_cacheService;
};

#endif // TASK_SERVICE_H

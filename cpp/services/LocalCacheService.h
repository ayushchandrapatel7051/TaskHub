#ifndef LOCAL_CACHE_SERVICE_H
#define LOCAL_CACHE_SERVICE_H

#include <QObject>
#include <QSqlDatabase>
#include <QVariantMap>
#include <QList>
#include "../models/Task.h"

class LocalCacheService : public QObject {
    Q_OBJECT
public:
    explicit LocalCacheService(QObject *parent = nullptr);
    ~LocalCacheService();

    bool initializeDB();

    // Task Operations
    bool saveTask(const Task& task);
    bool updateTask(const Task& task);
    bool deleteTask(const QString& taskId);
    QList<Task> getAllTasks();
    Task getTask(const QString& taskId);

private:
    QSqlDatabase m_db;
    void createTables();
};

#endif // LOCAL_CACHE_SERVICE_H

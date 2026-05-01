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
    bool saveTask(const Task& task, bool isDirty = true);
    bool updateTask(const Task& task);
    bool deleteTask(const QString& taskId);
    QList<Task> getAllTasks(const QString& searchQuery = "");
    QList<Task> getDirtyTasks();
    Task getTask(const QString& taskId);
    void clearDirtyFlag(const QString& taskId);
    QStringList getAllLists();
    QStringList getRootLists();
    QStringList getListsForFolder(const QString& folderName);
    bool saveList(const QString& listName, const QString& color = QString(), const QString& folderName = QString(), const QString& listType = QStringLiteral("Task List"));
    QStringList getAllFolders();
    bool saveFolder(const QString& folderName);
    QStringList getAllTags();
    bool saveTag(const QString& tagName, const QString& color = QString(), const QString& parentTag = QString());
    QString getTagColor(const QString& tagName);

private:
    QSqlDatabase m_db;
    void createTables();
};

#endif // LOCAL_CACHE_SERVICE_H

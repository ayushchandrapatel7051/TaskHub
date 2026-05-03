#ifndef TASK_SERVICE_H
#define TASK_SERVICE_H

#include "../models/Task.h"
#include "LocalCacheService.h"
#include <QList>
#include <QObject>

class TaskService : public QObject {
  Q_OBJECT
public:
  explicit TaskService(LocalCacheService *cacheService,
                       QObject *parent = nullptr);

  Q_INVOKABLE QList<Task> getTasks(const QString &searchQuery = "");
  Q_INVOKABLE bool createTask(const QString &title, const QString &description,
                              int priority = 0, const QString &dueAt = "",
                              const QStringList &tags = QStringList(),
                              const QString &listName = "Inbox");
  Q_INVOKABLE QStringList getLists();
  Q_INVOKABLE QStringList getRootLists();
  Q_INVOKABLE QStringList getListsForFolder(const QString &folderName);
  Q_INVOKABLE QString getListType(const QString &listName);
  Q_INVOKABLE bool createList(const QString &listName,
                              const QString &color = "",
                              const QString &folderName = "",
                              const QString &listType = "Task List");
  Q_INVOKABLE QStringList getFolders();
  Q_INVOKABLE bool createFolder(const QString &folderName);
  Q_INVOKABLE QStringList getTags();
  Q_INVOKABLE bool createTag(const QString &tagName, const QString &color = "",
                             const QString &parentTag = "");
  Q_INVOKABLE QString getTagColor(const QString &tagName);
  Q_INVOKABLE bool updateTaskStatus(const QString &taskId,
                                    const QString &status);
  Q_INVOKABLE bool deleteTask(const QString &taskId);
  bool updateTask(const Task &task);

signals:
  void tasksChanged();
  void listsChanged();

private:
  LocalCacheService *m_cacheService;
};

#endif // TASK_SERVICE_H

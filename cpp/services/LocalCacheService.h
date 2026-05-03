#ifndef LOCAL_CACHE_SERVICE_H
#define LOCAL_CACHE_SERVICE_H

#include "../models/Task.h"
#include <QList>
#include <QObject>
#include <QSqlDatabase>
#include <QVariantMap>

class LocalCacheService : public QObject {
  Q_OBJECT
public:
  explicit LocalCacheService(QObject *parent = nullptr);
  ~LocalCacheService();

  bool initializeDB();

  // Task Operations
  bool saveTask(const Task &task, bool isDirty = true);
  bool updateTask(const Task &task);
  bool deleteTask(const QString &taskId);
  QList<Task> getAllTasks(const QString &searchQuery = "");
  QList<Task> getDirtyTasks();
  Task getTask(const QString &taskId);
  void clearDirtyFlag(const QString &taskId);
  QStringList getAllLists();
  QStringList getRootLists();
  QStringList getListsForFolder(const QString &folderName);
  QString getListType(const QString &listName);
  bool getListPinned(const QString &listName);
  bool getListArchived(const QString &listName);
  bool saveList(const QString &listName, const QString &color = QString(),
                const QString &folderName = QString(),
                const QString &listType = QStringLiteral("Task List"));
  bool renameList(const QString &oldName, const QString &newName);
  bool deleteList(const QString &listName);
  bool moveTasksToList(const QString &fromList, const QString &toList);
  bool setListPinned(const QString &listName, bool pinned);
  bool setListArchived(const QString &listName, bool archived);
  bool updateListFolder(const QString &listName, const QString &folderName);
  bool duplicateListWithTasks(const QString &listName,
                              const QString &newListName);
  QStringList getAllFolders();
  bool getFolderPinned(const QString &folderName);
  bool saveFolder(const QString &folderName);
  bool renameFolder(const QString &oldName, const QString &newName);
  bool deleteFolder(const QString &folderName);
  bool setFolderPinned(const QString &folderName, bool pinned);
  bool ungroupFolder(const QString &folderName);
  bool duplicateFolder(const QString &folderName, const QString &newFolderName);
  QStringList getAllTags();
  bool saveTag(const QString &tagName, const QString &color = QString(),
               const QString &parentTag = QString());
  QString getTagColor(const QString &tagName);

private:
  QSqlDatabase m_db;
  void createTables();
};

#endif // LOCAL_CACHE_SERVICE_H

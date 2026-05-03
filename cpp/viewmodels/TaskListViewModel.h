#ifndef TASK_LIST_VIEW_MODEL_H
#define TASK_LIST_VIEW_MODEL_H

#include "../services/TaskService.h"
#include <QAbstractListModel>
#include <QSet>

class TaskListViewModel : public QAbstractListModel {
  Q_OBJECT
public:
  enum TaskRoles {
    IdRole = Qt::UserRole + 1,
    TitleRole,
    DescriptionRole,
    PriorityRole,
    StatusRole,
    IsCompletedRole,
    DueAtRole,
    IsPinnedRole,
    SectionRole,
    TagsRole,
    ListRole
  };

  explicit TaskListViewModel(TaskService *taskService,
                             QObject *parent = nullptr);

  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index,
                int role = Qt::DisplayRole) const override;
  QHash<int, QByteArray> roleNames() const override;

  Q_INVOKABLE void loadTasks();
  Q_INVOKABLE void addTask(const QString &title, const QString &description,
                           int priority = 0, const QString &dueAt = "",
                           const QStringList &tags = QStringList(),
                           const QString &listName = "Inbox");
  Q_INVOKABLE void toggleTaskCompletion(int row);
  Q_INVOKABLE void renameTask(int row, const QString &newTitle);
  Q_INVOKABLE void softDeleteTask(int row);
  Q_INVOKABLE void moveTask(int fromRow, int toRow);

  // Group collapsing logic
  Q_INVOKABLE void toggleSection(const QString &section);
  Q_INVOKABLE bool isSectionCollapsed(const QString &section) const;

  // Filtering logic
  Q_INVOKABLE void setSearchQuery(const QString &query);
  Q_INVOKABLE void setFilterTag(const QString &tag);
  Q_INVOKABLE void setFilterList(const QString &listName);
  Q_INVOKABLE void setFilterPriority(int priority);
  Q_INVOKABLE void setFilterDate(const QString &date);
  Q_INVOKABLE void clearFilters();
  Q_INVOKABLE QStringList getAllTags() const;
  Q_INVOKABLE QStringList getAllLists() const;
  Q_INVOKABLE QStringList getVisibleLists() const;
  Q_INVOKABLE QStringList getRootLists() const;
  Q_INVOKABLE QStringList getListsForFolder(const QString &folderName) const;
  Q_INVOKABLE QStringList getAllFolders() const;
  Q_INVOKABLE void createList(const QString &listName,
                              const QString &color = "",
                              const QString &folderName = "",
                              const QString &listType = "Task List");
  Q_INVOKABLE void createFolder(const QString &folderName);
  Q_INVOKABLE void createTag(const QString &tagName, const QString &color = "",
                             const QString &parentTag = "");
  Q_INVOKABLE QString getSavedTagColor(const QString &tagName) const;
  Q_INVOKABLE QString getListType(const QString &listName) const;

  // Count methods for sidebar
  Q_INVOKABLE int getTodayCount() const;
  Q_INVOKABLE int getNext7DaysCount() const;
  Q_INVOKABLE int getNoDateCount() const;
  Q_INVOKABLE int getAllTaskCount() const;
  Q_INVOKABLE int getCompletedTaskCount() const;
  Q_INVOKABLE int getTagTaskCount(const QString &tag) const;
  Q_INVOKABLE int getListTaskCount(const QString &listName) const;

  Q_PROPERTY(QString activeFilterTag READ activeFilterTag NOTIFY filterChanged)
  Q_PROPERTY(
      QString activeFilterList READ activeFilterList NOTIFY filterChanged)
  Q_PROPERTY(QString activeFilterDate READ activeFilterDate NOTIFY filterChanged)
  Q_PROPERTY(QString searchQuery READ searchQuery NOTIFY filterChanged)
  Q_PROPERTY(bool selectedTaskPinned READ selectedTaskPinned NOTIFY
                 selectedTaskChanged)

  // Task Detail Selection
  Q_PROPERTY(
      int selectedTaskIndex READ selectedTaskIndex NOTIFY selectedTaskChanged)
  Q_PROPERTY(QString selectedTaskTitle READ selectedTaskTitle NOTIFY
                 selectedTaskChanged)
  Q_PROPERTY(QString selectedTaskDescription READ selectedTaskDescription NOTIFY
                 selectedTaskChanged)
  Q_PROPERTY(int selectedTaskPriority READ selectedTaskPriority NOTIFY
                 selectedTaskChanged)
  Q_PROPERTY(QString selectedTaskDueAt READ selectedTaskDueAt NOTIFY
                 selectedTaskChanged)
  Q_PROPERTY(QStringList selectedTaskTags READ selectedTaskTags NOTIFY
                 selectedTaskChanged)
  Q_PROPERTY(
      QString selectedTaskList READ selectedTaskList NOTIFY selectedTaskChanged)

  Q_INVOKABLE void selectTask(int index);
  Q_INVOKABLE void updateSelectedTaskDescription(const QString &description);
  Q_INVOKABLE void updateSelectedTaskPriority(int priority);
  Q_INVOKABLE void updateSelectedTaskTags(const QString &tagsString);
  Q_INVOKABLE void updateSelectedTaskList(const QString &listName);
  Q_INVOKABLE void updateSelectedTaskDueAt(const QString &dateStr);
  Q_INVOKABLE void updateSelectedTaskPinned(bool pinned);

  QString activeFilterTag() const { return m_filterTag; }
  QString activeFilterList() const { return m_filterList; }
  QString activeFilterDate() const { return m_filterDate; }
  QString searchQuery() const { return m_searchQuery; }

  int selectedTaskIndex() const { return m_selectedTaskIndex; }
  QString selectedTaskTitle() const;
  QString selectedTaskDescription() const;
  int selectedTaskPriority() const;
  QString selectedTaskDueAt() const;
  QStringList selectedTaskTags() const;
  QString selectedTaskList() const;
  bool selectedTaskPinned() const;

signals:
  void sectionToggled(); // Emitted when a section is collapsed/expanded
  void filterChanged();  // Emitted when a filter changes
  void selectedTaskChanged();
  void tasksModified(); // Emitted when tasks are added/deleted/modified

private slots:
  void onTasksChanged();

private:
  static QString getTaskSection(const Task &task);
  static int getTaskSectionOrder(const Task &task);

  TaskService *m_taskService;
  QList<Task> m_tasks;
  QSet<QString> m_collapsedSections;

  // Filter state
  QString m_searchQuery;
  QString m_filterTag;
  QString m_filterList;
  int m_filterPriority = -1;
  QString m_filterDate = "Inbox"; // Default to showing all incomplete tasks

  int m_selectedTaskIndex = -1;
};

#endif // TASK_LIST_VIEW_MODEL_H

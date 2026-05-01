#ifndef TASK_LIST_VIEW_MODEL_H
#define TASK_LIST_VIEW_MODEL_H

#include <QAbstractListModel>
#include <QSet>
#include "../services/TaskService.h"

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
        TagsRole
    };

    explicit TaskListViewModel(TaskService* taskService, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void loadTasks();
    Q_INVOKABLE void addTask(const QString& title, const QString& description, int priority = 0, const QString& dueAt = "", const QStringList& tags = QStringList());
    Q_INVOKABLE void toggleTaskCompletion(int row);
    Q_INVOKABLE void renameTask(int row, const QString& newTitle);
    Q_INVOKABLE void softDeleteTask(int row);
    Q_INVOKABLE void moveTask(int fromRow, int toRow);
    
    // Group collapsing logic
    Q_INVOKABLE void toggleSection(const QString& section);
    Q_INVOKABLE bool isSectionCollapsed(const QString& section) const;

    // Filtering logic
    Q_INVOKABLE void setSearchQuery(const QString& query);
    Q_INVOKABLE void setFilterTag(const QString& tag);
    Q_INVOKABLE void setFilterPriority(int priority);
    Q_INVOKABLE void setFilterDate(const QString& date);
    Q_INVOKABLE void clearFilters();
    Q_INVOKABLE QStringList getAllTags() const;
    
    // Count methods for sidebar
    Q_INVOKABLE int getTodayCount() const;
    Q_INVOKABLE int getNext7DaysCount() const;
    Q_INVOKABLE int getNoDateCount() const;
    Q_INVOKABLE int getAllTaskCount() const;
    
    Q_PROPERTY(QString activeFilterTag READ activeFilterTag NOTIFY filterChanged)
    Q_PROPERTY(QString activeFilterDate READ activeFilterDate NOTIFY filterChanged)
    Q_PROPERTY(QString searchQuery READ searchQuery NOTIFY filterChanged)
    
    // Task Detail Selection
    Q_PROPERTY(int selectedTaskIndex READ selectedTaskIndex NOTIFY selectedTaskChanged)
    Q_PROPERTY(QString selectedTaskTitle READ selectedTaskTitle NOTIFY selectedTaskChanged)
    Q_PROPERTY(QString selectedTaskDescription READ selectedTaskDescription NOTIFY selectedTaskChanged)
    Q_PROPERTY(int selectedTaskPriority READ selectedTaskPriority NOTIFY selectedTaskChanged)
    Q_PROPERTY(QString selectedTaskDueAt READ selectedTaskDueAt NOTIFY selectedTaskChanged)
    Q_PROPERTY(QStringList selectedTaskTags READ selectedTaskTags NOTIFY selectedTaskChanged)
    
    Q_INVOKABLE void selectTask(int index);
    Q_INVOKABLE void updateSelectedTaskDescription(const QString& description);
    Q_INVOKABLE void updateSelectedTaskPriority(int priority);
    Q_INVOKABLE void updateSelectedTaskTags(const QString& tagsString);
    Q_INVOKABLE void updateSelectedTaskDueAt(const QString& dateStr);

    QString activeFilterTag() const { return m_filterTag; }
    QString activeFilterDate() const { return m_filterDate; }
    QString searchQuery() const { return m_searchQuery; }
    
    int selectedTaskIndex() const { return m_selectedTaskIndex; }
    QString selectedTaskTitle() const;
    QString selectedTaskDescription() const;
    int selectedTaskPriority() const;
    QString selectedTaskDueAt() const;
    QStringList selectedTaskTags() const;

signals:
    void sectionToggled(); // Emitted when a section is collapsed/expanded
    void filterChanged(); // Emitted when a filter changes
    void selectedTaskChanged();
    void tasksModified(); // Emitted when tasks are added/deleted/modified

private slots:
    void onTasksChanged();

private:
    static QString getTaskSection(const Task& task);
    static int getTaskSectionOrder(const Task& task);

    TaskService* m_taskService;
    QList<Task> m_tasks;
    QSet<QString> m_collapsedSections;
    
    // Filter state
    QString m_searchQuery;
    QString m_filterTag;
    int m_filterPriority = -1;
    QString m_filterDate = "Inbox"; // Default to showing all incomplete tasks
    
    int m_selectedTaskIndex = -1;
};

#endif // TASK_LIST_VIEW_MODEL_H

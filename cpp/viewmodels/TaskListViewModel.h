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
        SectionRole
    };

    explicit TaskListViewModel(TaskService* taskService, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void loadTasks();
    Q_INVOKABLE void addTask(const QString& title, const QString& description);
    Q_INVOKABLE void toggleTaskCompletion(int row);
    Q_INVOKABLE void renameTask(int row, const QString& newTitle);
    Q_INVOKABLE void softDeleteTask(int row);
    Q_INVOKABLE void moveTask(int fromRow, int toRow);
    
    // Group collapsing logic
    Q_INVOKABLE void toggleSection(const QString& section);
    Q_INVOKABLE bool isSectionCollapsed(const QString& section) const;

signals:
    void sectionToggled(); // Emitted when a section is collapsed/expanded

private slots:
    void onTasksChanged();

private:
    static QString getTaskSection(const Task& task);
    static int getTaskSectionOrder(const Task& task);

    TaskService* m_taskService;
    QList<Task> m_tasks;
    QSet<QString> m_collapsedSections;
};

#endif // TASK_LIST_VIEW_MODEL_H

#include "TaskListViewModel.h"
#include <QDate>
#include <algorithm>

TaskListViewModel::TaskListViewModel(TaskService* taskService, QObject *parent)
    : QAbstractListModel(parent), m_taskService(taskService) {
    connect(m_taskService, &TaskService::tasksChanged, this, &TaskListViewModel::onTasksChanged);
    loadTasks();
}

int TaskListViewModel::rowCount(const QModelIndex &parent) const {
    if (parent.isValid()) return 0;
    return m_tasks.count();
}

QVariant TaskListViewModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= m_tasks.count())
        return QVariant();

    const Task &task = m_tasks[index.row()];

    switch (role) {
        case IdRole: return task.id;
        case TitleRole: return task.title;
        case DescriptionRole: return task.description;
        case PriorityRole: return task.priority;
        case StatusRole: return task.status;
        case IsCompletedRole: return task.isCompleted;
        case DueAtRole: return task.dueAt.isValid() ? task.dueAt.toString(Qt::ISODate) : QVariant();
        case IsPinnedRole: return task.isPinned;
        case SectionRole: return getTaskSection(task);
        default: return QVariant();
    }
}

QHash<int, QByteArray> TaskListViewModel::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[TitleRole] = "title";
    roles[DescriptionRole] = "description";
    roles[PriorityRole] = "priority";
    roles[StatusRole] = "status";
    roles[IsCompletedRole] = "isCompleted";
    roles[DueAtRole] = "dueAt";
    roles[IsPinnedRole] = "isPinned";
    roles[SectionRole] = "section";
    return roles;
}

QString TaskListViewModel::getTaskSection(const Task& task) {
    if (task.isCompleted) return "Completed";
    if (task.isPinned) return "Pinned";
    if (!task.dueAt.isValid()) return "No Date";
    
    QDate today = QDate::currentDate();
    QDate dueDate = task.dueAt.date();
    
    if (dueDate < today) return "Overdue";
    if (dueDate == today) return "Today";
    return "Upcoming";
}

int TaskListViewModel::getTaskSectionOrder(const Task& task) {
    if (task.isCompleted) return 6;
    if (task.isPinned) return 1;
    if (!task.dueAt.isValid()) return 5;
    
    QDate today = QDate::currentDate();
    QDate dueDate = task.dueAt.date();
    
    if (dueDate < today) return 2; // Overdue
    if (dueDate == today) return 3; // Today
    return 4; // Upcoming
}

void TaskListViewModel::loadTasks() {
    beginResetModel();
    m_tasks = m_taskService->getTasks();
    
    // Sort logic for sections
    std::sort(m_tasks.begin(), m_tasks.end(), [](const Task& a, const Task& b) {
        int orderA = getTaskSectionOrder(a);
        int orderB = getTaskSectionOrder(b);
        if (orderA != orderB) {
            return orderA < orderB;
        }
        
        // Priority (Higher is 3, Low is 1)
        if (a.priority != b.priority) {
            return a.priority > b.priority;
        }
        
        // Due Date
        if (a.dueAt.isValid() && b.dueAt.isValid()) {
            return a.dueAt < b.dueAt;
        } else if (a.dueAt.isValid()) {
            return true;
        } else if (b.dueAt.isValid()) {
            return false;
        }
        
        return a.createdAt < b.createdAt;
    });
    
    endResetModel();
}

void TaskListViewModel::addTask(const QString& title, const QString& description) {
    m_taskService->createTask(title, description);
}

void TaskListViewModel::toggleTaskCompletion(int row) {
    if (row < 0 || row >= m_tasks.count()) return;
    
    Task task = m_tasks[row];
    QString newStatus = task.isCompleted ? "todo" : "completed";
    m_taskService->updateTaskStatus(task.id, newStatus);
}

void TaskListViewModel::renameTask(int row, const QString& newTitle) {
    if (row < 0 || row >= m_tasks.count()) return;
    
    Task task = m_tasks[row];
    if (task.title != newTitle) {
        task.title = newTitle;
        m_taskService->updateTask(task);
    }
}

void TaskListViewModel::softDeleteTask(int row) {
    if (row < 0 || row >= m_tasks.count()) return;
    m_taskService->deleteTask(m_tasks[row].id);
}

void TaskListViewModel::moveTask(int fromRow, int toRow) {
    if (fromRow < 0 || fromRow >= m_tasks.count() || toRow < 0 || toRow >= m_tasks.count() || fromRow == toRow) return;
    
    // We update the orderIndex to shift them.
    // However, since m_tasks is sorted by groups, moving across groups might break sorting locally
    // unless we also change the group properties. For "local only", we'll just swap orderIndex for now.
    Task& fromTask = m_tasks[fromRow];
    Task& toTask = m_tasks[toRow];
    
    int temp = fromTask.orderIndex;
    fromTask.orderIndex = toTask.orderIndex;
    toTask.orderIndex = temp;
    
    m_taskService->updateTask(fromTask);
    m_taskService->updateTask(toTask);
}

void TaskListViewModel::toggleSection(const QString& section) {
    if (m_collapsedSections.contains(section)) {
        m_collapsedSections.remove(section);
    } else {
        m_collapsedSections.insert(section);
    }
    emit sectionToggled();
}

bool TaskListViewModel::isSectionCollapsed(const QString& section) const {
    return m_collapsedSections.contains(section);
}

void TaskListViewModel::onTasksChanged() {
    loadTasks();
}

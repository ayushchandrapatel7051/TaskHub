#include "TaskListViewModel.h"
#include <QDate>
#include <algorithm>

namespace {
QString normalizedListName(const QString& listName) {
    QString name = listName.trimmed();
    return name.isEmpty() ? QStringLiteral("Inbox") : name;
}
}

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
        case TagsRole: return task.tags;
        case ListRole: return normalizedListName(task.listId);
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
    roles[TagsRole] = "tags";
    roles[ListRole] = "listName";
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
    QString selectedId;
    if (m_selectedTaskIndex >= 0 && m_selectedTaskIndex < m_tasks.size()) {
        selectedId = m_tasks[m_selectedTaskIndex].id;
    }

    beginResetModel();
    QList<Task> allTasks = m_taskService->getTasks(m_searchQuery);
    m_tasks.clear();
    
    QDate today = QDate::currentDate();
    
    // Apply filters
    for (const Task& task : allTasks) {
        if (m_filterDate == "Completed") {
            if (!task.isCompleted) continue;
        }

        // Tag Filter
        if (!m_filterTag.isEmpty() && !task.tags.contains(m_filterTag, Qt::CaseInsensitive)) {
            continue;
        }

        if (!m_filterList.isEmpty() && normalizedListName(task.listId).compare(m_filterList, Qt::CaseInsensitive) != 0) {
            continue;
        }
        
        // Priority Filter
        if (m_filterPriority != -1 && task.priority != m_filterPriority) {
            continue;
        }
        
        // Date Filter (Inbox=All incomplete, Today=Today, Next 7 Days=<=7 days)
        if (!m_filterDate.isEmpty() && m_filterDate != "Inbox" && m_filterDate != "All" && m_filterDate != "Completed" && m_filterDate != "Calendar") {
            if (m_filterDate == "Today") {
                if (!task.dueAt.isValid() || task.dueAt.date() != today) continue;
            } else if (m_filterDate == "Next 7 Days") {
                if (!task.dueAt.isValid() || task.dueAt.date() < today || task.dueAt.date() > today.addDays(7)) continue;
            } else if (m_filterDate == "No Date") {
                if (task.dueAt.isValid()) continue;
            }
            // Calendar could be handled differently if needed, skipping for now
        }
        
        m_tasks.append(task);
    }
    
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
    
    m_selectedTaskIndex = -1;
    if (!selectedId.isEmpty()) {
        for (int i = 0; i < m_tasks.size(); ++i) {
            if (m_tasks[i].id == selectedId) {
                m_selectedTaskIndex = i;
                break;
            }
        }
    }
    emit selectedTaskChanged();
    
    endResetModel();
}

void TaskListViewModel::addTask(const QString& title, const QString& description, int priority, const QString& dueAt, const QStringList& tags, const QString& listName) {
    QString targetList = listName.trimmed().isEmpty() ? (m_filterList.isEmpty() ? QStringLiteral("Inbox") : m_filterList) : listName;
    m_taskService->createTask(title, description, priority, dueAt, tags, targetList);
}

void TaskListViewModel::toggleTaskCompletion(int row) {
    qDebug() << "[TaskListViewModel] toggleTaskCompletion called for row:" << row;
    if (row < 0 || row >= m_tasks.count()) {
        qDebug() << "[TaskListViewModel] Invalid row! Count is:" << m_tasks.count();
        return;
    }
    
    Task task = m_tasks[row];
    qDebug() << "[TaskListViewModel] Task found:" << task.title << "ID:" << task.id;
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
    qDebug() << "[TaskListViewModel] softDeleteTask called for row:" << row;
    if (row < 0 || row >= m_tasks.count()) {
        qDebug() << "[TaskListViewModel] Invalid row for delete! Count is:" << m_tasks.count();
        return;
    }
    qDebug() << "[TaskListViewModel] Deleting task:" << m_tasks[row].title << "ID:" << m_tasks[row].id;
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
    emit tasksModified(); // Signal for sidebar and other UI elements
}

void TaskListViewModel::setSearchQuery(const QString& query) {
    if (m_searchQuery != query) {
        m_searchQuery = query;
        emit filterChanged();
        loadTasks();
    }
}

void TaskListViewModel::setFilterTag(const QString& tag) {
    if (m_filterTag != tag) {
        m_filterTag = tag;
        m_filterList = "";
        m_filterDate = "All";
        emit filterChanged();
        loadTasks();
    }
}

void TaskListViewModel::setFilterList(const QString& listName) {
    QString normalized = normalizedListName(listName);
    if (m_filterList != normalized) {
        m_filterList = normalized;
        m_filterTag = "";
        m_filterDate = "All";
        emit filterChanged();
        loadTasks();
    }
}

void TaskListViewModel::setFilterPriority(int priority) {
    if (m_filterPriority != priority) {
        m_filterPriority = priority;
        emit filterChanged();
        loadTasks();
    }
}

void TaskListViewModel::setFilterDate(const QString& date) {
    if (m_filterDate != date) {
        m_filterDate = date;
        m_filterTag = "";
        m_filterList = "";
        emit filterChanged();
        loadTasks();
    }
}

void TaskListViewModel::clearFilters() {
    m_searchQuery = "";
    m_filterTag = "";
    m_filterList = "";
    m_filterPriority = -1;
    m_filterDate = "Inbox";
    emit filterChanged();
    loadTasks();
}

QStringList TaskListViewModel::getAllTags() const {
    return m_taskService->getTags();
}

QStringList TaskListViewModel::getAllLists() const {
    return m_taskService->getLists();
}

QStringList TaskListViewModel::getVisibleLists() const {
    QStringList lists = m_taskService->getLists();
    lists.removeAll(QStringLiteral("Inbox"));
    return lists;
}

QStringList TaskListViewModel::getRootLists() const {
    return m_taskService->getRootLists();
}

QStringList TaskListViewModel::getListsForFolder(const QString& folderName) const {
    return m_taskService->getListsForFolder(folderName);
}

QStringList TaskListViewModel::getAllFolders() const {
    return m_taskService->getFolders();
}

void TaskListViewModel::createList(const QString& listName, const QString& color, const QString& folderName, const QString& listType) {
    if (m_taskService->createList(listName, color, folderName, listType)) {
        emit filterChanged();
        emit tasksModified();
    }
}

void TaskListViewModel::createFolder(const QString& folderName) {
    if (m_taskService->createFolder(folderName)) {
        emit filterChanged();
        emit tasksModified();
    }
}

void TaskListViewModel::createTag(const QString& tagName, const QString& color, const QString& parentTag) {
    if (m_taskService->createTag(tagName, color, parentTag)) {
        emit filterChanged();
        emit tasksModified();
    }
}

QString TaskListViewModel::getSavedTagColor(const QString& tagName) const {
    return m_taskService->getTagColor(tagName);
}

// --- Task Detail Selection ---

void TaskListViewModel::selectTask(int index) {
    if (index >= 0 && index < m_tasks.size()) {
        m_selectedTaskIndex = index;
        emit selectedTaskChanged();
    }
}

QString TaskListViewModel::selectedTaskTitle() const {
    if (m_selectedTaskIndex >= 0 && m_selectedTaskIndex < m_tasks.size())
        return m_tasks[m_selectedTaskIndex].title;
    return "";
}

QString TaskListViewModel::selectedTaskDescription() const {
    if (m_selectedTaskIndex >= 0 && m_selectedTaskIndex < m_tasks.size())
        return m_tasks[m_selectedTaskIndex].description;
    return "";
}

int TaskListViewModel::selectedTaskPriority() const {
    if (m_selectedTaskIndex >= 0 && m_selectedTaskIndex < m_tasks.size())
        return m_tasks[m_selectedTaskIndex].priority;
    return 0;
}

QString TaskListViewModel::selectedTaskDueAt() const {
    if (m_selectedTaskIndex >= 0 && m_selectedTaskIndex < m_tasks.size()) {
        const QDateTime& dt = m_tasks[m_selectedTaskIndex].dueAt;
        if (dt.isValid()) return dt.toString(Qt::ISODate).left(10);
    }
    return "";
}

QStringList TaskListViewModel::selectedTaskTags() const {
    if (m_selectedTaskIndex >= 0 && m_selectedTaskIndex < m_tasks.size())
        return m_tasks[m_selectedTaskIndex].tags;
    return QStringList();
}

QString TaskListViewModel::selectedTaskList() const {
    if (m_selectedTaskIndex >= 0 && m_selectedTaskIndex < m_tasks.size())
        return normalizedListName(m_tasks[m_selectedTaskIndex].listId);
    return "Inbox";
}

void TaskListViewModel::updateSelectedTaskDescription(const QString& description) {
    if (m_selectedTaskIndex >= 0 && m_selectedTaskIndex < m_tasks.size()) {
        Task& task = m_tasks[m_selectedTaskIndex];
        task.description = description;
        m_taskService->updateTask(task);
        emit selectedTaskChanged();
    }
}

void TaskListViewModel::updateSelectedTaskPriority(int priority) {
    if (m_selectedTaskIndex >= 0 && m_selectedTaskIndex < m_tasks.size()) {
        Task& task = m_tasks[m_selectedTaskIndex];
        task.priority = priority;
        m_taskService->updateTask(task);
        emit selectedTaskChanged();
        emit dataChanged(index(m_selectedTaskIndex), index(m_selectedTaskIndex));
    }
}

void TaskListViewModel::updateSelectedTaskTags(const QString& tagsString) {
    if (m_selectedTaskIndex >= 0 && m_selectedTaskIndex < m_tasks.size()) {
        Task& task = m_tasks[m_selectedTaskIndex];
        task.tags = tagsString.split(",", Qt::SkipEmptyParts);
        for(QString& tag : task.tags) tag = tag.trimmed();
        m_taskService->updateTask(task);
        emit selectedTaskChanged();
        emit dataChanged(index(m_selectedTaskIndex), index(m_selectedTaskIndex));
    }
}

void TaskListViewModel::updateSelectedTaskList(const QString& listName) {
    if (m_selectedTaskIndex >= 0 && m_selectedTaskIndex < m_tasks.size()) {
        Task task = m_tasks[m_selectedTaskIndex];
        task.listId = normalizedListName(listName);
        m_taskService->createList(task.listId);
        m_taskService->updateTask(task);
        emit selectedTaskChanged();
        emit dataChanged(index(m_selectedTaskIndex), index(m_selectedTaskIndex));
    }
}

void TaskListViewModel::updateSelectedTaskDueAt(const QString& dateStr) {
    if (m_selectedTaskIndex >= 0 && m_selectedTaskIndex < m_tasks.size()) {
        Task& task = m_tasks[m_selectedTaskIndex];
        if (dateStr.isEmpty()) {
            task.dueAt = QDateTime();
        } else {
            task.dueAt = QDateTime::fromString(dateStr, Qt::ISODate);
        }
        m_taskService->updateTask(task);
        emit selectedTaskChanged();
        emit dataChanged(index(m_selectedTaskIndex), index(m_selectedTaskIndex));
    }
}

// Count methods for sidebar - count from ALL tasks regardless of current filter
int TaskListViewModel::getTodayCount() const {
    QDate today = QDate::currentDate();
    QList<Task> allTasks = m_taskService->getTasks();
    int count = 0;
    for (const Task& task : allTasks) {
        if (!task.isCompleted && task.status != "trashed" && task.dueAt.isValid()) {
            if (task.dueAt.date() == today) {
                count++;
            }
        }
    }
    return count;
}

int TaskListViewModel::getNext7DaysCount() const {
    QDate today = QDate::currentDate();
    QList<Task> allTasks = m_taskService->getTasks();
    int count = 0;
    for (const Task& task : allTasks) {
        if (!task.isCompleted && task.status != "trashed" && task.dueAt.isValid()) {
            QDate dueDate = task.dueAt.date();
            if (dueDate > today && dueDate <= today.addDays(7)) {
                count++;
            }
        }
    }
    return count;
}

int TaskListViewModel::getNoDateCount() const {
    QList<Task> allTasks = m_taskService->getTasks();
    int count = 0;
    for (const Task& task : allTasks) {
        if (!task.isCompleted && task.status != "trashed" && !task.dueAt.isValid()) {
            count++;
        }
    }
    return count;
}

int TaskListViewModel::getAllTaskCount() const {
    QList<Task> allTasks = m_taskService->getTasks();
    int count = 0;
    for (const Task& task : allTasks) {
        if (!task.isCompleted && task.status != "trashed") {
            count++;
        }
    }
    return count;
}

int TaskListViewModel::getCompletedTaskCount() const {
    QList<Task> allTasks = m_taskService->getTasks();
    int count = 0;
    for (const Task& task : allTasks) {
        if (task.isCompleted && task.status != "trashed") {
            count++;
        }
    }
    return count;
}

int TaskListViewModel::getTagTaskCount(const QString& tag) const {
    QList<Task> allTasks = m_taskService->getTasks();
    int count = 0;
    for (const Task& task : allTasks) {
        if (!task.isCompleted && task.status != "trashed" && task.tags.contains(tag, Qt::CaseInsensitive)) {
            count++;
        }
    }
    return count;
}

int TaskListViewModel::getListTaskCount(const QString& listName) const {
    QString normalized = normalizedListName(listName);
    QList<Task> allTasks = m_taskService->getTasks();
    int count = 0;
    for (const Task& task : allTasks) {
        if (!task.isCompleted && task.status != "trashed" && normalizedListName(task.listId).compare(normalized, Qt::CaseInsensitive) == 0) {
            count++;
        }
    }
    return count;
}

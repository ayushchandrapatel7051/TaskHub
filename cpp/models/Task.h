#ifndef TASK_H
#define TASK_H

#include <QString>
#include <QDateTime>
#include <QStringList>

class Task {
public:
    Task();
    
    QString id;
    QString listId;
    QString title;
    QString description;
    int priority; // 0=Low, 1=Medium, 2=High
    QString status; // "todo", "in_progress", "completed", "trashed"
    QDateTime dueAt;
    QDateTime startAt;
    QString repeatRule;
    QStringList tags;
    bool isPinned;
    bool isCompleted;
    int orderIndex; // For drag & drop reordering
    QDateTime createdAt;
    QDateTime updatedAt;
    
    // Serialization for Local SQLite and Firebase
    static Task fromVariantMap(const QVariantMap& map);
    QVariantMap toVariantMap() const;
};

#endif // TASK_H

#include "SyncService.h"
#include <QDebug>

SyncService::SyncService(LocalCacheService* cacheService, FirestoreService* firestoreService, QObject *parent)
    : QObject(parent), m_cacheService(cacheService), m_firestoreService(firestoreService) {
    
    // Setup interval sync every 5 minutes
    m_syncTimer.setInterval(5 * 60 * 1000);
    connect(&m_syncTimer, &QTimer::timeout, this, &SyncService::performSync);
    
    connect(m_firestoreService, &FirestoreService::syncCompleted, this, &SyncService::onSyncCompleted);
    connect(m_firestoreService, &FirestoreService::remoteTasksFetched, this, &SyncService::onRemoteTasksFetched);
}

void SyncService::startSync() {
    m_syncTimer.start();
    performSync(); // initial sync
}

void SyncService::stopSync() {
    m_syncTimer.stop();
}

void SyncService::performSync() {
    qDebug() << "SyncEngine: Performing sync...";
    
    // Step 1: Fetch remote changes
    m_firestoreService->fetchRemoteTasks();
    
    // Step 2: Push local unsynced changes
    QList<Task> dirtyTasks = m_cacheService->getDirtyTasks();
    if (!dirtyTasks.isEmpty()) {
        qDebug() << "SyncEngine: Pushing" << dirtyTasks.size() << "dirty tasks.";
        m_firestoreService->syncTasksUp(dirtyTasks);
    }
}

void SyncService::onSyncCompleted(bool success, const QStringList& syncedTaskIds) {
    if (success) {
        qDebug() << "SyncEngine: Batch push successful, clearing dirty flags for" << syncedTaskIds.size() << "tasks.";
        for (const QString& id : syncedTaskIds) {
            m_cacheService->clearDirtyFlag(id);
        }
    } else {
        qWarning() << "SyncEngine: Batch push failed, keeping dirty flags.";
    }
}

void SyncService::onRemoteTasksFetched(const QList<Task>& tasks) {
    qDebug() << "SyncEngine: Fetched" << tasks.size() << "remote tasks. Resolving conflicts...";
    
    int savedCount = 0;
    for (const Task& remoteTask : tasks) {
        Task localTask = m_cacheService->getTask(remoteTask.id);
        
        if (localTask.id.isEmpty()) {
            // Task does not exist locally, save it
            m_cacheService->saveTask(remoteTask, false); // false = not dirty
            savedCount++;
        } else {
            // Local pending changes must never be overwritten by stale remote data.
            if (localTask.isDirty) {
                continue;
            }

            if (!remoteTask.updatedAt.isValid()) {
                continue;
            }

            if (localTask.updatedAt < remoteTask.updatedAt) {
                // Remote is newer, update local
                m_cacheService->saveTask(remoteTask, false); // false = not dirty
                savedCount++;
            }
        }
    }
    
    if (savedCount > 0) {
        qDebug() << "SyncEngine: Applied" << savedCount << "remote updates to local cache.";
        emit tasksChanged();
    }
}

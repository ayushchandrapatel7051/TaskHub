#include "SyncService.h"
#include <QDebug>

SyncService::SyncService(LocalCacheService* cacheService, FirestoreService* firestoreService, QObject *parent)
    : QObject(parent), m_cacheService(cacheService), m_firestoreService(firestoreService) {
    
    // Setup interval sync every 5 minutes
    m_syncTimer.setInterval(5 * 60 * 1000);
    connect(&m_syncTimer, &QTimer::timeout, this, &SyncService::performSync);
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
    // (Needs tracking 'synced' flag in SQLite)
    QList<Task> allLocalTasks = m_cacheService->getAllTasks();
    m_firestoreService->syncTasksUp(allLocalTasks);
}

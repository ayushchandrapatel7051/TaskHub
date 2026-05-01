#ifndef SYNC_SERVICE_H
#define SYNC_SERVICE_H

#include <QObject>
#include <QTimer>
#include "LocalCacheService.h"
#include "FirestoreService.h"

class SyncService : public QObject {
    Q_OBJECT
public:
    explicit SyncService(LocalCacheService* cacheService, FirestoreService* firestoreService, QObject *parent = nullptr);

    void startSync();
    void stopSync();

private slots:
    void performSync();

private:
    LocalCacheService* m_cacheService;
    FirestoreService* m_firestoreService;
    QTimer m_syncTimer;
};

#endif // SYNC_SERVICE_H

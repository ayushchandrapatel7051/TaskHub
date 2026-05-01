#include <QCoreApplication>
#include <QDebug>
#include "cpp/models/Task.h"
#include "cpp/services/LocalCacheService.h"
#include "cpp/services/TaskService.h"

int main(int argc, char *argv[]) {
    QCoreApplication a(argc, argv);
    
    LocalCacheService cacheService;
    TaskService taskService(&cacheService);
    
    // Create a task
    qDebug() << "Creating task 'Test Task'...";
    taskService.createTask("Test Task", "Test Desc");
    
    auto tasks = taskService.getTasks();
    qDebug() << "Tasks count:" << tasks.count();
    
    if (tasks.isEmpty()) {
        qDebug() << "FAILED: No tasks found!";
        return 0;
    }
    
    Task t = tasks.last();
    qDebug() << "Found task:" << t.title << "ID:" << t.id << "Completed:" << t.isCompleted;
    
    // Toggle completion
    qDebug() << "Toggling completion...";
    taskService.updateTaskStatus(t.id, "completed");
    
    tasks = taskService.getTasks();
    Task t2 = tasks.last();
    qDebug() << "After toggle:" << t2.title << "Completed:" << t2.isCompleted;
    
    // Delete task
    qDebug() << "Deleting task...";
    taskService.deleteTask(t2.id);
    
    tasks = taskService.getTasks();
    qDebug() << "Tasks count after delete:" << tasks.count();
    
    return 0;
}

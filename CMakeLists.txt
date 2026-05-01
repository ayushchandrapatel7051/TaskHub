cmake_minimum_required(VERSION 3.16)

project(TaskHub VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Qml Quick Sql Network)

qt_standard_project_setup()

set(PROJECT_SOURCES
    app/main.cpp
    # Services
    cpp/services/LocalCacheService.cpp
    cpp/services/LocalCacheService.h
    cpp/services/TaskService.cpp
    cpp/services/TaskService.h
    cpp/services/AuthService.cpp
    cpp/services/AuthService.h
    cpp/services/FirestoreService.cpp
    cpp/services/FirestoreService.h
    cpp/services/SyncService.cpp
    cpp/services/SyncService.h
    # Models
    cpp/models/Task.cpp
    cpp/models/Task.h
    # ViewModels
    cpp/viewmodels/TaskListViewModel.cpp
    cpp/viewmodels/TaskListViewModel.h
)

qt_add_executable(TaskHub
    MANUAL_FINALIZATION
    ${PROJECT_SOURCES}
)

# Resources (QML and assets)
qt_add_resources(TaskHub qml_resources
    PREFIX "/"
    FILES
        qml/Main.qml
        qml/theme/Theme.qml
        qml/theme/qmldir
        qml/components/Sidebar.qml
        qml/components/TaskList.qml
        qml/components/TaskItem.qml
        qml/components/TaskDetail.qml
        qml/components/CalendarView.qml
        qml/components/LoginScreen.qml
        resources/firebase_config.json
)

target_link_libraries(TaskHub
    PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::Sql Qt6::Network
)

set_target_properties(TaskHub PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER my.example.com
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

install(TARGETS TaskHub
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

qt_finalize_executable(TaskHub)

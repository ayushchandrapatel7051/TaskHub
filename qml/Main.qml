import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme"
import "components"

ApplicationWindow {
    id: window
    width: 1200
    height: 800
    visible: true
    title: qsTr("TaskHub")
    
    // Premium Dark Theme Setup
    color: Theme.background

    Component.onCompleted: {
        authService.autoLogin()
    }
    
    Loader {
        anchors.fill: parent
        sourceComponent: authService.isAuthenticated ? dashboardView : loginView
    }

    Component {
        id: loginView
        LoginScreen {}
    }

    Component {
        id: dashboardView
        Rectangle {
            id: dashboard
            property string activeView: "tasks"

            anchors.fill: parent
            color: Theme.background

            function viewIndex(view) {
                switch (view) {
                    case "calendar": return 1
                    case "matrix": return 2
                    case "pomodoro": return 3
                    case "habit": return 4
                    case "search": return 5
                    default: return 0
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0
            
                Sidebar {
                    id: sidebar
                    activeView: dashboard.activeView
                    Layout.preferredWidth: implicitWidth
                    Layout.fillHeight: true
                    onViewRequested: function(view) {
                        dashboard.activeView = view
                        if (view === "calendar") {
                            taskListViewModel.setFilterDate("Calendar")
                        } else if (view === "tasks") {
                            taskListViewModel.setFilterDate("All")
                        } else if (view === "matrix" || view === "search") {
                            taskListViewModel.setFilterDate("All")
                        }
                    }
                }
                
                StackLayout {
                    id: mainStack
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: dashboard.viewIndex(dashboard.activeView)
                    
                    TaskList {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                    
                    CalendarView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    EisenhowerMatrixView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    PomodoroView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    HabitTrackerView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    SearchView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
                
                TaskDetail {
                    Layout.preferredWidth: 340
                    Layout.fillHeight: true
                    visible: dashboard.activeView === "tasks"
                }
            }
        }
    }
}

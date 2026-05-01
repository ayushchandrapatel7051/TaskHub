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
            anchors.fill: parent
            color: Theme.background

            RowLayout {
                anchors.fill: parent
                spacing: 0
            
            Sidebar {
                Layout.preferredWidth: 290
                Layout.fillHeight: true
            }
            
            StackLayout {
                id: mainStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: taskListViewModel.activeFilterDate === "Calendar" ? 1 : 0
                
                TaskList {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                
                CalendarView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
            
            TaskDetail {
                Layout.preferredWidth: 340
                Layout.fillHeight: true
                visible: true
            }
            }
        }
    }
}

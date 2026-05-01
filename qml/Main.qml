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
        RowLayout {
            spacing: 0
            
            Sidebar {
                Layout.preferredWidth: 260
                Layout.fillHeight: true
            }
            
            TaskList {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
            
            TaskDetail {
                Layout.preferredWidth: 350
                Layout.fillHeight: true
            }
        }
    }
}

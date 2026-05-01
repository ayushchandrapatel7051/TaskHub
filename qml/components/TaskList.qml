import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    color: Theme.background

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        // Header
        Text {
            text: "Inbox"
            color: Theme.textPrimary
            font.pixelSize: 28
            font.bold: true
            font.family: Theme.fontFamily
        }

        // Quick Add Input
        Rectangle {
            Layout.fillWidth: true
            height: 50
            color: Theme.surface
            radius: Theme.radiusMedium
            border.color: Theme.divider

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                
                TextField {
                    id: taskInput
                    Layout.fillWidth: true
                    placeholderText: "Add a task..."
                    color: Theme.textPrimary
                    font.pixelSize: 16
                    font.family: Theme.fontFamily
                    background: null
                    
                    onAccepted: {
                        if (text.trim() !== "") {
                            taskListViewModel.addTask(text, "")
                            text = ""
                        }
                    }
                }
            }
        }

        // List View
        ListView {
            id: taskListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: taskListViewModel
            clip: true
            spacing: 8
            
            section.property: "section"
            section.delegate: Rectangle {
                width: ListView.view ? ListView.view.width : 0
                height: 40
                color: "transparent"
                
                // We need to fetch the collapsed state dynamically.
                // We'll use a local property updated by the connection.
                property bool isCollapsed: taskListViewModel.isSectionCollapsed(section)
                
                Connections {
                    target: taskListViewModel
                    function onSectionToggled() {
                        isCollapsed = taskListViewModel.isSectionCollapsed(section)
                    }
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    
                    Text {
                        text: isCollapsed ? "▶" : "▼"
                        color: Theme.textMuted
                        font.pixelSize: 12
                    }
                    
                    Text {
                        text: section
                        color: Theme.textSecondary
                        font.pixelSize: 14
                        font.bold: true
                        font.family: Theme.fontFamily
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        taskListViewModel.toggleSection(section)
                    }
                }
            }
            
            delegate: TaskItem {
                width: ListView.view.width
                taskIndex: index
                taskTitle: model.title
                taskCompleted: model.isCompleted
                taskPriority: model.priority !== undefined ? model.priority : 0
                taskSection: model.section
                
                onToggled: taskListViewModel.toggleTaskCompletion(index)
                onRenamed: function(newTitle) { taskListViewModel.renameTask(index, newTitle) }
                onDeleted: taskListViewModel.softDeleteTask(index)
            }
        }
    }
}

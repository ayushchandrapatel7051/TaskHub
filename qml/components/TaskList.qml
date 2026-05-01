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
        
        Shortcut {
            sequence: "Ctrl+K"
            onActivated: searchInput.forceActiveFocus()
        }
        
        Shortcut {
            sequence: "Return"
            onActivated: {
                if (newTaskInput.activeFocus) {
                    addTask()
                }
            }
        }

        // Header Area
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: taskListViewModel.activeFilterDate === "" ? "Inbox" : taskListViewModel.activeFilterDate
                color: Theme.textPrimary
                font.pixelSize: 28
                font.bold: true
                font.family: Theme.fontFamily
            }
            
            Item { Layout.fillWidth: true } // Spacer
            
            // Active Tag Filter Badge
            Rectangle {
                visible: taskListViewModel.activeFilterTag !== ""
                height: 28
                width: filterText.width + 30
                radius: 14
                color: Theme.primary + "33"
                border.color: Theme.primary
                border.width: 1
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 5
                    
                    Text {
                        id: filterText
                        text: "Tagged: #" + taskListViewModel.activeFilterTag
                        color: Theme.primary
                        font.pixelSize: 13
                        font.bold: true
                        font.family: Theme.fontFamily
                    }
                    
                    Text {
                        text: "✕"
                        color: Theme.primary
                        font.pixelSize: 12
                        font.bold: true
                        
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -5
                            cursorShape: Qt.PointingHandCursor
                            onClicked: taskListViewModel.clearFilters()
                        }
                    }
                }
            }
        }

        // Search Bar
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: Theme.surface
            radius: Theme.radiusMedium
            border.color: searchInput.activeFocus ? Theme.primary : Theme.divider
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                
                Text {
                    text: "🔍"
                    color: Theme.textMuted
                    font.pixelSize: 14
                }
                
                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: "Search tasks..."
                    color: Theme.textPrimary
                    font.pixelSize: 14
                    font.family: Theme.fontFamily
                    background: null
                    text: taskListViewModel.searchQuery
                    
                    Timer {
                        id: debounceTimer
                        interval: 300
                        onTriggered: taskListViewModel.setSearchQuery(searchInput.text)
                    }
                    
                    onTextEdited: debounceTimer.restart()
                }
                
                Text {
                    visible: searchInput.text !== ""
                    text: "✕"
                    color: Theme.textMuted
                    font.pixelSize: 12
                    font.bold: true
                    
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -5
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = ""
                            taskListViewModel.setSearchQuery("")
                        }
                    }
                }
            }
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
            
            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutQuad }
                NumberAnimation { property: "scale"; from: 0.8; to: 1; duration: 250; easing.type: Easing.OutBack }
            }
            
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: 200 }
                NumberAnimation { property: "scale"; to: 0.8; duration: 200 }
            }
            
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
                taskTags: model.tags !== undefined ? model.tags : []
                
                onToggled: taskListViewModel.toggleTaskCompletion(index)
                onRenamed: function(newTitle) { taskListViewModel.renameTask(index, newTitle) }
                onDeleted: taskListViewModel.softDeleteTask(index)
            }
        }
    }
}

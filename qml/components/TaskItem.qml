import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    height: visible ? 48 : 0
    visible: !isSectionCollapsed
    property bool isSelected: root.taskIndex === taskListViewModel.selectedTaskIndex
    
    color: isSelected ? "#22262d" : (mouseArea.containsMouse ? "#1b1f25" : "transparent")
    radius: Theme.radiusMedium
    border.color: "transparent"
    border.width: 0

    property string taskTitle: ""
    property bool taskCompleted: false
    property int taskPriority: 0
    property string taskSection: ""
    property bool isSectionCollapsed: taskListViewModel.isSectionCollapsed(taskSection)
    
    property var taskTags: []

    signal toggled()

    property int taskIndex: -1
    signal renamed(string newTitle)
    signal deleted()
    
    // Listen for section toggles to show/hide items
    Connections {
        target: taskListViewModel
        function onSectionToggled() {
            root.isSectionCollapsed = taskListViewModel.isSectionCollapsed(taskSection)
        }
    }

    // Smooth hover transition
    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        visible: root.visible

        // Drag Handle (Placeholder for Drag logic)
        Text {
            text: "⋮⋮"
            color: mouseArea.containsMouse ? Theme.textMuted : "transparent"
            font.pixelSize: 18
            font.bold: true
        }

        // Priority Indicator
        Rectangle {
            width: 3
            height: parent.height - 8
            radius: 1
            color: {
                if (taskPriority === 3) return Theme.accentRed
                if (taskPriority === 2) return Theme.accentYellow
                if (taskPriority === 1) return Theme.accentBlue
                return "transparent"
            }
        }

        // Checkbox
        Rectangle {
            width: 16
            height: 16
            radius: 4
            border.color: taskCompleted ? Theme.primary : Theme.textMuted
            border.width: 2
            color: taskCompleted ? Theme.primary : "transparent"
            
            // Checkmark icon placeholder
            Text {
                anchors.centerIn: parent
                text: "✓"
                color: "white"
                visible: taskCompleted
                font.pixelSize: 10
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: root.toggled()
            }
        }

        // Title and Tags container
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            
            // Title (Editable)
            TextField {
                id: titleField
                Layout.fillWidth: true
                text: root.taskTitle
                color: taskCompleted ? Theme.textMuted : Theme.textPrimary
                font.pixelSize: 16
                font.strikeout: taskCompleted
                font.family: Theme.fontFamily
                background: null // Transparent background
                padding: 0
                
                onEditingFinished: {
                    if (text !== root.taskTitle && text.trim() !== "") {
                        root.renamed(text)
                    }
                }
            }
            
            // Tags Row
            Row {
                spacing: 5
                visible: root.taskTags.length > 0
                
                Repeater {
                    model: root.taskTags
                    
                    Rectangle {
                        color: Theme.surfaceHover
                        radius: Theme.radiusSmall
                        height: 18
                        width: tagText.width + 12
                        
                        Text {
                            id: tagText
                            anchors.centerIn: parent
                            text: "#" + modelData
                            color: Theme.textSecondary
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                        }
                    }
                }
            }
        }

        // Delete Button
        Rectangle {
            width: 30
            height: 30
            radius: 15
            color: deleteMouseArea.containsMouse ? Theme.accentRed : "transparent"
            visible: mouseArea.containsMouse
            
            Text {
                anchors.centerIn: parent
                text: "🗑" // Trash icon
                color: deleteMouseArea.containsMouse ? "white" : Theme.accentRed
                font.pixelSize: 16
            }
            
            MouseArea {
                id: deleteMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.deleted()
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: taskListViewModel.selectTask(root.taskIndex)
    }
}

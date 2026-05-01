import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    height: visible ? 60 : 0
    visible: !isSectionCollapsed
    color: mouseArea.containsMouse ? Theme.surfaceHover : Theme.surface
    radius: Theme.radiusMedium
    border.color: Theme.divider

    property string taskTitle: ""
    property bool taskCompleted: false
    property int taskPriority: 0
    property string taskSection: ""
    property bool isSectionCollapsed: taskListViewModel.isSectionCollapsed(taskSection)
    
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
        anchors.margins: 15
        spacing: 15
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
            width: 4
            height: 30
            radius: 2
            color: {
                if (taskPriority === 3) return Theme.accentRed
                if (taskPriority === 2) return Theme.accentYellow
                if (taskPriority === 1) return Theme.accentBlue
                return "transparent"
            }
        }

        // Checkbox
        Rectangle {
            width: 24
            height: 24
            radius: 12
            border.color: taskCompleted ? Theme.primary : Theme.textMuted
            border.width: 2
            color: taskCompleted ? Theme.primary : "transparent"
            
            // Checkmark icon placeholder
            Text {
                anchors.centerIn: parent
                text: "✓"
                color: "white"
                visible: taskCompleted
                font.pixelSize: 14
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: root.toggled()
            }
        }

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
            
            onEditingFinished: {
                if (text !== root.taskTitle && text.trim() !== "") {
                    root.renamed(text)
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
        acceptedButtons: Qt.NoButton // Let the checkbox handle clicks
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    color: Theme.surface
    border.color: Theme.divider
    border.width: 1

    property bool hasSelection: taskListViewModel.selectedTaskIndex >= 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20
        
        // Empty State
        Text {
            visible: !root.hasSelection
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "Select a task to view details"
            color: Theme.textMuted
            font.pixelSize: 16
            font.family: Theme.fontFamily
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        // Selected State
        ColumnLayout {
            visible: root.hasSelection
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 15

            // Title
            Text {
                Layout.fillWidth: true
                text: root.hasSelection ? taskListViewModel.selectedTaskTitle : ""
                color: Theme.textPrimary
                font.pixelSize: 22
                font.bold: true
                font.family: Theme.fontFamily
                wrapMode: Text.Wrap
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.divider
            }

            // Due Date
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Due Date:"
                    color: Theme.textSecondary
                    font.pixelSize: 14
                    font.bold: true
                }
                TextField {
                    id: dateInput
                    Layout.fillWidth: true
                    placeholderText: "YYYY-MM-DD"
                    text: root.hasSelection ? taskListViewModel.selectedTaskDueAt : ""
                    color: Theme.textPrimary
                    background: Rectangle {
                        color: Theme.background
                        border.color: Theme.divider
                        radius: Theme.radiusSmall
                    }
                    onEditingFinished: {
                        if (root.hasSelection) {
                            taskListViewModel.updateSelectedTaskDueAt(text)
                        }
                    }
                }
            }

            // Priority
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Text {
                    text: "Priority:"
                    color: Theme.textSecondary
                    font.pixelSize: 14
                    font.bold: true
                }
                RowLayout {
                    Repeater {
                        model: ["Low", "Medium", "High"]
                        Rectangle {
                            height: 30
                            Layout.fillWidth: true
                            radius: Theme.radiusSmall
                            color: {
                                let isActive = root.hasSelection && taskListViewModel.selectedTaskPriority === (index + 1)
                                if (!isActive) return Theme.background
                                if (index === 2) return Theme.accentRed
                                if (index === 1) return Theme.accentYellow
                                return Theme.accentBlue
                            }
                            border.color: Theme.divider
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: (root.hasSelection && taskListViewModel.selectedTaskPriority === (index + 1)) ? "white" : Theme.textPrimary
                                font.pixelSize: 13
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.hasSelection) taskListViewModel.updateSelectedTaskPriority(index + 1)
                                }
                            }
                        }
                    }
                }
            }

            // Tags
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Text {
                    text: "Tags (comma separated):"
                    color: Theme.textSecondary
                    font.pixelSize: 14
                    font.bold: true
                }
                TextField {
                    id: tagsInput
                    Layout.fillWidth: true
                    placeholderText: "work, urgent..."
                    text: root.hasSelection ? taskListViewModel.selectedTaskTags.join(", ") : ""
                    color: Theme.textPrimary
                    background: Rectangle {
                        color: Theme.background
                        border.color: Theme.divider
                        radius: Theme.radiusSmall
                    }
                    onEditingFinished: {
                        if (root.hasSelection) taskListViewModel.updateSelectedTaskTags(text)
                    }
                }
            }

            // Notes
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 5
                Text {
                    text: "Notes:"
                    color: Theme.textSecondary
                    font.pixelSize: 14
                    font.bold: true
                }
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    TextArea {
                        id: notesInput
                        placeholderText: "Add details or subtasks..."
                        text: root.hasSelection ? taskListViewModel.selectedTaskDescription : ""
                        color: Theme.textPrimary
                        wrapMode: TextArea.Wrap
                        background: Rectangle {
                            color: Theme.background
                            border.color: Theme.divider
                            radius: Theme.radiusSmall
                        }
                        onEditingFinished: {
                            if (root.hasSelection) taskListViewModel.updateSelectedTaskDescription(text)
                        }
                    }
                }
            }
        }
    }
}

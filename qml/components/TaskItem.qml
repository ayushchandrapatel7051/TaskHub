import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    height: visible ? 40 : 0
    visible: !isSectionCollapsed

    property bool isSelected: root.taskIndex === taskListViewModel.selectedTaskIndex
    property string taskTitle: ""
    property bool taskCompleted: false
    property int taskPriority: 0
    property string taskSection: ""
    property bool isSectionCollapsed: taskListViewModel.isSectionCollapsed(taskSection)
    property var taskTags: []
    property int taskIndex: -1

    signal toggled()
    signal renamed(string newTitle)
    signal deleted()

    color: isSelected ? "#242424" : (rowHover.hovered ? "#1f1f1f" : "transparent")
    radius: 0
    opacity: taskCompleted ? 0.58 : 1.0

    HoverHandler { id: rowHover }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: taskListViewModel.selectTask(root.taskIndex)
    }

    Connections {
        target: taskListViewModel
        function onSectionToggled() {
            root.isSectionCollapsed = taskListViewModel.isSectionCollapsed(taskSection)
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: "#252525"
        visible: root.visible
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 8
        visible: root.visible

        Rectangle {
            Layout.preferredWidth: 3
            Layout.preferredHeight: 22
            radius: 2
            color: {
                if (taskCompleted) return "transparent"
                if (taskPriority === 3) return Theme.accentRed
                if (taskPriority === 2) return Theme.accentYellow
                if (taskPriority === 1) return Theme.primary
                return "transparent"
            }
        }

        Rectangle {
            Layout.preferredWidth: 15
            Layout.preferredHeight: 15
            radius: 4
            border.color: taskCompleted ? Theme.primary : "#7a7f89"
            border.width: 1.4
            color: taskCompleted ? Theme.primary : "transparent"

            Text {
                anchors.centerIn: parent
                text: "✓"
                color: "white"
                visible: taskCompleted
                font.pixelSize: 10
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggled()
            }
        }

        TextField {
            id: titleField
            Layout.fillWidth: true
            text: root.taskTitle
            color: taskCompleted ? "#8a8f99" : Theme.textPrimary
            font.pixelSize: 14
            font.strikeout: taskCompleted
            font.family: Theme.fontFamily
            background: null
            padding: 0
            selectByMouse: true

            onEditingFinished: {
                if (text !== root.taskTitle && text.trim() !== "") {
                    root.renamed(text)
                }
            }
        }

        Row {
            spacing: 6
            visible: root.taskTags.length > 0
            Layout.maximumWidth: 260
            clip: true

            Repeater {
                model: root.taskTags

                Rectangle {
                    height: 20
                    width: tagText.width + 12
                    radius: 10
                    color: "#75435a"

                    Text {
                        id: tagText
                        anchors.centerIn: parent
                        text: modelData
                        color: "#f0cedc"
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }
                }
            }
        }

        Rectangle {
            width: 26
            height: 26
            radius: 6
            color: deleteMouseArea.containsMouse ? "#3a2323" : "transparent"
            visible: rowHover.hovered

            SidebarIcon {
                anchors.centerIn: parent
                width: 15
                height: 15
                iconName: "trash"
                iconColor: deleteMouseArea.containsMouse ? Theme.accentRed : "#8b8f98"
                strokeWidth: 1.5
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
}

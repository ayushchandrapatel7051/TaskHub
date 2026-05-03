import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    height: visible ? 42 : 0
    visible: !isSectionCollapsed

    property bool isSelected: root.taskIndex === taskListViewModel.selectedTaskIndex
    property string taskTitle: ""
    property bool taskCompleted: false
    property int taskPriority: 0
    property string taskSection: ""
    property bool isSectionCollapsed: taskListViewModel.isSectionCollapsed(taskSection)
    property var taskTags: []
    property int taskIndex: -1
    property string taskList: ""
    property string taskDueAt: ""

    signal toggled()
    signal renamed(string newTitle)
    signal deleted()

    color: isSelected ? "#242424" : (rowHover.hovered ? "#1f1f1f" : "transparent")
    radius: 0
    opacity: taskCompleted ? 0.58 : 1.0

    HoverHandler { id: rowHover }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: {
            taskListViewModel.selectTask(root.taskIndex)
            titleField.forceActiveFocus()
        }
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
                if (taskTags.length === 0) return "transparent"
                var saved = taskListViewModel.getSavedTagColor(taskTags[0])
                if (saved !== "") return saved
                var palette = ["#e83d3d", "#eb8a23", "#e0e72c", "#2ef02a", "#4b6fff", "#bb68ef", "#eb68aa"]
                var hash = 0
                for (var i = 0; i < taskTags[0].length; i++) {
                    hash = taskTags[0].charCodeAt(i) + ((hash << 5) - hash)
                }
                return palette[Math.abs(hash) % palette.length]
            }
        }

        Rectangle {
            Layout.preferredWidth: 15
            Layout.preferredHeight: 15
            radius: 3
            border.color: {
                if (taskCompleted) return Theme.primary
                if (taskPriority === 3) return Theme.accentRed
                if (taskPriority === 2) return Theme.accentYellow
                if (taskPriority === 1) return Theme.primary
                return "#7a7f89"
            }
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

            onActiveFocusChanged: {
                if (activeFocus) {
                    taskListViewModel.selectTask(root.taskIndex)
                }
            }

            onEditingFinished: {
                if (text !== root.taskTitle && text.trim() !== "") {
                    root.renamed(text)
                }
            }
        }

        // ── Right meta row: tags → list → due date ────────────────────
        Row {
            spacing: 6
            Layout.maximumWidth: 320
            clip: true

            // Tag chips
            Repeater {
                model: root.taskTags.slice(0, 3)  // cap at 3 tags

                Rectangle {
                    height: 20
                    width: tagText.width + 16
                    radius: 4
                    color: Qt.rgba(tagAccentColor.r, tagAccentColor.g, tagAccentColor.b, 0.12)

                    Text {
                        id: tagText
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 7
                        text: modelData
                        color: Qt.rgba(tagAccentColor.r, tagAccentColor.g, tagAccentColor.b, 0.7)
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }

                    property color tagAccentColor: {
                        var saved = taskListViewModel.getSavedTagColor(modelData)
                        if (saved !== "") return saved
                        var palette = ["#e83d3d", "#eb8a23", "#e0e72c", "#2ef02a", "#4b6fff", "#bb68ef", "#eb68aa"]
                        var hash = 0
                        for (var i = 0; i < modelData.length; i++) {
                            hash = modelData.charCodeAt(i) + ((hash << 5) - hash)
                        }
                        return palette[Math.abs(hash) % palette.length]
                    }
                }
            }

            // List name pill — hide when already filtered by this list
            Rectangle {
                visible: root.taskList !== "" && root.taskList !== "Inbox" &&
                         taskListViewModel.activeFilterList !== root.taskList
                height: 20
                width: listLabel.width + 22
                radius: 4
                color: "#2d2d2d"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 4

                    SidebarIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 11
                        height: 11
                        iconName: "list"
                        iconColor: "#9a9a9a"
                        strokeWidth: 1.5
                    }
                    Text {
                        id: listLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.taskList
                        color: "#9a9a9a"
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }
                }
            }

            // Due date pill
            Rectangle {
                visible: root.taskDueAt !== ""
                height: 20
                width: dateLabel.width + 20
                radius: 4
                color: "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    spacing: 4

                    SidebarIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 11
                        height: 11
                        iconName: "calendar"
                        iconColor: {
                            if (root.taskSection === "Overdue") return Theme.accentRed
                            if (root.taskSection === "Today")   return Theme.accentYellow
                            return "#8a8f99"
                        }
                        strokeWidth: 1.5
                    }
                    Text {
                        id: dateLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (root.taskDueAt === "") return ""
                            var d = new Date(root.taskDueAt)
                            var months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
                            return months[d.getMonth()] + " " + d.getDate()
                        }
                        color: {
                            if (root.taskSection === "Overdue") return Theme.accentRed
                            if (root.taskSection === "Today")   return Theme.accentYellow
                            return "#8a8f99"
                        }
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

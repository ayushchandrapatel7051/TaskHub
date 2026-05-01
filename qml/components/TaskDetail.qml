import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    color: "#181818"
    border.color: "#303030"
    border.width: 1

    property bool hasSelection: taskListViewModel.selectedTaskIndex >= 0

    function lines() {
        return taskListViewModel.selectedTaskDescription.split("\n")
    }

    function isSubtaskLine(line) {
        return line.indexOf("- [ ] ") === 0 || line.indexOf("- [x] ") === 0
    }

    function subtaskTitle(line) {
        return line.substring(6)
    }

    function subtasks() {
        var result = []
        var source = lines()
        for (var i = 0; i < source.length; i++) {
            if (isSubtaskLine(source[i])) {
                result.push({ lineIndex: i, title: subtaskTitle(source[i]), done: source[i].indexOf("- [x] ") === 0 })
            }
        }
        return result
    }

    function notesText() {
        var result = []
        var source = lines()
        for (var i = 0; i < source.length; i++) {
            if (!isSubtaskLine(source[i])) result.push(source[i])
        }
        return result.join("\n").trim()
    }

    function rebuildDescription(newNotes) {
        var source = lines()
        var taskLines = []
        for (var i = 0; i < source.length; i++) {
            if (isSubtaskLine(source[i])) taskLines.push(source[i])
        }
        var pieces = []
        if (taskLines.length > 0) pieces.push(taskLines.join("\n"))
        if (newNotes.trim() !== "") pieces.push(newNotes.trim())
        taskListViewModel.updateSelectedTaskDescription(pieces.join("\n"))
    }

    function addSubtask(title) {
        var clean = title.trim()
        if (clean === "") return
        var current = taskListViewModel.selectedTaskDescription.trim()
        var next = current === "" ? "- [ ] " + clean : current + "\n- [ ] " + clean
        taskListViewModel.updateSelectedTaskDescription(next)
    }

    function toggleSubtask(lineIndex, done) {
        var source = lines()
        if (lineIndex < 0 || lineIndex >= source.length) return
        source[lineIndex] = (done ? "- [ ] " : "- [x] ") + subtaskTitle(source[lineIndex])
        taskListViewModel.updateSelectedTaskDescription(source.join("\n"))
    }

    Item {
        anchors.fill: parent
        visible: !root.hasSelection

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "✧"
                color: "#252525"
                font.pixelSize: 90
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Select a task"
                color: "#777777"
                font.pixelSize: 14
                font.family: Theme.fontFamily
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: root.hasSelection
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            Layout.leftMargin: 20
            Layout.rightMargin: 12
            spacing: 10

            Rectangle {
                width: 15
                height: 15
                radius: 3
                color: "transparent"
                border.color: "#ef4444"
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: taskListViewModel.toggleTaskCompletion(taskListViewModel.selectedTaskIndex)
                }
            }

            Text {
                text: taskListViewModel.selectedTaskDueAt === "" ? "No date" : taskListViewModel.selectedTaskDueAt
                color: taskListViewModel.selectedTaskDueAt === "" ? "#777777" : "#ff4b4b"
                font.pixelSize: 12
                font.family: Theme.fontFamily
                Layout.fillWidth: true
            }

            Text {
                text: "⚑"
                color: "#ef4444"
                font.pixelSize: 18
            }

            Text {
                text: "⌫"
                color: "#a8a8a8"
                font.pixelSize: 17
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: taskListViewModel.softDeleteTask(taskListViewModel.selectedTaskIndex)
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#303030" }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: detailColumn.height + 24
            clip: true

            ColumnLayout {
                id: detailColumn
                width: parent.width
                spacing: 18

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.topMargin: 20
                    text: taskListViewModel.selectedTaskTitle
                    color: "#f5f5f5"
                    font.pixelSize: 20
                    font.bold: true
                    font.family: Theme.fontFamily
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: 8

                    Repeater {
                        model: taskListViewModel.selectedTaskTags

                        Rectangle {
                            height: 22
                            width: tagLabel.width + 18
                            radius: 11
                            color: "#7e4f57"

                            Text {
                                id: tagLabel
                                anchors.centerIn: parent
                                text: modelData
                                color: "#f0dede"
                                font.pixelSize: 11
                                font.family: Theme.fontFamily
                            }
                        }
                    }

                    Text {
                        text: "+"
                        color: Theme.primary
                        font.pixelSize: 18
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: 6

                    Repeater {
                        model: root.subtasks()

                        delegate: RowLayout {
                            Layout.fillWidth: true
                            height: 34
                            spacing: 10

                            Rectangle {
                                width: 15
                                height: 15
                                radius: 3
                                color: modelData.done ? "#3b3b3b" : "transparent"
                                border.color: modelData.done ? "#3b3b3b" : "#777777"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    visible: modelData.done
                                    text: "✓"
                                    color: "#777777"
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleSubtask(modelData.lineIndex, modelData.done)
                                }
                            }

                            Text {
                                text: modelData.title
                                color: modelData.done ? "#777777" : "#f2f2f2"
                                font.pixelSize: 14
                                font.strikeout: modelData.done
                                font.family: Theme.fontFamily
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "↳"
                            color: "#777777"
                            font.pixelSize: 16
                        }

                        TextField {
                            id: subtaskInput
                            Layout.fillWidth: true
                            placeholderText: "Add Subtask"
                            color: "#f5f5f5"
                            placeholderTextColor: "#777777"
                            background: null
                            font.pixelSize: 14
                            font.family: Theme.fontFamily
                            onAccepted: {
                                root.addSubtask(text)
                                text = ""
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#303030" }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text { text: "▰"; color: "#bdbdbd"; font.pixelSize: 13 }
                        ComboBox {
                            Layout.fillWidth: true
                            model: taskListViewModel.getAllLists()
                            currentIndex: Math.max(0, taskListViewModel.getAllLists().indexOf(taskListViewModel.selectedTaskList))
                            onActivated: taskListViewModel.updateSelectedTaskList(currentText)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text { text: "▣"; color: "#bdbdbd"; font.pixelSize: 13 }
                        TextField {
                            Layout.fillWidth: true
                            text: taskListViewModel.selectedTaskDueAt
                            placeholderText: "Date"
                            color: "#f5f5f5"
                            placeholderTextColor: "#777777"
                            background: Rectangle { color: "#202020"; radius: 6; border.color: "#333333"; border.width: 1 }
                            onEditingFinished: taskListViewModel.updateSelectedTaskDueAt(text)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: [
                                { value: 3, color: "#ef4444" },
                                { value: 2, color: "#f59e0b" },
                                { value: 1, color: "#4b6fff" },
                                { value: 0, color: "#bdbdbd" }
                            ]

                            Rectangle {
                                Layout.preferredWidth: 42
                                height: 30
                                radius: 7
                                color: taskListViewModel.selectedTaskPriority === modelData.value ? modelData.color + "33" : "#222222"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.value === 0 ? "⚐" : "⚑"
                                    color: modelData.color
                                    font.pixelSize: 16
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: taskListViewModel.updateSelectedTaskPriority(modelData.value)
                                }
                            }
                        }
                    }

                    TextField {
                        Layout.fillWidth: true
                        text: taskListViewModel.selectedTaskTags.join(", ")
                        placeholderText: "Tags"
                        color: "#f5f5f5"
                        placeholderTextColor: "#777777"
                        background: Rectangle { color: "#202020"; radius: 6; border.color: "#333333"; border.width: 1 }
                        onEditingFinished: taskListViewModel.updateSelectedTaskTags(text)
                    }
                }

                TextArea {
                    id: notesInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    text: root.notesText()
                    placeholderText: "Add notes"
                    color: "#f5f5f5"
                    placeholderTextColor: "#777777"
                    wrapMode: TextArea.Wrap
                    font.pixelSize: 14
                    font.family: Theme.fontFamily
                    background: Rectangle {
                        color: "#202020"
                        radius: 8
                        border.color: "#333333"
                        border.width: 1
                    }
                    onActiveFocusChanged: {
                        if (!activeFocus) root.rebuildDescription(text)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            Layout.leftMargin: 20
            Layout.rightMargin: 16
            spacing: 14

            Text {
                text: "▰ " + taskListViewModel.selectedTaskList
                color: "#bdbdbd"
                font.pixelSize: 13
                font.family: Theme.fontFamily
                Layout.fillWidth: true
            }

            Text { text: "A"; color: "#d8d8d8"; font.pixelSize: 14 }
            Text { text: "◱"; color: "#d8d8d8"; font.pixelSize: 16 }
            Text { text: "..."; color: "#d8d8d8"; font.pixelSize: 18 }
        }
    }
}

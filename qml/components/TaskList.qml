import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    color: Theme.background

    // ── Priority picker popup ──────────────────────────────────────────
    Popup {
        id: priorityPicker
        parent: Overlay.overlay
        modal: false
        width: 220
        height: 60
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#1e1e2e"
            radius: Theme.radiusMedium
            border.color: Theme.divider
            border.width: 1
            layer.enabled: true
            layer.effect: null
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            Repeater {
                model: [
                    { label: "High",   color: "#ef4444", value: 3 },
                    { label: "Med",    color: "#f59e0b", value: 2 },
                    { label: "Low",    color: "#3b82f6", value: 1 },
                    { label: "None",   color: "#475569", value: 0 }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: Theme.radiusSmall
                    color: addBar.selectedPriority === modelData.value ? modelData.color + "33" : "transparent"
                    border.color: addBar.selectedPriority === modelData.value ? modelData.color : "transparent"

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "⚑"
                            color: modelData.color
                            font.pixelSize: 14
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.label
                            color: Theme.textSecondary
                            font.pixelSize: 9
                            font.family: Theme.fontFamily
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            addBar.selectedPriority = modelData.value
                            priorityPicker.close()
                        }
                    }
                }
            }
        }
    }

    // ── Date picker popup ──────────────────────────────────────────────
    Popup {
        id: datePicker
        parent: Overlay.overlay
        modal: false
        width: 240
        height: 170
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#1e1e2e"
            radius: Theme.radiusMedium
            border.color: Theme.divider
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text {
                text: "Quick Date"
                color: Theme.textSecondary
                font.pixelSize: 11
                font.bold: true
                font.family: Theme.fontFamily
                font.letterSpacing: 0.5
            }

            Repeater {
                model: [
                    { label: "Today",        icon: "☀",  days: 0  },
                    { label: "Tomorrow",      icon: "🌅", days: 1  },
                    { label: "Next Week",     icon: "📅", days: 7  },
                    { label: "No Date",       icon: "✕",  days: -1 }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: Theme.radiusSmall
                    color: dateHover.containsMouse ? Theme.surfaceHover : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        spacing: 10

                        Text {
                            text: modelData.icon
                            font.pixelSize: 14
                        }
                        Text {
                            text: modelData.label
                            color: Theme.textPrimary
                            font.pixelSize: 13
                            font.family: Theme.fontFamily
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            visible: modelData.days >= 0
                            text: modelData.days === 0
                                  ? Qt.formatDate(new Date(), "ddd")
                                  : (modelData.days === 1
                                     ? Qt.formatDate(new Date(new Date().getTime() + 86400000), "ddd")
                                     : "")
                            color: Theme.textMuted
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                            anchors.rightMargin: 8
                        }
                    }

                    HoverHandler { id: dateHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.days === -1) {
                                addBar.selectedDate = ""
                            } else {
                                var d = new Date()
                                d.setDate(d.getDate() + modelData.days)
                                addBar.selectedDate = Qt.formatDate(d, "yyyy-MM-dd")
                            }
                            datePicker.close()
                        }
                    }
                }
            }
        }
    }

    // ── Main layout ────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        Shortcut {
            sequence: "Ctrl+K"
            onActivated: addBar.expanded = true; taskInput.forceActiveFocus()
        }

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: taskListViewModel.activeFilterDate === "" ? "Inbox" : taskListViewModel.activeFilterDate
                color: Theme.textPrimary
                font.pixelSize: 34
                font.bold: true
                font.family: Theme.fontFamily
            }

            Item { Layout.fillWidth: true }

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

        // ── TickTick-style Add Task Bar ─────────────────────────────────
        Item {
            id: addBar
            Layout.fillWidth: true

            // Exposed state
            property bool expanded: false
            property int  selectedPriority: 0   // 0=None,1=Low,2=Med,3=High
            property string selectedDate: ""

            // Priority colour helpers
            property var priorityColors: ["#475569", "#3b82f6", "#f59e0b", "#ef4444"]
            property var priorityLabels: ["",         "Low",     "Med",     "High"]

            function submit() {
                var title = taskInput.text.trim()
                if (title === "") return
                taskListViewModel.addTask(title, "", addBar.selectedPriority, addBar.selectedDate)
                taskInput.text = ""
                addBar.selectedPriority = 0
                addBar.selectedDate = ""
                addBar.expanded = false
            }

            height: expanded ? expandedContainer.height : collapsedBar.height

            Behavior on height {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            // ── Collapsed placeholder bar ───────────────────────────────
            Rectangle {
                id: collapsedBar
                width: parent.width
                height: 40
                visible: !addBar.expanded
                color: Theme.panel
                radius: Theme.radiusMedium
                border.color: Theme.primary

                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: "+"
                        color: Theme.primary
                        font.pixelSize: 20
                        font.bold: true
                    }

                    Text {
                        text: "Add task to \"Inbox\""
                        color: Theme.textMuted
                        font.pixelSize: 14
                        font.family: Theme.fontFamily
                        Layout.fillWidth: true

                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }

                HoverHandler { id: collapsedHover }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        addBar.expanded = true
                        taskInput.forceActiveFocus()
                    }
                }
            }

            // ── Expanded input area ────────────────────────────────────
            Rectangle {
                id: expandedContainer
                width: parent.width
                visible: addBar.expanded
                height: visible ? innerCol.height + 2 : 0  // +2 for border
                color: Theme.surface
                radius: Theme.radiusMedium
                border.color: Theme.primary
                border.width: 1.5

                ColumnLayout {
                    id: innerCol
                    width: parent.width
                    spacing: 0

                    // Title input row
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 12
                        spacing: 10

                        // Priority dot indicator
                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: "transparent"
                            border.color: addBar.priorityColors[addBar.selectedPriority]
                            border.width: 2
                        }

                        TextField {
                            id: taskInput
                            Layout.fillWidth: true
                            placeholderText: "Task name"
                            color: Theme.textPrimary
                            font.pixelSize: 15
                            font.family: Theme.fontFamily
                            background: null
                            leftPadding: 0
                            rightPadding: 0

                            Keys.onReturnPressed: addBar.submit()
                            Keys.onEnterPressed:  addBar.submit()
                            Keys.onEscapePressed: {
                                text = ""
                                addBar.expanded = false
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.divider
                    }

                    // Action row
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        Layout.topMargin: 8
                        Layout.bottomMargin: 8
                        spacing: 4

                        // Date button
                        Rectangle {
                            height: 28
                            width: dateActionRow.implicitWidth + 16
                            radius: Theme.radiusSmall
                            color: addBar.selectedDate !== "" ? Theme.primary + "22" : "transparent"
                            border.color: addBar.selectedDate !== "" ? Theme.primary : "transparent"

                            RowLayout {
                                id: dateActionRow
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    text: "📅"
                                    font.pixelSize: 13
                                }
                                Text {
                                    text: addBar.selectedDate !== "" ? addBar.selectedDate : "Date"
                                    color: addBar.selectedDate !== "" ? Theme.primary : Theme.textMuted
                                    font.pixelSize: 12
                                    font.family: Theme.fontFamily
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var pos = mapToItem(Overlay.overlay, 0, height)
                                    datePicker.x = Math.max(12, Math.min(pos.x - datePicker.width + width, Overlay.overlay.width - datePicker.width - 12))
                                    datePicker.y = Math.min(pos.y + 8, Overlay.overlay.height - datePicker.height - 12)
                                    datePicker.open()
                                }
                            }
                        }

                        // Priority button
                        Rectangle {
                            height: 28
                            width: priorityActionRow.implicitWidth + 16
                            radius: Theme.radiusSmall
                            color: addBar.selectedPriority > 0 ? addBar.priorityColors[addBar.selectedPriority] + "22" : "transparent"
                            border.color: addBar.selectedPriority > 0 ? addBar.priorityColors[addBar.selectedPriority] : "transparent"

                            RowLayout {
                                id: priorityActionRow
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    text: "⚑"
                                    color: addBar.selectedPriority > 0 ? addBar.priorityColors[addBar.selectedPriority] : Theme.textMuted
                                    font.pixelSize: 14
                                }
                                Text {
                                    visible: addBar.selectedPriority > 0
                                    text: addBar.priorityLabels[addBar.selectedPriority]
                                    color: addBar.priorityColors[addBar.selectedPriority]
                                    font.pixelSize: 12
                                    font.family: Theme.fontFamily
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var pos = mapToItem(Overlay.overlay, 0, height)
                                    priorityPicker.x = Math.max(12, Math.min(pos.x - priorityPicker.width + width, Overlay.overlay.width - priorityPicker.width - 12))
                                    priorityPicker.y = Math.min(pos.y + 8, Overlay.overlay.height - priorityPicker.height - 12)
                                    priorityPicker.open()
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Cancel button
                        Rectangle {
                            height: 28
                            width: 64
                            radius: Theme.radiusSmall
                            color: cancelHover.containsMouse ? Theme.surfaceHover : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: Theme.textSecondary
                                font.pixelSize: 13
                                font.family: Theme.fontFamily
                            }

                            HoverHandler { id: cancelHover }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    taskInput.text = ""
                                    addBar.expanded = false
                                }
                            }
                        }

                        // Add button
                        Rectangle {
                            id: addButton
                            height: 28
                            width: 64
                            radius: Theme.radiusSmall
                            color: taskInput.text.trim() !== ""
                                   ? (addBtnHover.containsMouse ? Theme.primaryHover : Theme.primary)
                                   : Theme.surface
                            opacity: taskInput.text.trim() !== "" ? 1.0 : 0.5

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Add"
                                color: taskInput.text.trim() !== "" ? "white" : Theme.textMuted
                                font.pixelSize: 13
                                font.bold: true
                                font.family: Theme.fontFamily
                            }

                            HoverHandler { id: addBtnHover }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: taskInput.text.trim() !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: addBar.submit()
                            }
                        }
                    }
                }
            }
        } // end addBar

        // ── Task List View ────────────────────────────────────────────
        ListView {
            id: taskListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: taskListViewModel
            clip: true
            spacing: 8

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutQuad }
                NumberAnimation { property: "scale";   from: 0.8; to: 1; duration: 250; easing.type: Easing.OutBack }
            }

            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: 200 }
                NumberAnimation { property: "scale";   to: 0.8; duration: 200 }
            }

            section.property: "section"
            section.delegate: Rectangle {
                width: ListView.view ? ListView.view.width : 0
                height: 40
                color: "transparent"

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
                    onClicked: taskListViewModel.toggleSection(section)
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

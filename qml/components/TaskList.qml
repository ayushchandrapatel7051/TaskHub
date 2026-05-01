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
        z: 1001
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

    // ── Date picker popup (Custom Calendar) ───────────────────────────
    Popup {
        id: datePicker
        objectName: "datePicker"
        parent: Overlay.overlay
        modal: false
        width: 320
        height: Math.min(380, Overlay.overlay.height - 80)
        padding: 0
        z: 1000
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
            spacing: 12

            // Current month/year and navigation
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    text: "◀"
                    flat: true
                    padding: 4
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textMuted
                        font.pixelSize: 14
                    }
                    onClicked: {
                        var d = calendarHelper.currentMonth
                        d.setMonth(d.getMonth() - 1)
                        calendarHelper.currentMonth = d
                    }
                }

                Text {
                    id: monthYearText
                    text: calendarHelper.monthYearString
                    color: Theme.textPrimary
                    font.pixelSize: 14
                    font.bold: true
                    font.family: Theme.fontFamily
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Button {
                    text: "▶"
                    flat: true
                    padding: 4
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textMuted
                        font.pixelSize: 14
                    }
                    onClicked: {
                        var d = calendarHelper.currentMonth
                        d.setMonth(d.getMonth() + 1)
                        calendarHelper.currentMonth = d
                    }
                }
            }

            // Day of week headers
            GridLayout {
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 2
                rowSpacing: 2

                Repeater {
                    model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                    delegate: Text {
                        text: modelData
                        color: Theme.textMuted
                        font.pixelSize: 11
                        font.bold: true
                        font.family: Theme.fontFamily
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 4
                        bottomPadding: 4
                    }
                }
            }

            // Calendar days grid
            GridLayout {
                id: calendarGrid
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 2
                rowSpacing: 2

                Repeater {
                    id: daysRepeater
                    model: calendarHelper.days

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 4
                        color: {
                            if (modelData.isCurrentMonth === false) return "transparent"
                            if (modelData.isToday) return Theme.primary + "33"
                            if (modelData.isSelected) return Theme.primary
                            return "transparent"
                        }
                        border.color: modelData.isToday ? Theme.primary : "transparent"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day
                            color: {
                                if (modelData.isCurrentMonth === false) return Theme.textMuted
                                if (modelData.isSelected) return "white"
                                if (modelData.isToday) return Theme.primary
                                return Theme.textPrimary
                            }
                            font.pixelSize: 12
                            font.family: Theme.fontFamily
                            font.bold: modelData.isToday || modelData.isSelected
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: modelData.isCurrentMonth
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                addBar.selectedDate = modelData.dateString
                                calendarHelper.selectDate(modelData.dateString)
                                // Close popup through parent chain
                                var p = parent
                                while (p && p.objectName !== "datePicker") {
                                    p = p.parent
                                }
                                if (p && typeof p.close === "function") {
                                    p.close()
                                }
                            }
                        }
                    }
                }
            }

            // Quick action buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Button {
                    text: "Today"
                    Layout.fillWidth: true
                    palette.buttonText: Theme.textPrimary
                    onClicked: {
                        var today = new Date()
                        addBar.selectedDate = Qt.formatDate(today, "yyyy-MM-dd")
                        calendarHelper.currentMonth = today
                        datePicker.close()
                    }
                }

                Button {
                    text: "Clear"
                    Layout.fillWidth: true
                    palette.buttonText: Theme.textPrimary
                    onClicked: {
                        addBar.selectedDate = ""
                        datePicker.close()
                    }
                }
            }
        }

        QtObject {
            id: calendarHelper
            property date currentMonth: new Date()
            property var days: []

            onCurrentMonthChanged: updateDays()

            function updateDays() {
                var month = currentMonth.getMonth()
                var year = currentMonth.getFullYear()
                var firstDay = new Date(year, month, 1)
                var lastDay = new Date(year, month + 1, 0)
                var startDate = new Date(firstDay)
                startDate.setDate(startDate.getDate() - firstDay.getDay())

                var newDays = []
                var d = new Date(startDate)
                var today = new Date()

                for (var i = 0; i < 42; i++) {
                    var isCurrentMonth = d.getMonth() === month
                    var isToday = d.toDateString() === today.toDateString()
                    var isSelected = false

                    newDays.push({
                        day: d.getDate(),
                        dateString: Qt.formatDate(d, "yyyy-MM-dd"),
                        isCurrentMonth: isCurrentMonth,
                        isToday: isToday,
                        isSelected: isSelected
                    })

                    d.setDate(d.getDate() + 1)
                }

                days = newDays
                daysRepeater.model = newDays
            }

            function selectDate(dateStr) {
                for (var i = 0; i < days.length; i++) {
                    days[i].isSelected = (days[i].dateString === dateStr)
                }
                daysRepeater.model = days.slice()
            }

            property string monthYearString: {
                var months = ["January", "February", "March", "April", "May", "June",
                              "July", "August", "September", "October", "November", "December"]
                return months[currentMonth.getMonth()] + " " + currentMonth.getFullYear()
            }

            Component.onCompleted: updateDays()
        }
    }

    // ── Main layout ────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        Shortcut {
            sequence: "Ctrl+K"
            onActivated: {
                addBar.expanded = true
                taskInput.forceActiveFocus()
            }
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
            Layout.preferredHeight: height

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
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // First row: Date and Priority
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            // Date button
                            Rectangle {
                                height: 28
                                Layout.minimumWidth: 100
                                Layout.maximumWidth: 150
                                radius: Theme.radiusSmall
                                color: addBar.selectedDate !== "" ? Theme.primary + "22" : "transparent"
                                border.color: addBar.selectedDate !== "" ? Theme.primary : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 4

                                    Text {
                                        text: "📅"
                                        font.pixelSize: 12
                                    }
                                    Text {
                                        text: addBar.selectedDate !== "" ? addBar.selectedDate : "Date"
                                        color: addBar.selectedDate !== "" ? Theme.primary : Theme.textMuted
                                        font.pixelSize: 11
                                        font.family: Theme.fontFamily
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        datePicker.close()
                                        var pos = mapToItem(Overlay.overlay, 0, 0)
                                        var spaceBelow = Overlay.overlay.height - (pos.y + height + 8)
                                        
                                        if (spaceBelow < datePicker.height + 12) {
                                            datePicker.y = Math.max(12, pos.y - datePicker.height - 8)
                                        } else {
                                            datePicker.y = pos.y + height + 8
                                        }
                                        
                                        datePicker.x = Math.max(12, Math.min(pos.x, Overlay.overlay.width - datePicker.width - 12))
                                        datePicker.open()
                                    }
                                }
                            }

                            // Priority button
                            Rectangle {
                                height: 28
                                Layout.minimumWidth: 80
                                Layout.maximumWidth: 120
                                radius: Theme.radiusSmall
                                color: addBar.selectedPriority > 0 ? addBar.priorityColors[addBar.selectedPriority] + "22" : "transparent"
                                border.color: addBar.selectedPriority > 0 ? addBar.priorityColors[addBar.selectedPriority] : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 4

                                    Text {
                                        text: "⚑"
                                        color: addBar.selectedPriority > 0 ? addBar.priorityColors[addBar.selectedPriority] : Theme.textMuted
                                        font.pixelSize: 12
                                    }
                                    Text {
                                        visible: addBar.selectedPriority > 0
                                        text: addBar.priorityLabels[addBar.selectedPriority]
                                        color: addBar.priorityColors[addBar.selectedPriority]
                                        font.pixelSize: 11
                                        font.family: Theme.fontFamily
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        priorityPicker.close()
                                        var pos = mapToItem(Overlay.overlay, 0, 0)
                                        var spaceBelow = Overlay.overlay.height - (pos.y + height + 8)
                                        
                                        if (spaceBelow < priorityPicker.height + 12) {
                                            priorityPicker.y = Math.max(12, pos.y - priorityPicker.height - 8)
                                        } else {
                                            priorityPicker.y = pos.y + height + 8
                                        }
                                        
                                        priorityPicker.x = Math.max(12, Math.min(pos.x, Overlay.overlay.width - priorityPicker.width - 12))
                                        priorityPicker.open()
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        // Second row: Cancel and Add buttons
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

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
                                font.pixelSize: 12
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
                                font.pixelSize: 12
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

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    implicitWidth: 52 + (activeView === "tasks" ? 240 : 0)
    color: "#242424"

    property string activeView: "tasks"
    property int refreshRevision: 0
    property var pickerColors: ["#ef4444", "#fb7185", "#fb923c", "#facc15", "#e7f44a", "#22c55e", "#3b82f6", "#6366f1", "#bb68ef"]
    signal viewRequested(string view)

    function openCenteredPopup(popup) {
        popup.x = Math.max(12, (Overlay.overlay.width - popup.width) / 2)
        popup.y = Math.max(24, (Overlay.overlay.height - popup.height) / 2)
        popup.open()
    }

    function folderOptions() {
        root.refreshRevision
        return ["None"].concat(taskListViewModel.getAllFolders()).concat(["+ New Folder"])
    }

    component SidebarComboBox: ComboBox {
        id: control
        implicitHeight: 32
        font.family: Theme.fontFamily
        font.pixelSize: 13

        contentItem: Text {
            leftPadding: 10
            rightPadding: 28
            verticalAlignment: Text.AlignVCenter
            text: control.displayText
            color: "#e8e8e8"
            font: control.font
            elide: Text.ElideRight
        }

        indicator: Text {
            x: control.width - width - 10
            y: (control.height - height) / 2
            text: "⌄"
            color: "#8a8a8a"
            font.pixelSize: 14
        }

        background: Rectangle {
            radius: 7
            color: control.hovered ? "#303030" : "#242424"
            border.color: control.activeFocus ? Theme.primary : "#3b3b3b"
            border.width: 1
        }

        popup: Popup {
            y: control.height + 4
            width: control.width
            implicitHeight: Math.min(contentItem.implicitHeight + 8, 220)
            padding: 4
            background: Rectangle {
                color: "#252525"
                radius: 8
                border.color: "#3b3b3b"
            }
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: control.popup.visible ? control.delegateModel : null
                currentIndex: control.highlightedIndex
            }
        }

        delegate: ItemDelegate {
            width: control.width - 8
            height: 30
            highlighted: control.highlightedIndex === index
            contentItem: Text {
                text: modelData
                color: modelData === "+ New Folder" ? Theme.primary : "#e8e8e8"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            background: Rectangle {
                radius: 6
                color: highlighted ? "#343434" : "transparent"
            }
        }
    }

    component SidebarListRow: Rectangle {
        id: listRow
        property string listName: ""
        property int indent: 0
        Layout.fillWidth: true
        height: 34
        radius: 7
        color: taskListViewModel.activeFilterList === listName ? "#343434" : (listMouse.containsMouse ? "#2b2b2b" : "transparent")

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12 + listRow.indent
            anchors.rightMargin: 12
            spacing: 10

            SidebarIcon {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                iconName: "list"
                iconColor: "#f5f5f5"
                strokeWidth: 1.7
            }

            Text {
                text: listRow.listName
                color: "#f5f5f5"
                font.pixelSize: 14
                font.family: Theme.fontFamily
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: getTagColor(listRow.listName)
                visible: taskListViewModel.activeFilterList === listRow.listName
            }

            Text {
                text: {
                    root.refreshRevision
                    return taskListViewModel.getListTaskCount(listRow.listName)
                }
                color: "#858585"
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }

        MouseArea {
            id: listMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: taskListViewModel.setFilterList(listRow.listName)
        }
    }

    Connections {
        target: taskListViewModel
        function onFilterChanged() {
            root.refreshRevision++
        }
        function onTasksModified() {
            root.refreshRevision++
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 52
            Layout.fillHeight: true
            color: "#242424"
            border.color: "#333333"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 4
                anchors.bottomMargin: 12
                spacing: 10

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 32
                    height: 32
                    radius: 5
                    color: avatarMouse.containsMouse ? "#363636" : "#2e2e2e"
                    border.color: "#3f3f3f"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "TH"
                        color: "#f2f2f2"
                        font.pixelSize: 11
                        font.bold: true
                        font.family: Theme.fontFamily
                    }

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: -2
                        anchors.topMargin: -2
                        color: "#bfbfbf"
                        border.color: "#242424"
                        border.width: 1
                    }

                    MouseArea {
                        id: avatarMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: accountPopup.open()
                    }
                }

                Item { height: 6 }

                Repeater {
                    model: [
                        { view: "tasks", iconName: "tasks", label: "Tasks" },
                        { view: "calendar", iconName: "calendar", label: "Calendar" },
                        { view: "matrix", iconName: "matrix", label: "Eisenhower Matrix" },
                        { view: "pomodoro", iconName: "pomodoro", label: "Pomodoro" },
                        { view: "habit", iconName: "habit", label: "Habit Tracker" },
                        { view: "search", iconName: "search", label: "Search" }
                    ]

                    delegate: Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 34
                        height: 34
                        radius: 7
                        property bool selected: root.activeView === modelData.view
                        color: selected ? "#ffffff" : (navMouse.containsMouse ? "#353535" : "transparent")

                        SidebarIcon {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            iconName: modelData.iconName
                            iconColor: parent.selected ? "#242424" : "#b8b8b8"
                            strokeWidth: parent.selected ? 2.2 : 1.8
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.viewRequested(modelData.view)
                        }

                        ToolTip.visible: navMouse.containsMouse
                        ToolTip.text: modelData.label
                        ToolTip.delay: 450
                    }
                }

                Item { Layout.fillHeight: true }

                Repeater {
                    model: [
                        { action: "sync", iconName: "sync", label: "Sync" },
                        { action: "notifications", iconName: "notifications", label: "Notifications" },
                        { action: "help", iconName: "help", label: "Help" }
                    ]

                    delegate: Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 34
                        height: 34
                        radius: 7
                        color: bottomMouse.containsMouse ? "#353535" : "transparent"

                        SidebarIcon {
                            anchors.centerIn: parent
                            width: 17
                            height: 17
                            iconName: modelData.iconName
                            iconColor: "#929292"
                            strokeWidth: 1.8
                        }

                        MouseArea {
                            id: bottomMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.action === "sync") {
                                    syncService.performSync()
                                } else if (modelData.action === "notifications") {
                                    notificationsPopup.open()
                                } else {
                                    helpPopup.open()
                                }
                            }
                        }

                        ToolTip.visible: bottomMouse.containsMouse
                        ToolTip.text: modelData.label
                        ToolTip.delay: 450
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: activeView === "tasks" ? 240 : 0
            Layout.fillHeight: true
            visible: activeView === "tasks"
            color: "#1f1f1f"
            border.color: "#303030"
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 6
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.bottomMargin: 10
                spacing: 8

                Repeater {
                    model: [
                        { name: "All", iconName: "all" },
                        { name: "Today", iconName: "today" },
                        { name: "Next 7 Days", iconName: "next" },
                        { name: "Inbox", iconName: "inbox" },
                        { name: "Summary", iconName: "summary" }
                    ]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 7
                        property bool selected: modelData.name === "Inbox"
                                                ? taskListViewModel.activeFilterList === "Inbox"
                                                : taskListViewModel.activeFilterDate === modelData.name && taskListViewModel.activeFilterList === ""
                        color: selected ? "#343434" : (smartMouse.containsMouse ? "#2b2b2b" : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            SidebarIcon {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                iconName: modelData.iconName
                                iconColor: "#f2f2f2"
                                strokeWidth: 1.7
                            }

                            Text {
                                text: modelData.name
                                color: "#f5f5f5"
                                font.pixelSize: 14
                                font.family: Theme.fontFamily
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: getTaskCount(modelData.name)
                                color: "#858585"
                                font.pixelSize: 11
                                font.family: Theme.fontFamily
                            }
                        }

                        MouseArea {
                            id: smartMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.name === "Inbox") {
                                    taskListViewModel.setFilterList("Inbox")
                                } else if (modelData.name !== "Summary") {
                                    taskListViewModel.setFilterDate(modelData.name)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#363636"
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Lists"
                        color: "#777777"
                        font.pixelSize: 12
                        font.bold: true
                        font.family: Theme.fontFamily
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: usedText.width + 10
                        height: 18
                        radius: 4
                        color: "#333333"

                        Text {
                            id: usedText
                            anchors.centerIn: parent
                            text: {
                                root.refreshRevision
                                return "Used: " + taskListViewModel.getVisibleLists().length
                            }
                            color: "#9a9a9a"
                            font.pixelSize: 10
                            font.family: Theme.fontFamily
                        }
                    }

                    Text {
                        text: "+"
                        color: "#bdbdbd"
                        font.pixelSize: 18
                        font.bold: true
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            cursorShape: Qt.PointingHandCursor
                            onClicked: openCenteredPopup(newListPopup)
                        }
                    }
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(210, contentColumn.height + 4)
                    clip: true

                    ColumnLayout {
                        id: contentColumn
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: {
                                root.refreshRevision
                                return taskListViewModel.getRootLists()
                            }

                            delegate: SidebarListRow {
                                listName: modelData
                            }
                        }

                        Repeater {
                            model: {
                                root.refreshRevision
                                return taskListViewModel.getAllFolders()
                            }

                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 30
                                    radius: 7
                                    color: "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 12
                                        spacing: 8

                                        Text {
                                            text: "⌄"
                                            color: "#858585"
                                            font.pixelSize: 12
                                        }

                                        SidebarIcon {
                                            Layout.preferredWidth: 16
                                            Layout.preferredHeight: 16
                                            iconName: "folder"
                                            iconColor: "#dcdcdc"
                                            strokeWidth: 1.5
                                        }

                                        Text {
                                            text: modelData
                                            color: "#f5f5f5"
                                            font.pixelSize: 14
                                            font.family: Theme.fontFamily
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                Repeater {
                                    model: taskListViewModel.getListsForFolder(modelData)
                                    delegate: SidebarListRow {
                                        listName: modelData
                                        indent: 22
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    text: "Filters"
                    color: "#777777"
                    font.pixelSize: 12
                    font.bold: true
                    font.family: Theme.fontFamily
                    Layout.topMargin: 6
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 50
                    radius: 6
                    color: "#2c2c2c"

                    Text {
                        anchors.fill: parent
                        anchors.margins: 12
                        text: "Display tasks filtered by list, date, priority, tag, and more"
                        color: "#858585"
                        wrapMode: Text.WordWrap
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 8

                    Text {
                        text: "Tags"
                        color: "#777777"
                        font.pixelSize: 12
                        font.bold: true
                        font.family: Theme.fontFamily
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "+"
                        color: "#bdbdbd"
                        font.pixelSize: 18
                        font.bold: true
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            cursorShape: Qt.PointingHandCursor
                            onClicked: openCenteredPopup(newTagPopup)
                        }
                    }
                }

                Repeater {
                    model: {
                        root.refreshRevision
                        return taskListViewModel.getAllTags()
                    }

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        radius: 7
                        color: tagFilterMouse.containsMouse ? "#2b2b2b" : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            SidebarIcon {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                iconName: "tag"
                                iconColor: "#f5f5f5"
                                strokeWidth: 1.6
                            }

                            Text {
                                text: modelData
                                color: "#f5f5f5"
                                font.pixelSize: 14
                                font.family: Theme.fontFamily
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: getTagColor(modelData)
                            }

                            Text {
                                text: {
                                    root.refreshRevision
                                    return taskListViewModel.getTagTaskCount(modelData)
                                }
                                color: "#858585"
                                font.pixelSize: 11
                                font.family: Theme.fontFamily
                            }
                        }

                        MouseArea {
                            id: tagFilterMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: taskListViewModel.setFilterTag(modelData)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#363636"
                    Layout.topMargin: 8
                    Layout.bottomMargin: 6
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 7
                    color: completedMouse.containsMouse || taskListViewModel.activeFilterDate === "Completed" ? "#2b2b2b" : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        SidebarIcon {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            iconName: "completed"
                            iconColor: "#f5f5f5"
                            strokeWidth: 1.6
                        }
                        Text {
                            text: "Completed"
                            color: "#f5f5f5"
                            font.pixelSize: 14
                            font.family: Theme.fontFamily
                            Layout.fillWidth: true
                        }
                        Text {
                            text: {
                                root.refreshRevision
                                return taskListViewModel.getCompletedTaskCount()
                            }
                            color: "#858585"
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: completedMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: taskListViewModel.setFilterDate("Completed")
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 7
                    color: trashMouse.containsMouse ? "#2b2b2b" : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        SidebarIcon {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            iconName: "trash"
                            iconColor: "#f5f5f5"
                            strokeWidth: 1.6
                        }
                        Text {
                            text: "Trash"
                            color: "#f5f5f5"
                            font.pixelSize: 14
                            font.family: Theme.fontFamily
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: trashMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    color: "#2b2b2b"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 8

                        SidebarIcon {
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            iconName: "premium"
                            iconColor: "#686868"
                            strokeWidth: 1.5
                        }
                        Text {
                            text: "Upgrade to Premium"
                            color: "#858585"
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                            Layout.fillWidth: true
                        }
                        Text { text: "›"; color: "#686868"; font.pixelSize: 14 }
                    }
                }
            }
        }
    }

    function getTaskCount(filterName) {
        root.refreshRevision
        switch(filterName) {
            case "All": return taskListViewModel.getAllTaskCount()
            case "Today": return taskListViewModel.getTodayCount()
            case "Next 7 Days": return taskListViewModel.getNext7DaysCount()
            case "Inbox": return taskListViewModel.getListTaskCount("Inbox")
            default: return ""
        }
    }

    function getTagColor(tagName) {
        var savedColor = taskListViewModel.getSavedTagColor(tagName)
        if (savedColor !== "") return savedColor

        var colors = ["#e83d3d", "#eb8a23", "#e0e72c", "#2ef02a", "#4b6fff", "#bb68ef", "#eb68aa"]
        var hash = 0
        for (var i = 0; i < tagName.length; i++) {
            hash = tagName.charCodeAt(i) + ((hash << 5) - hash)
        }
        return colors[Math.abs(hash) % colors.length]
    }

    Popup {
        id: accountPopup
        parent: Overlay.overlay
        modal: false
        width: 220
        padding: 14
        x: 58
        y: 8
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#252525"
            radius: 8
            border.color: "#3b3b3b"
            border.width: 1
        }

        ColumnLayout {
            width: parent.width
            spacing: 10

            Text {
                text: "TaskHub Account"
                color: "#f5f5f5"
                font.pixelSize: 14
                font.bold: true
                font.family: Theme.fontFamily
            }

            Button {
                text: "Sign out"
                Layout.fillWidth: true
                onClicked: {
                    accountPopup.close()
                    authService.logout()
                }
            }
        }
    }

    Popup {
        id: notificationsPopup
        parent: Overlay.overlay
        modal: false
        width: 250
        padding: 14
        x: 58
        y: root.height - 112
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#252525"
            radius: 8
            border.color: "#3b3b3b"
            border.width: 1
        }

        Text {
            width: parent.width
            text: "No notifications"
            color: "#b8b8b8"
            font.pixelSize: 13
            font.family: Theme.fontFamily
        }
    }

    Popup {
        id: helpPopup
        parent: Overlay.overlay
        modal: false
        width: 280
        padding: 14
        x: 58
        y: root.height - 72
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#252525"
            radius: 8
            border.color: "#3b3b3b"
            border.width: 1
        }

        Text {
            width: parent.width
            text: "Tasks opens the second sidebar. Calendar, Matrix, Pomodoro, Habit, and Search open full workspace views."
            color: "#b8b8b8"
            wrapMode: Text.WordWrap
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }
    }

    Popup {
        id: newListPopup
        parent: Overlay.overlay
        modal: true
        width: 740
        height: 426
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        property string selectedColor: "#3b82f6"
        property string selectedFolder: "None"
        property string selectedListType: "Task List"

        Overlay.modal: Rectangle {
            color: "#88000000"
        }

        onOpened: {
            newListInput.text = ""
            selectedFolder = "None"
            selectedListType = "Task List"
            newListInput.forceActiveFocus()
        }

        background: Rectangle {
            color: "#252525"
            radius: 14
            border.color: "#3b3b3b"
            border.width: 1
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            ColumnLayout {
                Layout.preferredWidth: 380
                Layout.fillHeight: true
                Layout.margins: 26
                spacing: 16

                Text {
                    text: "Add List"
                    color: "#f5f5f5"
                    font.pixelSize: 18
                    font.bold: true
                    font.family: Theme.fontFamily
                    Layout.alignment: Qt.AlignHCenter
                }

                TextField {
                    id: newListInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    placeholderText: "Name"
                    color: "#f5f5f5"
                    placeholderTextColor: "#777777"
                    leftPadding: 42
                    font.family: Theme.fontFamily
                    background: Rectangle {
                        color: "#1b1b1b"
                        radius: 8
                        border.color: "#3b3b3b"
                        border.width: 1

                        SidebarIcon {
                            anchors.left: parent.left
                            anchors.leftMargin: 13
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            iconName: "list"
                            iconColor: "#858585"
                            strokeWidth: 1.6
                        }
                    }
                    onAccepted: newListPopup.createList()
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14
                    Text {
                        text: "List Color"
                        color: "#dcdcdc"
                        font.pixelSize: 13
                        font.family: Theme.fontFamily
                        Layout.preferredWidth: 92
                    }
                    RowLayout {
                        spacing: 8
                        Repeater {
                            model: root.pickerColors
                            delegate: Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                color: modelData
                                border.color: newListPopup.selectedColor === modelData ? "#ffffff" : "transparent"
                                border.width: 2
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: newListPopup.selectedColor = modelData
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14
                    Text { text: "View Type"; color: "#dcdcdc"; font.pixelSize: 13; font.family: Theme.fontFamily; Layout.preferredWidth: 92 }
                    Repeater {
                        model: [
                            { iconName: "all", premium: false },
                            { iconName: "matrix", premium: false },
                            { iconName: "summary", premium: true }
                        ]
                        delegate: Rectangle {
                            width: 52
                            height: 38
                            radius: 8
                            color: index === 0 ? Theme.primary + "22" : "#2b2b2b"
                            border.color: index === 0 ? Theme.primary : "transparent"
                            SidebarIcon {
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                iconName: modelData.iconName
                                iconColor: index === 0 ? Theme.primary : "#8e8e8e"
                                strokeWidth: 1.7
                            }
                            Rectangle {
                                visible: modelData.premium
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: -3
                                width: 12
                                height: 12
                                radius: 6
                                color: "#facc15"
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14
                    Text { text: "Folder"; color: "#dcdcdc"; font.pixelSize: 13; font.family: Theme.fontFamily; Layout.preferredWidth: 92 }
                    SidebarComboBox {
                        id: newListFolderCombo
                        Layout.fillWidth: true
                        model: root.folderOptions()
                        currentIndex: Math.max(0, root.folderOptions().indexOf(newListPopup.selectedFolder))
                        onActivated: {
                            if (currentText === "+ New Folder") {
                                currentIndex = Math.max(0, root.folderOptions().indexOf(newListPopup.selectedFolder))
                                openCenteredPopup(newFolderPopup)
                            } else {
                                newListPopup.selectedFolder = currentText
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14
                    Text { text: "List Type"; color: "#dcdcdc"; font.pixelSize: 13; font.family: Theme.fontFamily; Layout.preferredWidth: 92 }
                    SidebarComboBox {
                        Layout.fillWidth: true
                        model: ["Task List", "Notes List"]
                        currentIndex: newListPopup.selectedListType === "Notes List" ? 1 : 0
                        onActivated: newListPopup.selectedListType = currentText
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14
                    Text { text: "Show in Smart List"; color: "#dcdcdc"; font.pixelSize: 13; font.family: Theme.fontFamily; Layout.preferredWidth: 130 }
                    SidebarComboBox { Layout.fillWidth: true; model: ["All tasks", "No"] }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 76
                        height: 30
                        radius: 7
                        color: cancelNewListHover.containsMouse ? "#333333" : "transparent"
                        border.color: "#3b3b3b"
                        Text { anchors.centerIn: parent; text: "Cancel"; color: "#bdbdbd"; font.pixelSize: 13; font.family: Theme.fontFamily }
                        HoverHandler { id: cancelNewListHover }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: newListPopup.close() }
                    }
                    Rectangle {
                        width: 76
                        height: 30
                        radius: 7
                        color: newListInput.text.trim() === "" ? "#303030" : Theme.primary
                        opacity: newListInput.text.trim() === "" ? 0.65 : 1
                        Text { anchors.centerIn: parent; text: "Add"; color: "#ffffff"; font.pixelSize: 13; font.family: Theme.fontFamily }
                        MouseArea { anchors.fill: parent; cursorShape: newListInput.text.trim() === "" ? Qt.ArrowCursor : Qt.PointingHandCursor; onClicked: newListPopup.createList() }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#202020"
                radius: 0
                clip: true
                Rectangle {
                    anchors.centerIn: parent
                    width: 270
                    height: 300
                    radius: 12
                    color: "#242424"
                    opacity: 0.9
                    border.color: "#2f2f2f"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            SidebarIcon { Layout.preferredWidth: 16; Layout.preferredHeight: 16; iconName: "list"; iconColor: newListPopup.selectedColor }
                            Text { text: newListInput.text.trim() === "" ? "Name" : newListInput.text.trim(); color: "#dcdcdc"; font.pixelSize: 13; font.family: Theme.fontFamily; Layout.fillWidth: true; elide: Text.ElideRight }
                        }
                        Rectangle { Layout.fillWidth: true; height: 14; radius: 4; color: "#303030" }
                        Repeater {
                            model: 8
                            Rectangle {
                                Layout.fillWidth: true
                                height: 8
                                radius: 4
                                color: index % 3 === 0 ? newListPopup.selectedColor : "#343434"
                                opacity: index % 3 === 0 ? 0.9 : 1
                            }
                        }
                    }
                }
            }
        }

        function createList() {
            var name = newListInput.text.trim()
            if (name === "") return
            taskListViewModel.createList(name, newListPopup.selectedColor, newListPopup.selectedFolder === "None" ? "" : newListPopup.selectedFolder, newListPopup.selectedListType)
            taskListViewModel.setFilterList(name)
            newListInput.text = ""
            newListPopup.close()
        }
    }

    Popup {
        id: newFolderPopup
        parent: Overlay.overlay
        modal: true
        width: 320
        height: 168
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        Overlay.modal: Rectangle {
            color: "#88000000"
        }

        onOpened: {
            newFolderInput.text = ""
            newFolderInput.forceActiveFocus()
        }

        background: Rectangle {
            color: "#252525"
            radius: 12
            border.color: "#3b3b3b"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            Text {
                text: "New Folder"
                color: "#f5f5f5"
                font.pixelSize: 17
                font.bold: true
                font.family: Theme.fontFamily
            }

            TextField {
                id: newFolderInput
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                placeholderText: "Folder name"
                color: "#f5f5f5"
                placeholderTextColor: "#777777"
                font.family: Theme.fontFamily
                background: Rectangle {
                    radius: 7
                    color: "#303030"
                    border.color: "#3b3b3b"
                }
                onAccepted: newFolderPopup.createFolder()
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 76
                    height: 30
                    radius: 7
                    color: folderCancelHover.containsMouse ? "#333333" : "transparent"
                    border.color: "#3b3b3b"
                    Text { anchors.centerIn: parent; text: "Cancel"; color: "#bdbdbd"; font.pixelSize: 13; font.family: Theme.fontFamily }
                    HoverHandler { id: folderCancelHover }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: newFolderPopup.close() }
                }
                Rectangle {
                    width: 76
                    height: 30
                    radius: 7
                    color: newFolderInput.text.trim() === "" ? "#303030" : Theme.primary
                    opacity: newFolderInput.text.trim() === "" ? 0.65 : 1
                    Text { anchors.centerIn: parent; text: "Add"; color: "#ffffff"; font.pixelSize: 13; font.family: Theme.fontFamily }
                    MouseArea { anchors.fill: parent; cursorShape: newFolderInput.text.trim() === "" ? Qt.ArrowCursor : Qt.PointingHandCursor; onClicked: newFolderPopup.createFolder() }
                }
            }
        }

        function createFolder() {
            var name = newFolderInput.text.trim()
            if (name === "") return
            taskListViewModel.createFolder(name)
            newListPopup.selectedFolder = name
            newFolderInput.text = ""
            newFolderPopup.close()
        }
    }

    Popup {
        id: newTagPopup
        parent: Overlay.overlay
        modal: true
        width: 382
        height: 286
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        property string selectedColor: "#bb68ef"

        Overlay.modal: Rectangle {
            color: "#88000000"
        }

        onOpened: {
            newTagInput.text = ""
            newTagParent.currentIndex = 0
            newTagInput.forceActiveFocus()
        }

        background: Rectangle {
            color: "#252525"
            radius: 14
            border.color: "#3b3b3b"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Add Tags"
                    color: "#f5f5f5"
                    font.pixelSize: 17
                    font.bold: true
                    font.family: Theme.fontFamily
                    Layout.fillWidth: true
                }
                Text {
                    text: "×"
                    color: "#bdbdbd"
                    font.pixelSize: 22
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: newTagPopup.close()
                    }
                }
            }

            TextField {
                id: newTagInput
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                placeholderText: "Name"
                color: "#f5f5f5"
                placeholderTextColor: "#777777"
                font.family: Theme.fontFamily
                background: Rectangle {
                    color: "#303030"
                    radius: 7
                    border.color: "#303030"
                }
                onAccepted: newTagPopup.createTag()
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 18
                Text { text: "Color"; color: "#f5f5f5"; font.pixelSize: 13; font.family: Theme.fontFamily; Layout.preferredWidth: 62 }
                RowLayout {
                    spacing: 9
                    Repeater {
                        model: root.pickerColors
                        delegate: Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: modelData
                            border.color: newTagPopup.selectedColor === modelData ? "#ffffff" : "transparent"
                            border.width: 2
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: newTagPopup.selectedColor = modelData
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 18
                Text { text: "Parent Tag"; color: "#f5f5f5"; font.pixelSize: 13; font.family: Theme.fontFamily; Layout.preferredWidth: 62 }
                SidebarComboBox {
                    id: newTagParent
                    Layout.fillWidth: true
                    model: {
                        root.refreshRevision
                        return ["None"].concat(taskListViewModel.getAllTags())
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 100
                    height: 30
                    radius: 7
                    color: cancelNewTagHover.containsMouse ? "#333333" : "transparent"
                    border.color: "#3b3b3b"
                    Text { anchors.centerIn: parent; text: "Close"; color: "#bdbdbd"; font.pixelSize: 13; font.family: Theme.fontFamily }
                    HoverHandler { id: cancelNewTagHover }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: newTagPopup.close() }
                }
                Rectangle {
                    width: 100
                    height: 30
                    radius: 7
                    color: newTagInput.text.trim() === "" ? "#303030" : Theme.primary
                    opacity: newTagInput.text.trim() === "" ? 0.65 : 1
                    Text { anchors.centerIn: parent; text: "Save"; color: "#ffffff"; font.pixelSize: 13; font.family: Theme.fontFamily }
                    MouseArea { anchors.fill: parent; cursorShape: newTagInput.text.trim() === "" ? Qt.ArrowCursor : Qt.PointingHandCursor; onClicked: newTagPopup.createTag() }
                }
            }
        }

        function createTag() {
            var name = newTagInput.text.trim()
            if (name === "") return
            var parentName = newTagParent.currentText === "None" ? "" : newTagParent.currentText
            taskListViewModel.createTag(name, newTagPopup.selectedColor, parentName)
            newTagInput.text = ""
            newTagPopup.close()
        }
    }
}

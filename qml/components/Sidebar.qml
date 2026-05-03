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
    property string contextMenuType: "list" // "list" | "folder"
    property string contextMenuListName: ""
    property string contextMenuFolderName: ""
    property string contextMenuTargetKey: ""
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

    function openContextMenu(anchorItem, type, name, mouse) {
        if (!Overlay.overlay || !anchorItem) return
        contextMenuType = type
        if (type === "list") {
            contextMenuListName = name
            contextMenuFolderName = ""
            contextMenuTargetKey = "list:" + name
        } else {
            contextMenuFolderName = name
            contextMenuListName = ""
            contextMenuTargetKey = "folder:" + name
        }

        listContextMenu.close()
        var pos = mouse
            ? anchorItem.mapToItem(Overlay.overlay, mouse.x, mouse.y)
            : anchorItem.mapToItem(Overlay.overlay, 0, anchorItem.height)
        var x = pos.x
        var y = pos.y
        if (x + listContextMenu.implicitWidth > Overlay.overlay.width - 12)
            x = Overlay.overlay.width - listContextMenu.implicitWidth - 12
        if (y + listContextMenu.implicitHeight > Overlay.overlay.height - 12)
            y = Overlay.overlay.height - listContextMenu.implicitHeight - 12
        if (x < 12) x = 12
        if (y < 12) y = 12
        listContextMenu.x = x
        listContextMenu.y = y
        listContextMenu.open()
    }

    function openRenamePopup(type, name) {
        renamePopup.targetType = type
        renamePopup.oldName = name
        renameInput.text = name
        renamePopup.open()
        renameInput.forceActiveFocus()
    }

    function normalizeFolderName(name) {
        var folders = taskListViewModel.getAllFolders()
        for (var i = 0; i < folders.length; i++) {
            if (folders[i] === name) return name
        }
        return "None"
    }

    function syncNewListFolder() {
        newListPopup.selectedFolder = normalizeFolderName(newListPopup.selectedFolder)
    }

    function listMenuItems() {
        root.refreshRevision
        var pinned = taskListViewModel.getListPinned(contextMenuListName)
        var archived = taskListViewModel.getListArchived(contextMenuListName)
        return [
            "Edit",
            pinned ? "Unpin" : "Pin",
            "Duplicate",
            "Share",
            archived ? "Unarchive" : "Archive",
            "Delete"
        ]
    }

    function folderMenuItems() {
        root.refreshRevision
        var pinned = taskListViewModel.getFolderPinned(contextMenuFolderName)
        return [
            "Add List",
            "Edit",
            pinned ? "Unpin" : "Pin",
            "Duplicate",
            "Ungroup"
        ]
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
        property bool hoverActive: listMouse.containsMouse || menuBtnHover.containsMouse ||
                                   (listContextMenu.visible && root.contextMenuTargetKey === "list:" + listRow.listName)
        property bool isPinned: {
            root.refreshRevision
            return taskListViewModel.getListPinned(listRow.listName)
        }
        Layout.fillWidth: true
        height: 34
        radius: 7
        color: taskListViewModel.activeFilterList === listName ? "#343434" : (hoverActive ? "#2b2b2b" : "transparent")

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12 + listRow.indent
            anchors.rightMargin: 36
            spacing: 8

            SidebarIcon {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                iconName: taskListViewModel.getListType(listRow.listName) === "Notes List" ? "summary" : "list"
                iconColor: taskListViewModel.getListType(listRow.listName) === "Notes List" ? "#a78bfa" : "#f5f5f5"
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

            Text {
                visible: listRow.isPinned
                text: "📌"
                color: "#bdbdbd"
                font.pixelSize: 12
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
                visible: !listRow.hoverActive
            }
        }

        MouseArea {
            id: listMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    openContextMenu(menuButton, "list", listRow.listName, mouse)
                } else {
                    taskListViewModel.setFilterList(listRow.listName)
                }
            }
        }

        Rectangle {
            id: menuButton
            width: 24
            height: 24
            radius: 6
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            color: menuBtnHover.containsMouse ? "#2a2a2a" : "transparent"
            visible: listRow.hoverActive

            Text {
                anchors.centerIn: parent
                text: "..."
                color: "#9a9a9a"
                font.pixelSize: 14
            }

            HoverHandler { id: menuBtnHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: openContextMenu(menuButton, "list", listRow.listName)
            }
        }
    }

    Connections {
        target: taskListViewModel
        function onFilterChanged() {
            root.refreshRevision++
            syncNewListFolder()
        }
        function onTasksModified() {
            root.refreshRevision++
            syncNewListFolder()
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
                                var all = taskListViewModel.getAllFolders()
                                var filtered = []
                                for (var i = 0; i < all.length; i++) {
                                    if (all[i] !== "Archive") filtered.push(all[i])
                                }
                                return filtered
                            }

                            delegate: ColumnLayout {
                                property string folderName: modelData
                                property bool folderPinned: {
                                    root.refreshRevision
                                    return taskListViewModel.getFolderPinned(folderName)
                                }
                                property bool folderHoverActive: folderMouse.containsMouse || folderMenuHover.containsMouse ||
                                    (listContextMenu.visible && root.contextMenuTargetKey === "folder:" + folderName)
                                Layout.fillWidth: true
                                spacing: 2

                                Rectangle {
                                    id: folderRow
                                    Layout.fillWidth: true
                                    height: 30
                                    radius: 7
                                    color: folderHoverActive ? "#2b2b2b" : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 36
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

                                        Text {
                                            visible: folderPinned
                                            text: "📌"
                                            color: "#bdbdbd"
                                            font.pixelSize: 11
                                        }
                                    }

                                    MouseArea {
                                        id: folderMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: function(mouse) {
                                            if (mouse.button === Qt.RightButton) {
                                                openContextMenu(folderMenuButton, "folder", folderName, mouse)
                                            }
                                        }
                                    }

                                    Rectangle {
                                        id: folderMenuButton
                                        width: 22
                                        height: 22
                                        radius: 6
                                        anchors.right: parent.right
                                        anchors.rightMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: folderMenuHover.containsMouse ? "#2a2a2a" : "transparent"
                                        visible: folderHoverActive

                                        Text {
                                            anchors.centerIn: parent
                                            text: "..."
                                            color: "#9a9a9a"
                                            font.pixelSize: 13
                                        }

                                        HoverHandler { id: folderMenuHover }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: openContextMenu(folderMenuButton, "folder", folderName)
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

                        ColumnLayout {
                            property bool hasArchive: {
                                root.refreshRevision
                                return taskListViewModel.getAllFolders().indexOf("Archive") !== -1
                            }
                            visible: hasArchive
                            Layout.fillWidth: true
                            spacing: 2
                            Layout.topMargin: 8

                            Rectangle {
                                id: archiveRow
                                Layout.fillWidth: true
                                height: 30
                                radius: 7
                                color: archiveHoverActive ? "#2b2b2b" : "transparent"

                                property bool archivePinned: {
                                    root.refreshRevision
                                    return taskListViewModel.getFolderPinned("Archive")
                                }
                                property bool archiveHoverActive: archiveMouse.containsMouse || archiveMenuHover.containsMouse ||
                                    (listContextMenu.visible && root.contextMenuTargetKey === "folder:Archive")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 36
                                    spacing: 8

                                    Text { text: "⌄"; color: "#858585"; font.pixelSize: 12 }

                                    SidebarIcon {
                                        Layout.preferredWidth: 16
                                        Layout.preferredHeight: 16
                                        iconName: "archive"
                                        iconColor: "#dcdcdc"
                                        strokeWidth: 1.5
                                    }

                                    Text {
                                        text: "Archive"
                                        color: "#f5f5f5"
                                        font.pixelSize: 14
                                        font.family: Theme.fontFamily
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        visible: archivePinned
                                        text: "📌"
                                        color: "#bdbdbd"
                                        font.pixelSize: 11
                                    }
                                }

                                MouseArea {
                                    id: archiveMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                        onClicked: function(mouse) {
                                            if (mouse.button === Qt.RightButton) {
                                                openContextMenu(archiveMenuButton, "folder", "Archive", mouse)
                                            }
                                        }
                                }

                                Rectangle {
                                    id: archiveMenuButton
                                    width: 22
                                    height: 22
                                    radius: 6
                                    anchors.right: parent.right
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: archiveMenuHover.containsMouse ? "#2a2a2a" : "transparent"
                                    visible: archiveHoverActive

                                    Text {
                                        anchors.centerIn: parent
                                        text: "..."
                                        color: "#9a9a9a"
                                        font.pixelSize: 13
                                    }

                                    HoverHandler { id: archiveMenuHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: openContextMenu(archiveMenuButton, "folder", "Archive")
                                    }
                                }
                            }

                            Repeater {
                                model: taskListViewModel.getListsForFolder("Archive")
                                delegate: SidebarListRow {
                                    listName: modelData
                                    indent: 22
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
        id: listContextMenu
        parent: Overlay.overlay
        modal: false
        padding: 6
        z: 5000
        implicitWidth: 190
        implicitHeight: menuColumn.implicitHeight + padding * 2
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#1f1f1f"
            radius: 8
            border.color: "#2f2f2f"
            border.width: 1
        }

        ColumnLayout {
            id: menuColumn
            width: 180
            spacing: 2

            Repeater {
                model: root.contextMenuType === "folder"
                    ? folderMenuItems()
                    : listMenuItems()

                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 6
                    color: menuItemHover.containsMouse ? "#2a2a2a" : "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        text: modelData
                        color: modelData === "Delete" ? Theme.accentRed : "#e0e0e0"
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                    }

                    HoverHandler { id: menuItemHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.contextMenuType === "folder") {
                                if (modelData === "Add List") {
                                    newListPopup.initialFolder = normalizeFolderName(root.contextMenuFolderName)
                                    openCenteredPopup(newListPopup)
                                } else if (modelData === "Edit") {
                                    openRenamePopup("folder", root.contextMenuFolderName)
                                } else if (modelData === "Pin" || modelData === "Unpin") {
                                    var pinFolder = modelData === "Pin"
                                    taskListViewModel.pinFolder(root.contextMenuFolderName, pinFolder)
                                } else if (modelData === "Duplicate") {
                                    taskListViewModel.duplicateFolder(root.contextMenuFolderName)
                                } else if (modelData === "Ungroup") {
                                    taskListViewModel.ungroupFolder(root.contextMenuFolderName)
                                }
                            } else {
                                if (modelData === "Edit") {
                                    openRenamePopup("list", root.contextMenuListName)
                                } else if (modelData === "Pin" || modelData === "Unpin") {
                                    var pinList = modelData === "Pin"
                                    taskListViewModel.pinList(root.contextMenuListName, pinList)
                                } else if (modelData === "Duplicate") {
                                    taskListViewModel.duplicateList(root.contextMenuListName)
                                } else if (modelData === "Share") {
                                    if (Qt.application && Qt.application.clipboard) {
                                        Qt.application.clipboard.setText(root.contextMenuListName)
                                    }
                                } else if (modelData === "Archive" || modelData === "Unarchive") {
                                    taskListViewModel.archiveList(root.contextMenuListName)
                                } else if (modelData === "Delete") {
                                    taskListViewModel.deleteList(root.contextMenuListName)
                                }
                            }
                            listContextMenu.close()
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: renamePopup
        parent: Overlay.overlay
        modal: true
        width: 320
        height: 160
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property string targetType: "list"
        property string oldName: ""

        Overlay.modal: Rectangle { color: "#88000000" }

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
                text: renamePopup.targetType === "folder" ? "Rename Folder" : "Rename List"
                color: "#f5f5f5"
                font.pixelSize: 16
                font.bold: true
                font.family: Theme.fontFamily
            }

            TextField {
                id: renameInput
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                placeholderText: renamePopup.targetType === "folder" ? "Folder name" : "List name"
                color: "#f5f5f5"
                placeholderTextColor: "#777777"
                font.family: Theme.fontFamily
                background: Rectangle {
                    radius: 7
                    color: "#303030"
                    border.color: "#3b3b3b"
                }
                onAccepted: renameConfirm.clicked()
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 76
                    height: 30
                    radius: 7
                    color: renameCancelHover.containsMouse ? "#333333" : "transparent"
                    border.color: "#3b3b3b"
                    Text { anchors.centerIn: parent; text: "Cancel"; color: "#bdbdbd"; font.pixelSize: 13; font.family: Theme.fontFamily }
                    HoverHandler { id: renameCancelHover }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: renamePopup.close() }
                }
                Rectangle {
                    id: renameConfirm
                    width: 76
                    height: 30
                    radius: 7
                    color: renameInput.text.trim() === "" ? "#303030" : Theme.primary
                    opacity: renameInput.text.trim() === "" ? 0.65 : 1
                    Text { anchors.centerIn: parent; text: "Save"; color: "#ffffff"; font.pixelSize: 13; font.family: Theme.fontFamily }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: renameInput.text.trim() === "" ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onClicked: {
                            var newName = renameInput.text.trim()
                            if (newName === "") return
                            if (renamePopup.targetType === "folder") {
                                taskListViewModel.renameFolder(renamePopup.oldName, newName)
                            } else {
                                taskListViewModel.renameList(renamePopup.oldName, newName)
                            }
                            renamePopup.close()
                        }
                    }
                }
            }
        }
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
        width: 520
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        // State
        property string selectedColor: ""        // "" = none/default
        property string selectedFolder: "None"
        property string initialFolder: "None"
        property string selectedListType: "Task List"  // "Task List" | "Notes List"
        property int    selectedViewType: 0            // 0=List 1=Board 2=Timeline
        property string selectedSmartList: "All tasks" // "All tasks" | "No"
        property string selectedIcon: "≡"             // emoji or symbol
        property bool   showIconPicker: false

        Overlay.modal: Rectangle { color: "#99000000" }

        onOpened: {
            newListNameInput.text = ""
            selectedColor = ""
            selectedFolder = normalizeFolderName(initialFolder)
            initialFolder = "None"
            selectedListType = "Task List"
            selectedViewType = 0
            selectedSmartList = "All tasks"
            selectedIcon = "≡"
            showIconPicker = false
            newListNameInput.forceActiveFocus()
        }

        background: Rectangle {
            color: "#252628"
            radius: 14
            border.color: "#383838"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 0

            // ── Header ──────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 52
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 22

                    Text {
                        text: "Add List"
                        color: "#f0f0f0"
                        font.pixelSize: 16
                        font.bold: true
                        font.family: Theme.fontFamily
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 26; height: 26; radius: 13
                        color: closeBtnHover.containsMouse ? "#383838" : "transparent"
                        Text { anchors.centerIn: parent; text: "×"; color: "#aaaaaa"; font.pixelSize: 18 }
                        HoverHandler { id: closeBtnHover }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: newListPopup.close() }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#333333" }

            // ── Two-column body ─────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                // LEFT: form
                ColumnLayout {
                    Layout.preferredWidth: 280
                    Layout.fillHeight: true
                    Layout.margins: 20
                    spacing: 14

                    // Name row: icon picker + text field
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Icon button
                        Rectangle {
                            width: 36; height: 36; radius: 8
                            color: iconBtnHover.containsMouse ? "#333333" : "#2a2a2a"
                            border.color: newListPopup.showIconPicker ? Theme.primary : "#3a3a3a"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: newListPopup.selectedIcon
                                font.pixelSize: 16
                                color: newListPopup.selectedColor !== "" ? newListPopup.selectedColor : "#cccccc"
                            }

                            HoverHandler { id: iconBtnHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: newListPopup.showIconPicker = !newListPopup.showIconPicker
                            }
                        }

                        // Name input
                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 8
                            color: "#1e1e1e"
                            border.color: newListNameInput.activeFocus ? Theme.primary : "#3a3a3a"
                            border.width: 1

                            TextField {
                                id: newListNameInput
                                anchors.fill: parent
                                anchors.margins: 8
                                placeholderText: "List name"
                                color: "#f0f0f0"
                                placeholderTextColor: "#666666"
                                font.pixelSize: 13
                                font.family: Theme.fontFamily
                                background: null
                                onAccepted: newListPopup.createList()
                            }
                        }
                    }

                    // Icon picker panel
                    Rectangle {
                        Layout.fillWidth: true
                        height: newListPopup.showIconPicker ? iconPickerCol.implicitHeight + 16 : 0
                        visible: newListPopup.showIconPicker
                        color: "#1e1e1e"
                        radius: 10
                        border.color: "#333333"
                        clip: true

                        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        ColumnLayout {
                            id: iconPickerCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 8

                            // Symbol row
                            Flow {
                                Layout.fillWidth: true
                                spacing: 4

                                Repeater {
                                    model: ["≡", "★", "♥", "⚡", "🎯", "📚", "💡", "🔧", "🎨", "🏆",
                                            "📝", "💼", "🏠", "🎵", "🌟", "💪", "🚀", "🎮", "🌈", "🔥",
                                            "💰", "🏋️", "✈️", "🌿", "🎭", "📊", "🔬", "🎓", "🏃", "💻"]

                                    Rectangle {
                                        width: 32; height: 32; radius: 6
                                        color: newListPopup.selectedIcon === modelData
                                            ? (newListPopup.selectedColor !== "" ? newListPopup.selectedColor + "33" : Theme.primary + "33")
                                            : (iconItemHover.containsMouse ? "#2e2e2e" : "transparent")
                                        border.color: newListPopup.selectedIcon === modelData
                                                    ? (newListPopup.selectedColor !== "" ? newListPopup.selectedColor : Theme.primary)
                                                    : "transparent"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: 15
                                            color: "#eeeeee"
                                        }

                                        HoverHandler { id: iconItemHover }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                newListPopup.selectedIcon = modelData
                                                newListPopup.showIconPicker = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // List Color
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "Color"
                            color: "#999999"
                            font.pixelSize: 12
                            font.family: Theme.fontFamily
                            Layout.preferredWidth: 72
                        }

                        Row {
                            spacing: 6

                            // "None" slot
                            Rectangle {
                                width: 20; height: 20; radius: 10
                                color: "#2a2a2a"
                                border.color: newListPopup.selectedColor === "" ? "#ffffff" : "#555555"
                                border.width: newListPopup.selectedColor === "" ? 2 : 1

                                Text { anchors.centerIn: parent; text: "×"; color: "#777777"; font.pixelSize: 12 }

                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: newListPopup.selectedColor = ""
                                }
                            }

                            Repeater {
                                model: ["#ef4444","#fb923c","#facc15","#4ade80","#22c55e",
                                        "#3b82f6","#6366f1","#a855f7","#ec4899","#f43f5e"]

                                Rectangle {
                                    width: 20; height: 20; radius: 10
                                    color: modelData
                                    border.color: newListPopup.selectedColor === modelData ? "#ffffff" : "transparent"
                                    border.width: 2

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 8; height: 8; radius: 4
                                        color: "white"
                                        visible: newListPopup.selectedColor === modelData
                                        opacity: 0.9
                                    }

                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: newListPopup.selectedColor = modelData
                                    }
                                }
                            }
                        }
                    }

                    // View Type
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "View"
                            color: "#999999"
                            font.pixelSize: 12
                            font.family: Theme.fontFamily
                            Layout.preferredWidth: 72
                        }

                        Row {
                            spacing: 6

                            Repeater {
                                model: [
                                    { label: "List",     icon: "all",     idx: 0 },
                                    { label: "Board",    icon: "matrix",  idx: 1 },
                                    { label: "Timeline", icon: "summary", idx: 2 }
                                ]

                                Rectangle {
                                    width: 64; height: 44; radius: 8
                                    color: newListPopup.selectedViewType === modelData.idx
                                        ? (newListPopup.selectedColor !== "" ? newListPopup.selectedColor + "22" : Theme.primary + "22")
                                        : (viewHover.containsMouse ? "#2a2a2a" : "#222222")
                                    border.color: newListPopup.selectedViewType === modelData.idx
                                                ? (newListPopup.selectedColor !== "" ? newListPopup.selectedColor : Theme.primary)
                                                : "#333333"
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 3

                                        SidebarIcon {
                                            Layout.alignment: Qt.AlignHCenter
                                            width: 16; height: 16
                                            iconName: modelData.icon
                                            iconColor: newListPopup.selectedViewType === modelData.idx
                                                    ? (newListPopup.selectedColor !== "" ? newListPopup.selectedColor : Theme.primary)
                                                    : "#888888"
                                            strokeWidth: 1.6
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: modelData.label
                                            color: newListPopup.selectedViewType === modelData.idx
                                                ? (newListPopup.selectedColor !== "" ? newListPopup.selectedColor : Theme.primary)
                                                : "#888888"
                                            font.pixelSize: 10
                                            font.family: Theme.fontFamily
                                        }
                                    }

                                    HoverHandler { id: viewHover }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: newListPopup.selectedViewType = modelData.idx
                                    }
                                }
                            }
                        }
                    }

                    // Folder
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "Folder"
                            color: "#999999"
                            font.pixelSize: 12
                            font.family: Theme.fontFamily
                            Layout.preferredWidth: 72
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 32; radius: 7
                            color: folderComboHover.containsMouse ? "#2a2a2a" : "#1e1e1e"
                            border.color: "#3a3a3a"; border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                spacing: 6

                                SidebarIcon {
                                    width: 13; height: 13
                                    iconName: "folder"
                                    iconColor: "#888888"
                                    strokeWidth: 1.5
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: newListPopup.selectedFolder
                                    color: newListPopup.selectedFolder === "None" ? "#666666" : "#e0e0e0"
                                    font.pixelSize: 12
                                    font.family: Theme.fontFamily
                                    elide: Text.ElideRight
                                }

                                Text { text: "⌄"; color: "#666666"; font.pixelSize: 12 }
                            }

                            HoverHandler { id: folderComboHover }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: folderDropdown.open()
                            }

                            Popup {
                                id: folderDropdown
                                y: parent.height + 4
                                width: parent.width
                                padding: 4
                                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                                background: Rectangle {
                                    color: "#252525"; radius: 8
                                    border.color: "#3a3a3a"; border.width: 1
                                }

                                ColumnLayout {
                                    width: parent.width
                                    spacing: 2

                                    Repeater {
                                        model: {
                                            var opts = ["None"]
                                            var folders = taskListViewModel.getAllFolders()
                                            for (var i = 0; i < folders.length; i++) opts.push(folders[i])
                                            opts.push("+ New Folder")
                                            return opts
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 28; radius: 6
                                            color: folderItemHover.containsMouse ? "#333333" : "transparent"

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left; anchors.leftMargin: 10
                                                text: modelData
                                                color: modelData === "+ New Folder" ? Theme.primary
                                                    : (newListPopup.selectedFolder === modelData ? "#ffffff" : "#cccccc")
                                                font.pixelSize: 12
                                                font.family: Theme.fontFamily
                                            }

                                            Text {
                                                visible: newListPopup.selectedFolder === modelData && modelData !== "+ New Folder"
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.right: parent.right; anchors.rightMargin: 10
                                                text: "✓"; color: Theme.primary; font.pixelSize: 11
                                            }

                                            HoverHandler { id: folderItemHover }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData === "+ New Folder") {
                                                        folderDropdown.close()
                                                        openCenteredPopup(newFolderPopup)
                                                    } else {
                                                        newListPopup.selectedFolder = modelData
                                                        folderDropdown.close()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // List Type
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "Type"
                            color: "#999999"
                            font.pixelSize: 12
                            font.family: Theme.fontFamily
                            Layout.preferredWidth: 72
                        }

                        Row {
                            spacing: 6

                            Repeater {
                                model: ["Task List", "Notes List"]

                                Rectangle {
                                    height: 28
                                    width: typeLabel.implicitWidth + 24
                                    radius: 6
                                    color: newListPopup.selectedListType === modelData
                                        ? (newListPopup.selectedColor !== "" ? newListPopup.selectedColor + "22" : Theme.primary + "22")
                                        : (typeHover.containsMouse ? "#2a2a2a" : "#1e1e1e")
                                    border.color: newListPopup.selectedListType === modelData
                                                ? (newListPopup.selectedColor !== "" ? newListPopup.selectedColor : Theme.primary)
                                                : "#383838"
                                    border.width: 1

                                    Text {
                                        id: typeLabel
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: newListPopup.selectedListType === modelData
                                            ? (newListPopup.selectedColor !== "" ? newListPopup.selectedColor : Theme.primary)
                                            : "#888888"
                                        font.pixelSize: 11
                                        font.family: Theme.fontFamily
                                    }

                                    HoverHandler { id: typeHover }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: newListPopup.selectedListType = modelData
                                    }
                                }
                            }
                        }
                    }

                    // Show in Smart List
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "Smart List"
                            color: "#999999"
                            font.pixelSize: 12
                            font.family: Theme.fontFamily
                            Layout.preferredWidth: 72
                        }

                        Row {
                            spacing: 6

                            Repeater {
                                model: ["All tasks", "No"]

                                Rectangle {
                                    height: 28
                                    width: smartLabel.implicitWidth + 24
                                    radius: 6
                                    color: newListPopup.selectedSmartList === modelData
                                        ? (newListPopup.selectedColor !== "" ? newListPopup.selectedColor + "22" : Theme.primary + "22")
                                        : (smartHover.containsMouse ? "#2a2a2a" : "#1e1e1e")
                                    border.color: newListPopup.selectedSmartList === modelData
                                                ? (newListPopup.selectedColor !== "" ? newListPopup.selectedColor : Theme.primary)
                                                : "#383838"
                                    border.width: 1

                                    Text {
                                        id: smartLabel
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: newListPopup.selectedSmartList === modelData
                                            ? (newListPopup.selectedColor !== "" ? newListPopup.selectedColor : Theme.primary)
                                            : "#888888"
                                        font.pixelSize: 11
                                        font.family: Theme.fontFamily
                                    }

                                    HoverHandler { id: smartHover }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: newListPopup.selectedSmartList = modelData
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Buttons
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 80; height: 32; radius: 8
                            color: cancelHoverNL.containsMouse ? "#333333" : "#2a2a2a"
                            border.color: "#3a3a3a"; border.width: 1

                            Text { anchors.centerIn: parent; text: "Cancel"; color: "#bbbbbb"; font.pixelSize: 13; font.family: Theme.fontFamily }
                            HoverHandler { id: cancelHoverNL }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: newListPopup.close() }
                        }

                        Rectangle {
                            width: 80; height: 32; radius: 8
                            color: {
                                if (newListNameInput.text.trim() === "") return "#2a2a2a"
                                var c = newListPopup.selectedColor !== "" ? newListPopup.selectedColor : Theme.primary
                                return addHoverNL.containsMouse ? Qt.darker(c, 1.1) : c
                            }
                            opacity: newListNameInput.text.trim() === "" ? 0.5 : 1.0

                            Text { anchors.centerIn: parent; text: "Add"; color: "white"; font.pixelSize: 13; font.bold: true; font.family: Theme.fontFamily }
                            HoverHandler { id: addHoverNL }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: newListNameInput.text.trim() === "" ? Qt.ArrowCursor : Qt.PointingHandCursor
                                onClicked: newListPopup.createList()
                            }
                        }
                    }
                }

                // RIGHT: live preview
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 320
                    color: "#1a1a1a"
                    radius: 0
                    clip: true

                    // Subtle grid background
                    Canvas {
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.strokeStyle = "#242424"
                            ctx.lineWidth = 1
                            for (var x = 0; x < width; x += 20) {
                                ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke()
                            }
                            for (var y = 0; y < height; y += 20) {
                                ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 32, 200)
                        spacing: 0

                        // Mini list header
                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 8
                            color: "#242424"
                            border.color: "#303030"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 7

                                Rectangle {
                                    width: 16; height: 16; radius: 4
                                    color: newListPopup.selectedColor !== "" ? newListPopup.selectedColor + "33" : "#2a2a2a"
                                    border.color: newListPopup.selectedColor !== "" ? newListPopup.selectedColor : "#444444"
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: newListPopup.selectedIcon
                                        font.pixelSize: 9
                                        color: newListPopup.selectedColor !== "" ? newListPopup.selectedColor : "#888888"
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: newListNameInput.text.trim() === "" ? "List name" : newListNameInput.text.trim()
                                    color: newListNameInput.text.trim() === "" ? "#555555" : "#dddddd"
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.family: Theme.fontFamily
                                    elide: Text.ElideRight
                                }

                                // View type mini badge
                                Rectangle {
                                    height: 16
                                    width: viewBadge.implicitWidth + 10
                                    radius: 4
                                    color: newListPopup.selectedColor !== "" ? newListPopup.selectedColor + "22" : "#2a2a2a"

                                    Text {
                                        id: viewBadge
                                        anchors.centerIn: parent
                                        text: ["List","Board","Timeline"][newListPopup.selectedViewType]
                                        color: newListPopup.selectedColor !== "" ? newListPopup.selectedColor : "#666666"
                                        font.pixelSize: 9
                                        font.family: Theme.fontFamily
                                    }
                                }
                            }
                        }

                        // Preview tasks (list or board style)
                        Item {
                            Layout.fillWidth: true
                            height: newListPopup.selectedViewType === 1 ? boardPreview.height : listPreview.height

                            // List preview
                            ColumnLayout {
                                id: listPreview
                                width: parent.width
                                spacing: 2
                                visible: newListPopup.selectedViewType !== 1
                                anchors.top: parent.top
                                anchors.topMargin: 6

                                Repeater {
                                    model: newListPopup.selectedListType === "Notes List"
                                        ? ["📝 Note title", "Another note..."]
                                        : ["Task one", "Task two", "Task three"]

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 26; radius: 5
                                        color: "#242424"
                                        border.color: "#2e2e2e"; border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 6

                                            Rectangle {
                                                width: 11; height: 11; radius: 3
                                                color: "transparent"
                                                border.color: newListPopup.selectedColor !== "" ? newListPopup.selectedColor : "#444444"
                                                border.width: 1
                                                visible: newListPopup.selectedListType !== "Notes List"
                                            }

                                            Rectangle {
                                                Layout.fillWidth: true
                                                height: 6; radius: 3
                                                color: index === 0
                                                    ? (newListPopup.selectedColor !== "" ? newListPopup.selectedColor + "66" : "#3b82f666")
                                                    : "#2e2e2e"
                                            }
                                        }
                                    }
                                }
                            }

                            // Board preview
                            Row {
                                id: boardPreview
                                width: parent.width
                                spacing: 4
                                visible: newListPopup.selectedViewType === 1
                                anchors.top: parent.top
                                anchors.topMargin: 6

                                Repeater {
                                    model: ["To Do", "Done"]

                                    Rectangle {
                                        width: (boardPreview.width - 4) / 2
                                        height: 60; radius: 5
                                        color: "#1e1e1e"
                                        border.color: "#2e2e2e"; border.width: 1

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            spacing: 4

                                            Text {
                                                text: modelData
                                                color: newListPopup.selectedColor !== "" ? newListPopup.selectedColor : "#666666"
                                                font.pixelSize: 9; font.bold: true
                                                font.family: Theme.fontFamily
                                            }

                                            Rectangle {
                                                Layout.fillWidth: true
                                                height: 18; radius: 3
                                                color: "#2a2a2a"
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Type + Smart List badges
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            spacing: 4

                            Rectangle {
                                height: 16
                                width: typeBadge.implicitWidth + 10
                                radius: 4
                                color: "#242424"

                                Text {
                                    id: typeBadge
                                    anchors.centerIn: parent
                                    text: newListPopup.selectedListType
                                    color: "#666666"
                                    font.pixelSize: 9
                                    font.family: Theme.fontFamily
                                }
                            }

                            Rectangle {
                                height: 16
                                width: smartBadge.implicitWidth + 10
                                radius: 4
                                color: newListPopup.selectedSmartList === "All tasks" ? "#1e3a2a" : "#242424"

                                Text {
                                    id: smartBadge
                                    anchors.centerIn: parent
                                    text: newListPopup.selectedSmartList === "All tasks" ? "Smart ✓" : "Not in Smart"
                                    color: newListPopup.selectedSmartList === "All tasks" ? "#4ade80" : "#555555"
                                    font.pixelSize: 9
                                    font.family: Theme.fontFamily
                                }
                            }

                            Rectangle {
                                visible: newListPopup.selectedFolder !== "None"
                                height: 16
                                width: folderBadge.implicitWidth + 10
                                radius: 4
                                color: "#242424"

                                Text {
                                    id: folderBadge
                                    anchors.centerIn: parent
                                    text: "📁 " + newListPopup.selectedFolder
                                    color: "#666666"
                                    font.pixelSize: 9
                                    font.family: Theme.fontFamily
                                }
                            }
                        }
                    }
                }
            }
        }

        function createList() {
            var name = newListNameInput.text.trim()
            if (name === "") return
            taskListViewModel.createList(
                name,
                newListPopup.selectedColor,
                newListPopup.selectedFolder === "None" ? "" : newListPopup.selectedFolder,
                newListPopup.selectedListType
            )
            taskListViewModel.setFilterList(name)
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

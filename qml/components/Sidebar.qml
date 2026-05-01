import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    color: Theme.panel
    border.color: Theme.divider
    border.width: 1
    
    // Listen for task changes to update counts reactively
    Connections {
        target: taskListViewModel
        function onFilterChanged() {
            // Force re-evaluation of all bindings when filters change
            countUpdateTimer.restart()
        }
        function onTasksModified() {
            // Trigger count updates when tasks are added/deleted/modified
            countUpdateTimer.restart()
        }
    }
    
    // Timer to batch updates
    Timer {
        id: countUpdateTimer
        interval: 100
        running: false
        onTriggered: {
            // This will trigger binding updates
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 50
            Layout.fillHeight: true
            color: Theme.panelAlt
            border.color: Theme.divider
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 14
                anchors.bottomMargin: 12
                spacing: 10

                Repeater {
                    model: ["👤", "✓", "📅", "◉", "🕘", "🔍"]
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData
                        color: Theme.textSecondary
                        font.pixelSize: 18
                    }
                }

                Item { Layout.fillHeight: true }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "↻"
                    color: Theme.textMuted
                    font.pixelSize: 18
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            anchors.margins: 10
            spacing: 8

            // Quick filters
            Repeater {
                model: [
                    { name: "All", icon: "👤" },
                    { name: "Today", icon: "✓" },
                    { name: "Next 7 Days", icon: "📅" },
                    { name: "Inbox", icon: "◉" },
                    { name: "Summary", icon: "🕘" }
                ]
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 8
                    color: taskListViewModel.activeFilterDate === modelData.name ? Theme.primary + "22" : (quickHover.containsMouse ? Theme.surfaceHover : "transparent")
                    border.color: taskListViewModel.activeFilterDate === modelData.name ? Theme.primary : "transparent"
                    border.width: taskListViewModel.activeFilterDate === modelData.name ? 1.5 : 0
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            text: modelData.icon
                            font.pixelSize: 16
                        }
                        
                        Text {
                            text: modelData.name
                            color: taskListViewModel.activeFilterDate === modelData.name ? Theme.primary : Theme.textPrimary
                            font.pixelSize: 14
                            font.family: Theme.fontFamily
                            font.weight: taskListViewModel.activeFilterDate === modelData.name ? Font.Bold : Font.Normal
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: getTaskCount(modelData.name)
                            color: Theme.textMuted
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    HoverHandler { id: quickHover }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: taskListViewModel.setFilterDate(modelData.name)
                    }
                }
            }

            Rectangle { 
                Layout.fillWidth: true
                height: 1
                color: Theme.divider
                Layout.topMargin: 6
                Layout.bottomMargin: 8
            }

            Text { 
                text: "Lists"
                color: Theme.textMuted
                font.pixelSize: 14
                font.bold: true
                font.family: Theme.fontFamily
            }

            // List filters (tags)
            Repeater {
                model: taskListViewModel.getAllTags()
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 8
                    color: taskListViewModel.activeFilterTag === modelData ? Theme.primary + "22" : (listHover.containsMouse ? Theme.surfaceHover : "transparent")
                    border.color: taskListViewModel.activeFilterTag === modelData ? Theme.primary : "transparent"
                    border.width: taskListViewModel.activeFilterTag === modelData ? 1.5 : 0
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        // Tag color dot
                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: getTagColor(modelData)
                        }
                        
                        Text {
                            text: "#" + modelData
                            color: taskListViewModel.activeFilterTag === modelData ? Theme.primary : Theme.textPrimary
                            font.pixelSize: 13
                            font.family: Theme.fontFamily
                            font.weight: taskListViewModel.activeFilterTag === modelData ? Font.Bold : Font.Normal
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: getTagTaskCount(modelData)
                            color: Theme.textMuted
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    HoverHandler { id: listHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: taskListViewModel.setFilterTag(modelData)
                    }
                }
            }
            
            // Add new tag button
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 8
                color: addTagHover.containsMouse ? Theme.surfaceHover : "transparent"
                border.color: Theme.divider
                border.width: 1
                
                Behavior on color { ColorAnimation { duration: 150 } }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 6
                    
                    Text {
                        text: "+"
                        color: Theme.primary
                        font.pixelSize: 16
                        font.bold: true
                    }
                    
                    Text {
                        text: "Add List"
                        color: Theme.textMuted
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                    }
                }
                
                HoverHandler { id: addTagHover }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: newTagDialog.open()
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    // Helper functions to calculate task counts
    function getTaskCount(filterName) {
        // Return the count based on the filter type - use C++ methods for accurate counts
        switch(filterName) {
            case "All": return taskListViewModel.getAllTaskCount()
            case "Today": return taskListViewModel.getTodayCount()
            case "Next 7 Days": return taskListViewModel.getNext7DaysCount()
            case "Inbox": return taskListViewModel.getAllTaskCount()  // Inbox = all incomplete
            case "Summary": return ""
            default: return 0
        }
    }

    function getTagTaskCount(tag) {
        var count = 0
        // TagsRole = Qt::UserRole + 10 = 256 + 10 = 266
        for (var i = 0; i < taskListViewModel.rowCount(); i++) {
            var tagsData = taskListViewModel.data(taskListViewModel.index(i, 0), 266)
            if (tagsData && typeof tagsData === 'object') {
                if (tagsData.indexOf && tagsData.indexOf(tag) !== -1) {
                    count++
                } else if (tagsData.includes && tagsData.includes(tag)) {
                    count++
                }
            }
        }
        return count
    }
    
    // Generate consistent color for tags
    function getTagColor(tagName) {
        var colors = [
            "#ef4444", "#f97316", "#f59e0b", "#eab308",
            "#84cc16", "#22c55e", "#10b981", "#14b8a6",
            "#06b6d4", "#0ea5e9", "#3b82f6", "#6366f1",
            "#8b5cf6", "#d946ef", "#ec4899", "#f43f5e"
        ]
        var hash = 0
        for (var i = 0; i < tagName.length; i++) {
            hash = tagName.charCodeAt(i) + ((hash << 5) - hash)
        }
        var index = Math.abs(hash) % colors.length
        return colors[index]
    }
    
    Popup {
        id: newTagDialog
        parent: Overlay.overlay
        modal: true
        width: 300
        padding: 20
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        
        background: Rectangle {
            color: Theme.panel
            radius: Theme.radiusMedium
            border.color: Theme.divider
            border.width: 1
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            
            Text {
                text: "Create New List"
                color: Theme.textPrimary
                font.pixelSize: 16
                font.bold: true
                font.family: Theme.fontFamily
            }
            
            TextField {
                id: newTagInput
                Layout.fillWidth: true
                placeholderText: "List name (e.g., Work)"
                color: Theme.textPrimary
                font.pixelSize: 13
                font.family: Theme.fontFamily
                background: Rectangle {
                    color: Theme.surface
                    radius: 4
                    border.color: Theme.divider
                    border.width: 1
                }
                padding: 8
                onAccepted: {
                    if (newTagInput.text.trim() !== "") {
                        // Create a dummy task with the new tag
                        taskListViewModel.addTask("[List Created: " + newTagInput.text.trim() + "]", "", 0, "", [newTagInput.text.trim()])
                        newTagDialog.close()
                        newTagInput.text = ""
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Button {
                    text: "Cancel"
                    Layout.fillWidth: true
                    onClicked: {
                        newTagDialog.close()
                        newTagInput.text = ""
                    }
                }
                
                Button {
                    text: "Create"
                    Layout.fillWidth: true
                    onClicked: {
                        if (newTagInput.text.trim() !== "") {
                            taskListViewModel.addTask("[List Created: " + newTagInput.text.trim() + "]", "", 0, "", [newTagInput.text.trim()])
                            newTagDialog.close()
                            newTagInput.text = ""
                        }
                    }
                }
            }
        }
    }
}

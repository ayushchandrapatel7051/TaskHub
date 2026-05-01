import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    color: Theme.panel
    border.color: Theme.divider
    border.width: 1

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
                    height: 38
                    radius: 7
                    color: taskListViewModel.activeFilterDate === modelData.name ? Theme.surfaceHover : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: modelData.name
                            color: Theme.textPrimary
                            font.pixelSize: 15
                            font.family: Theme.fontFamily
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: getTaskCount(modelData.name)
                            color: Theme.textMuted
                            font.pixelSize: 13
                        }
                    }

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
                    height: 36
                    radius: 7
                    color: taskListViewModel.activeFilterTag === modelData ? Theme.primary + "22" : (listHover.containsMouse ? Theme.surfaceHover : "transparent")
                    border.color: taskListViewModel.activeFilterTag === modelData ? Theme.primary : "transparent"
                    border.width: taskListViewModel.activeFilterTag === modelData ? 1 : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: modelData
                            color: taskListViewModel.activeFilterTag === modelData ? Theme.primary : Theme.textPrimary
                            font.pixelSize: 14
                            font.family: Theme.fontFamily
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: getTagTaskCount(modelData)
                            color: Theme.textMuted
                            font.pixelSize: 12
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

            Item { Layout.fillHeight: true }
        }
    }

    // Helper functions to calculate task counts
    function getTaskCount(filterName) {
        // Return the count based on the filter type
        switch(filterName) {
            case "All": return taskListViewModel.rowCount()
            case "Today": return getFilteredCount("Today")
            case "Next 7 Days": return getFilteredCount("Upcoming")
            case "Inbox": return getFilteredCount("No Date")
            case "Summary": return ""
            default: return 0
        }
    }

    function getFilteredCount(section) {
        var count = 0
        // SectionRole = Qt::UserRole + 9 = 256 + 9 = 265
        for (var i = 0; i < taskListViewModel.rowCount(); i++) {
            var sectionData = taskListViewModel.data(taskListViewModel.index(i, 0), 265)
            if (sectionData === section) count++
        }
        return count
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
}

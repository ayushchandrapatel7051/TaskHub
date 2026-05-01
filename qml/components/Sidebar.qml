import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    color: Theme.surface
    border.color: Theme.divider
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 5

        // User Profile Area Placeholder
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 20
            
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: Theme.primary
                
                Text {
                    anchors.centerIn: parent
                    text: "U"
                    color: "white"
                    font.bold: true
                    font.family: Theme.fontFamily
                }
            }
            
            Text {
                text: "User Workspace"
                color: Theme.textPrimary
                font.pixelSize: 14
                font.bold: true
                font.family: Theme.fontFamily
                Layout.fillWidth: true
            }
        }

        // Navigation Items
        Text {
            text: "Views"
            color: Theme.textMuted
            font.pixelSize: 12
            font.bold: true
            font.family: Theme.fontFamily
            Layout.leftMargin: 10
            Layout.topMargin: 10
        }

        Repeater {
            model: ["Inbox", "Today", "Next 7 Days", "Calendar"]
            
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: {
                    if (taskListViewModel.activeFilterDate === modelData && taskListViewModel.activeFilterTag === "") {
                        return Theme.primary + "33" // 20% opacity primary
                    }
                    return itemMouseArea.containsMouse ? Theme.surfaceHover : "transparent"
                }
                radius: Theme.radiusMedium
                
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    text: modelData
                    color: (taskListViewModel.activeFilterDate === modelData && taskListViewModel.activeFilterTag === "") ? Theme.primary : Theme.textPrimary
                    font.pixelSize: 15
                    font.bold: (taskListViewModel.activeFilterDate === modelData && taskListViewModel.activeFilterTag === "")
                    font.family: Theme.fontFamily
                }
                
                MouseArea {
                    id: itemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        taskListViewModel.setFilterDate(modelData)
                    }
                }
            }
        }
        
        // Tags Section
        Text {
            text: "Tags"
            color: Theme.textMuted
            font.pixelSize: 12
            font.bold: true
            font.family: Theme.fontFamily
            Layout.leftMargin: 10
            Layout.topMargin: 20
        }
        
        Repeater {
            model: taskListViewModel.getAllTags()
            
            Rectangle {
                Layout.fillWidth: true
                height: 35
                color: {
                    if (taskListViewModel.activeFilterTag === modelData) {
                        return Theme.primary + "33"
                    }
                    return tagMouseArea.containsMouse ? Theme.surfaceHover : "transparent"
                }
                radius: Theme.radiusMedium
                
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    text: "#" + modelData
                    color: taskListViewModel.activeFilterTag === modelData ? Theme.primary : Theme.textSecondary
                    font.pixelSize: 14
                    font.family: Theme.fontFamily
                }
                
                MouseArea {
                    id: tagMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        taskListViewModel.setFilterTag(modelData)
                    }
                }
            }
        }

        Item { Layout.fillHeight: true } // Spacer
    }
}

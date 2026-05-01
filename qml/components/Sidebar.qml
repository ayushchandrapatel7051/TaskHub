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
        Repeater {
            model: ["Inbox", "Today", "Next 7 Days", "Calendar"]
            
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: itemMouseArea.containsMouse ? Theme.surfaceHover : "transparent"
                radius: Theme.radiusMedium
                
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    text: modelData
                    color: Theme.textPrimary
                    font.pixelSize: 15
                    font.family: Theme.fontFamily
                }
                
                MouseArea {
                    id: itemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }

        Item { Layout.fillHeight: true } // Spacer
    }
}

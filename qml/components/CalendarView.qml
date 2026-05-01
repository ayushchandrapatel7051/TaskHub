import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    color: Theme.background

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        // Header
        Text {
            text: "Calendar (Agenda)"
            color: Theme.textPrimary
            font.pixelSize: 28
            font.bold: true
            font.family: Theme.fontFamily
        }

        // Fake Month Grid Placeholder (Visual only for MVP)
        Rectangle {
            Layout.fillWidth: true
            height: 150
            color: Theme.surface
            radius: Theme.radiusMedium
            border.color: Theme.divider
            
            GridLayout {
                anchors.fill: parent
                anchors.margins: 10
                columns: 7
                rowSpacing: 5
                columnSpacing: 5
                
                Repeater {
                    model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                    Text {
                        text: modelData
                        color: Theme.textMuted
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }
                }
                
                Repeater {
                    model: 30
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: (index + 1) === 15 ? Theme.primary : "transparent"
                        radius: 4
                        Text {
                            anchors.centerIn: parent
                            text: (index + 1).toString()
                            color: (index + 1) === 15 ? "white" : Theme.textPrimary
                        }
                    }
                }
            }
        }

        // Agenda List
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: taskListViewModel
            clip: true
            spacing: 10
            
            delegate: Rectangle {
                width: ListView.view.width
                height: visible ? 60 : 0
                visible: model.dueAt !== undefined && model.dueAt !== ""
                color: Theme.surface
                radius: Theme.radiusMedium
                border.color: Theme.divider
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    
                    Text {
                        text: model.dueAt !== undefined ? model.dueAt.substring(0, 10) : ""
                        color: Theme.primary
                        font.bold: true
                        font.pixelSize: 14
                        Layout.preferredWidth: 100
                    }
                    
                    Text {
                        text: model.title
                        color: Theme.textPrimary
                        font.pixelSize: 16
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}

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
        anchors.margins: 20
        spacing: 15

        // Detail Placeholder
        Text {
            text: "Task Details"
            color: Theme.textSecondary
            font.pixelSize: 14
            font.family: Theme.fontFamily
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.divider
        }

        Text {
            Layout.fillWidth: true
            text: "Select a task to view details"
            color: Theme.textMuted
            font.pixelSize: 16
            font.family: Theme.fontFamily
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.fillHeight: true
        }
    }
}

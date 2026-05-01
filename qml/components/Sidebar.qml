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

            Repeater {
                model: [
                    { name: "All", count: "117" },
                    { name: "Today", count: "6" },
                    { name: "Next 7 Days", count: "6" },
                    { name: "Inbox", count: "1" },
                    { name: "Summary", count: "" }
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

                        Text {
                            text: modelData.name
                            color: Theme.textPrimary
                            font.pixelSize: 15
                            font.family: Theme.fontFamily
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: modelData.count
                            color: Theme.textMuted
                            font.pixelSize: 13
                            visible: modelData.count !== ""
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

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider; Layout.topMargin: 6; Layout.bottomMargin: 8 }

            Text { text: "Lists"; color: Theme.textMuted; font.pixelSize: 14; font.bold: true; font.family: Theme.fontFamily }

            Repeater {
                model: ["My 2025 Goals", "Programming", "Finance", "Skills", "Work"]
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 7
                    color: listHover.containsMouse ? Theme.surfaceHover : "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        text: modelData
                        color: Theme.textPrimary
                        font.pixelSize: 14
                        font.family: Theme.fontFamily
                    }
                    HoverHandler { id: listHover }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}

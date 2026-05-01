import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    color: "#181818"

    function isUrgent(dueAt) {
        if (dueAt === undefined || dueAt === "") return false
        var due = new Date(dueAt)
        var today = new Date()
        today.setHours(23, 59, 59, 999)
        return due <= today
    }

    function quadrantFor(priority, dueAt, pinned) {
        var urgent = isUrgent(dueAt)
        var important = priority >= 2 || pinned
        if (urgent && important) return 1
        if (!urgent && important) return 2
        if (urgent && !important) return 3
        return 4
    }

    function countQuadrant(quadrant) {
        var count = 0
        for (var i = 0; i < taskListViewModel.rowCount(); i++) {
            var idx = taskListViewModel.index(i, 0)
            var priority = taskListViewModel.data(idx, 260)
            var completed = taskListViewModel.data(idx, 262)
            var dueAt = taskListViewModel.data(idx, 263)
            var pinned = taskListViewModel.data(idx, 264)
            if (!completed && quadrantFor(priority, dueAt, pinned) === quadrant) count++
        }
        return count
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 16

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Eisenhower Matrix"
                color: "#f5f5f5"
                font.pixelSize: 20
                font.bold: true
                font.family: Theme.fontFamily
                Layout.fillWidth: true
            }

            Text {
                text: "..."
                color: "#f5f5f5"
                font.pixelSize: 20
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rowSpacing: 12
            columnSpacing: 12

            QuadrantPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                quadrant: 1
                accent: "#ff5a69"
                label: "Urgent & Important"
                marker: "I"
            }

            QuadrantPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                quadrant: 2
                accent: "#ffb700"
                label: "Not Urgent & Important"
                marker: "II"
            }

            QuadrantPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                quadrant: 3
                accent: "#4b78ff"
                label: "Urgent & Unimportant"
                marker: "III"
            }

            QuadrantPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                quadrant: 4
                accent: "#00c7a4"
                label: "Not Urgent & Unimportant"
                marker: "IV"
            }
        }
    }

    component QuadrantPanel: Rectangle {
        id: panel
        property int quadrant: 1
        property color accent: "#ff5a69"
        property string label: ""
        property string marker: "I"

        radius: 10
        color: "#222222"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: panel.accent

                    Text {
                        anchors.centerIn: parent
                        text: panel.marker
                        color: "#171717"
                        font.pixelSize: panel.marker.length > 2 ? 7 : 9
                        font.bold: true
                    }
                }

                Text {
                    text: panel.label
                    color: panel.accent
                    font.pixelSize: 13
                    font.bold: true
                    font.family: Theme.fontFamily
                    Layout.fillWidth: true
                }
            }

            Text {
                text: (panel.quadrant === 4 && root.countQuadrant(panel.quadrant) > 0 ? "Pinned" : "Overdue") + "  " + root.countQuadrant(panel.quadrant)
                color: "#f0f0f0"
                font.pixelSize: 14
                font.bold: true
                font.family: Theme.fontFamily
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: taskListViewModel
                spacing: 0

                delegate: Rectangle {
                    width: ListView.view.width
                    height: rowVisible ? 42 : 0
                    visible: rowVisible
                    color: "transparent"
                    property bool rowVisible: !model.isCompleted && root.quadrantFor(model.priority, model.dueAt, model.isPinned) === panel.quadrant

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 22
                        anchors.rightMargin: 16
                        spacing: 8

                        Rectangle {
                            width: 14
                            height: 14
                            radius: 3
                            color: "transparent"
                            border.color: panel.accent
                            border.width: 1
                        }

                        Text {
                            text: model.title
                            color: "#eeeeee"
                            font.pixelSize: 14
                            font.family: Theme.fontFamily
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: model.tags && model.tags.length > 0 ? model.tags[0] : ""
                            color: "#cfcfcf"
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                            visible: text !== ""
                        }

                        Text {
                            text: model.dueAt ? model.dueAt.substring(0, 10) : ""
                            color: root.isUrgent(model.dueAt) ? "#ff4b4b" : "#8d8d8d"
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: "#303030"
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignCenter
                text: "No Tasks"
                color: "#737373"
                font.pixelSize: 13
                font.family: Theme.fontFamily
                visible: root.countQuadrant(panel.quadrant) === 0
            }
        }
    }
}

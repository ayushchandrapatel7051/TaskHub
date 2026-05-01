import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    color: "#181818"

    ListModel { id: habits }
    property string habitStatus: "Active"

    function dayLabel(offset) {
        var labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var d = new Date()
        d.setDate(d.getDate() - 6 + offset)
        return labels[d.getDay()]
    }

    function dayNumber(offset) {
        var d = new Date()
        d.setDate(d.getDate() - 6 + offset)
        return d.getDate()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#181818"
            border.color: "#303030"
            border.width: 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 18

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        id: habitTitle
                        text: "Habit⌄"
                        color: "#f5f5f5"
                        font.pixelSize: 20
                        font.bold: true
                        font.family: Theme.fontFamily
                        Layout.fillWidth: true

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: statusPopup.open()
                        }
                    }

                    Text { text: "▦"; color: "#eeeeee"; font.pixelSize: 18 }
                    Text {
                        text: "+"
                        color: "#eeeeee"
                        font.pixelSize: 26
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -10
                            cursorShape: Qt.PointingHandCursor
                            onClicked: addHabitPopup.open()
                        }
                    }
                    Text { text: "..."; color: "#eeeeee"; font.pixelSize: 20 }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 78
                    Layout.leftMargin: 18
                    Layout.rightMargin: 18
                    spacing: 0

                    Repeater {
                        model: 7

                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.dayLabel(index)
                                color: index === 6 ? Theme.primary : "#8a8a8a"
                                font.pixelSize: 10
                                font.family: Theme.fontFamily
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.dayNumber(index)
                                color: index === 6 ? Theme.primary : "#dcdcdc"
                                font.pixelSize: 12
                                font.bold: true
                                font.family: Theme.fontFamily
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 22
                                height: 22
                                radius: 11
                                color: "transparent"
                                border.color: "#2f2f2f"
                                border.width: 2

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 14
                                    height: 2
                                    rotation: -45
                                    color: "#252525"
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        visible: habits.count === 0

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 112
                            height: 90
                            radius: 22
                            color: "#242424"

                            Text {
                                anchors.centerIn: parent
                                text: "◷"
                                color: Theme.primary
                                font.pixelSize: 58
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Develop a habit"
                            color: "#f1f1f1"
                            font.pixelSize: 14
                            font.bold: true
                            font.family: Theme.fontFamily
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Every little bit counts"
                            color: "#9a9a9a"
                            font.pixelSize: 12
                            font.family: Theme.fontFamily
                        }
                    }

                    ListView {
                        anchors.fill: parent
                        visible: habits.count > 0
                        model: habits
                        spacing: 8
                        clip: true

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 54
                            radius: 8
                            color: "#222222"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 12

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: done ? Theme.primary : "transparent"
                                    border.color: done ? Theme.primary : "#777777"
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        visible: done
                                        text: "✓"
                                        color: "white"
                                        font.pixelSize: 11
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: habits.setProperty(index, "done", !done)
                                    }
                                }

                                Text {
                                    text: title
                                    color: done ? "#888888" : "#f5f5f5"
                                    font.pixelSize: 14
                                    font.strikeout: done
                                    font.family: Theme.fontFamily
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: done ? "Done" : "Today"
                                    color: done ? Theme.primary : "#8a8a8a"
                                    font.pixelSize: 12
                                    font.family: Theme.fontFamily
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 420
            Layout.fillHeight: true
            color: "#181818"
            border.color: "#303030"
            border.width: 1
        }
    }

    Popup {
        id: statusPopup
        parent: Overlay.overlay
        modal: false
        width: 164
        height: 78
        padding: 0
        x: 78
        y: 39
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#222222"
            radius: 10
            border.color: "#3b3b3b"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 0

            Repeater {
                model: ["Active", "Archived"]

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 6
                    color: statusMouse.containsMouse ? "#303030" : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8

                        Text {
                            text: modelData
                            color: root.habitStatus === modelData ? Theme.primary : "#f1f1f1"
                            font.pixelSize: 13
                            font.family: Theme.fontFamily
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "✓"
                            visible: root.habitStatus === modelData
                            color: Theme.primary
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: statusMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.habitStatus = modelData
                            statusPopup.close()
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: addHabitPopup
        parent: Overlay.overlay
        modal: true
        width: 320
        padding: 18
        x: (parent.width - width) / 2
        y: 90

        background: Rectangle {
            color: "#252525"
            radius: 8
            border.color: "#3b3b3b"
            border.width: 1
        }

        ColumnLayout {
            width: parent.width
            spacing: 12

            Text {
                text: "New Habit"
                color: "#f5f5f5"
                font.pixelSize: 16
                font.bold: true
                font.family: Theme.fontFamily
            }

            TextField {
                id: habitInput
                Layout.fillWidth: true
                placeholderText: "Habit name"
                color: "#f5f5f5"
                placeholderTextColor: "#777777"
                background: Rectangle {
                    color: "#1b1b1b"
                    radius: 6
                    border.color: "#3b3b3b"
                    border.width: 1
                }
                onAccepted: addHabit()
            }

            Button {
                text: "Create"
                Layout.fillWidth: true
                onClicked: addHabit()
            }
        }

        function addHabit() {
            var name = habitInput.text.trim()
            if (name === "") return
            habits.append({ title: name, done: false })
            habitInput.text = ""
            addHabitPopup.close()
        }
    }
}

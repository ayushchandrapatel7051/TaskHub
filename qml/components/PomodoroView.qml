import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    color: "#181818"

    property int pomoSeconds: 35 * 60
    property int stopwatchSeconds: 0
    property bool running: false
    property bool stopwatchMode: false
    property int completedPomos: 0
    property int totalFocusSeconds: 75 * 60

    function pad(value) {
        return value < 10 ? "0" + value : value
    }

    function displayTime() {
        var seconds = stopwatchMode ? stopwatchSeconds : pomoSeconds
        return Math.floor(seconds / 60) + ":" + pad(seconds % 60)
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            if (root.stopwatchMode) {
                root.stopwatchSeconds++
            } else if (root.pomoSeconds > 0) {
                root.pomoSeconds--
                root.totalFocusSeconds++
            } else {
                root.running = false
                root.completedPomos++
                root.pomoSeconds = 35 * 60
            }
        }
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
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Pomodoro"
                        color: "#f5f5f5"
                        font.pixelSize: 20
                        font.bold: true
                        font.family: Theme.fontFamily
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 186
                        height: 36
                        radius: 18
                        color: "#292929"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 3

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 15
                                color: !root.stopwatchMode ? "#3a3a3a" : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "Pomo"
                                    color: !root.stopwatchMode ? "#f5f5f5" : "#a4a4a4"
                                    font.pixelSize: 13
                                    font.family: Theme.fontFamily
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.stopwatchMode = false
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 15
                                color: root.stopwatchMode ? "#3a3a3a" : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "Stopwatch"
                                    color: root.stopwatchMode ? "#f5f5f5" : "#a4a4a4"
                                    font.pixelSize: 13
                                    font.family: Theme.fontFamily
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.stopwatchMode = true
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text { text: "+"; color: "#f5f5f5"; font.pixelSize: 24 }
                    Text { text: "..."; color: "#f5f5f5"; font.pixelSize: 20 }
                }

                Item { Layout.fillHeight: true }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Focus ›"
                    color: "#898989"
                    font.pixelSize: 13
                    font.family: Theme.fontFamily
                    Layout.bottomMargin: 80
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 360
                    height: 360
                    radius: 180
                    color: "transparent"
                    border.color: root.running ? Theme.primary : "#303030"
                    border.width: 7

                    Text {
                        anchors.centerIn: parent
                        text: root.displayTime()
                        color: "#f5f5f5"
                        font.pixelSize: 50
                        font.family: Theme.fontFamily
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 120
                    width: 170
                    height: 48
                    radius: 24
                    color: startMouse.containsMouse ? Theme.primaryHover : Theme.primary

                    Text {
                        anchors.centerIn: parent
                        text: root.running ? "Pause" : "Start"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        id: startMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.running = !root.running
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 16
                    text: "Reset"
                    color: "#8a8a8a"
                    font.pixelSize: 13
                    font.family: Theme.fontFamily

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.running = false
                            root.pomoSeconds = 35 * 60
                            root.stopwatchSeconds = 0
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        Rectangle {
            Layout.preferredWidth: 430
            Layout.fillHeight: true
            color: "#191919"
            border.color: "#303030"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 24

                Text {
                    text: "Overview"
                    color: "#f5f5f5"
                    font.pixelSize: 20
                    font.bold: true
                    font.family: Theme.fontFamily
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 12
                    rowSpacing: 12

                    StatCard { title: "Today's Pomo"; value: root.completedPomos.toString() }
                    StatCard { title: "Today's Focus"; value: Math.floor(root.stopwatchSeconds / 60) + "m" }
                    StatCard { title: "Total Pomo"; value: (root.completedPomos + 2).toString() }
                    StatCard { title: "Total Focus Duration"; value: Math.floor(root.totalFocusSeconds / 3600) + "h " + Math.floor((root.totalFocusSeconds % 3600) / 60) + "m" }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 20

                    Text {
                        text: "Focus Record"
                        color: "#f5f5f5"
                        font.pixelSize: 18
                        font.bold: true
                        font.family: Theme.fontFamily
                        Layout.fillWidth: true
                    }

                    Text { text: "+"; color: "#dcdcdc"; font.pixelSize: 22 }
                    Text { text: "..."; color: "#dcdcdc"; font.pixelSize: 20 }
                }

                Text {
                    text: "Mar 20, 2024"
                    color: "#8a8a8a"
                    font.pixelSize: 13
                    font.family: Theme.fontFamily
                }

                Repeater {
                    model: [
                        { time: "14:01 - 14:51", length: "35m" },
                        { time: "12:41 - 13:26", length: "40m" }
                    ]

                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            width: 22
                            height: 22
                            radius: 11
                            color: "#234ea9"
                            Text {
                                anchors.centerIn: parent
                                text: "✓"
                                color: "#83a9ff"
                                font.pixelSize: 12
                            }
                        }

                        Text {
                            text: modelData.time
                            color: "#858585"
                            font.pixelSize: 12
                            font.family: Theme.fontFamily
                            Layout.fillWidth: true
                        }

                        Text {
                            text: modelData.length
                            color: "#858585"
                            font.pixelSize: 12
                            font.family: Theme.fontFamily
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    component StatCard: Rectangle {
        property string title: ""
        property string value: ""

        Layout.fillWidth: true
        height: 72
        radius: 9
        color: "#222222"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            Text {
                text: title
                color: "#7e7e7e"
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }

            Text {
                text: value
                color: "#e8e8e8"
                font.pixelSize: 24
                font.bold: true
                font.family: Theme.fontFamily
            }
        }
    }
}

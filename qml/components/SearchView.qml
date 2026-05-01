import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    color: "#181818"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 18

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Text {
                text: "Search"
                color: "#f5f5f5"
                font.pixelSize: 22
                font.bold: true
                font.family: Theme.fontFamily
            }

            Rectangle {
                Layout.fillWidth: true
                height: 42
                radius: 8
                color: "#222222"
                border.color: searchInput.activeFocus ? Theme.primary : "#333333"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "⌕"
                        color: "#8a8a8a"
                        font.pixelSize: 20
                    }

                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        text: taskListViewModel.searchQuery
                        placeholderText: "Search title or description"
                        color: "#f5f5f5"
                        placeholderTextColor: "#777777"
                        font.pixelSize: 14
                        font.family: Theme.fontFamily
                        background: null
                        padding: 0
                        onTextChanged: taskListViewModel.setSearchQuery(text)
                        Component.onCompleted: forceActiveFocus()
                    }

                    Text {
                        text: "×"
                        color: "#8a8a8a"
                        font.pixelSize: 20
                        visible: searchInput.text !== ""

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = ""
                                taskListViewModel.setSearchQuery("")
                            }
                        }
                    }
                }
            }
        }

        Text {
            text: searchInput.text === "" ? "Type to search your tasks" : taskListViewModel.rowCount() + " result" + (taskListViewModel.rowCount() === 1 ? "" : "s")
            color: "#8a8a8a"
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: taskListViewModel
            clip: true
            spacing: 0

            delegate: Rectangle {
                width: ListView.view.width
                height: 52
                color: searchMouse.containsMouse ? "#222222" : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Rectangle {
                        width: 15
                        height: 15
                        radius: 3
                        color: "transparent"
                        border.color: model.isCompleted ? "#777777" : Theme.primary
                        border.width: 1
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            text: model.title
                            color: "#f5f5f5"
                            font.pixelSize: 14
                            font.family: Theme.fontFamily
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: model.description || (model.dueAt ? model.dueAt.substring(0, 10) : "No date")
                            color: "#777777"
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: model.tags && model.tags.length > 0 ? model.tags[0] : ""
                        color: "#9a9a9a"
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    id: searchMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: taskListViewModel.selectTask(index)
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: "#2a2a2a"
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    color: "#181818"

    property date focusDate: new Date()
    property int focusYear: focusDate.getFullYear()
    property int focusMonth: focusDate.getMonth()
    property string mode: "Year"
    property var modes: ["Year", "Month", "Week", "Day", "Agenda", "Multi-Day", "Multi-Week"]
    property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    property var dayNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    function pad(value) {
        return value < 10 ? "0" + value : value
    }

    function dateKey(date) {
        return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate())
    }

    function dateFromKey(key) {
        var parts = key.split("-")
        return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]))
    }

    function titleText() {
        if (mode === "Year") return focusYear.toString()
        return monthNames[focusMonth]
    }

    function monthCells(year, month) {
        var first = new Date(year, month, 1)
        var start = new Date(first)
        start.setDate(first.getDate() - ((first.getDay() + 6) % 7))
        var cells = []
        for (var i = 0; i < 42; i++) {
            var d = new Date(start)
            d.setDate(start.getDate() + i)
            cells.push({
                day: d.getDate(),
                key: dateKey(d),
                current: d.getMonth() === month,
                today: dateKey(d) === dateKey(new Date())
            })
        }
        return cells
    }

    function addDays(date, days) {
        var d = new Date(date)
        d.setDate(d.getDate() + days)
        return d
    }

    function weekStart(date) {
        var d = new Date(date)
        d.setDate(d.getDate() - ((d.getDay() + 6) % 7))
        return d
    }

    function periodDays(count) {
        var start = count === 14 ? weekStart(focusDate) : (count === 7 ? weekStart(focusDate) : focusDate)
        var days = []
        for (var i = 0; i < count; i++) {
            var d = addDays(start, i)
            days.push({ label: dayNames[i % 7], day: d.getDate(), key: dateKey(d), today: dateKey(d) === dateKey(new Date()) })
        }
        return days
    }

    function taskColor(priority, index) {
        if (priority >= 3) return "#8b5368"
        if (priority === 2) return "#3b559d"
        if (priority === 1) return "#53858b"
        var colors = ["#7d6d3d", "#6f587f", "#526d5f", "#8a6a5f"]
        return colors[index % colors.length]
    }

    function tasksForDate(key) {
        var tasks = []
        for (var i = 0; i < taskListViewModel.rowCount(); i++) {
            var idx = taskListViewModel.index(i, 0)
            var dueAt = taskListViewModel.data(idx, 263)
            if (dueAt && dueAt.substring(0, 10) === key) {
                tasks.push({
                    title: taskListViewModel.data(idx, 258),
                    priority: taskListViewModel.data(idx, 260),
                    color: taskColor(taskListViewModel.data(idx, 260), tasks.length),
                    time: dueAt.length > 10 ? dueAt.substring(11, 16) : ""
                })
            }
        }
        return tasks
    }

    function taskCountForDate(key) {
        return tasksForDate(key).length
    }

    function agendaTasks() {
        var tasks = []
        for (var i = 0; i < taskListViewModel.rowCount(); i++) {
            var idx = taskListViewModel.index(i, 0)
            var dueAt = taskListViewModel.data(idx, 263)
            if (dueAt) {
                tasks.push({
                    title: taskListViewModel.data(idx, 258),
                    date: dueAt.substring(0, 10),
                    priority: taskListViewModel.data(idx, 260),
                    color: taskColor(taskListViewModel.data(idx, 260), i),
                    time: dueAt.length > 10 ? dueAt.substring(11, 16) : "08:00"
                })
            }
        }
        tasks.sort(function(a, b) { return a.date.localeCompare(b.date) })
        return tasks
    }

    function movePeriod(delta) {
        if (mode === "Year") {
            focusDate = new Date(focusYear + delta, focusMonth, 1)
        } else if (mode === "Month" || mode === "Agenda") {
            focusDate = new Date(focusYear, focusMonth + delta, 1)
        } else {
            focusDate = addDays(focusDate, delta * (mode === "Day" ? 1 : mode === "Multi-Week" ? 14 : mode === "Multi-Day" ? 3 : 7))
        }
        focusYear = focusDate.getFullYear()
        focusMonth = focusDate.getMonth()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            Layout.leftMargin: 18
            Layout.rightMargin: 12
            spacing: 12

            Text {
                text: "▣"
                color: "#f2f2f2"
                font.pixelSize: 20
            }

            Text {
                text: root.titleText()
                color: "#f5f5f5"
                font.pixelSize: 22
                font.bold: true
                font.family: Theme.fontFamily
                Layout.fillWidth: true
            }

            ToolButton {
                text: "+"
                palette.buttonText: "#eeeeee"
            }

            ComboBox {
                id: viewCombo
                model: root.modes
                currentIndex: root.modes.indexOf(root.mode)
                onActivated: root.mode = currentText
                Layout.preferredWidth: 94
            }

            Button {
                text: "‹"
                onClicked: root.movePeriod(-1)
            }

            Button {
                text: "Today"
                onClicked: {
                    root.focusDate = new Date()
                    root.focusYear = root.focusDate.getFullYear()
                    root.focusMonth = root.focusDate.getMonth()
                }
            }

            Button {
                text: "›"
                onClicked: root.movePeriod(1)
            }

            Text {
                text: "..."
                color: "#eeeeee"
                font.pixelSize: 20
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#282828"
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StackLayout {
                anchors.fill: parent
                anchors.bottomMargin: 72
                currentIndex: root.modes.indexOf(root.mode)

                YearView {}
                MonthView {}
                TimelineView { dayCount: 7 }
                TimelineView { dayCount: 1 }
                AgendaView {}
                TimelineView { dayCount: 3 }
                MultiWeekView {}
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 24
                width: 700
                height: 48
                radius: 24
                color: "#333333"
                border.color: "#555555"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 2

                    Repeater {
                        model: root.modes

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 20
                            color: root.mode === modelData ? "#4a4a4a" : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: "#f2f2f2"
                                font.pixelSize: 13
                                font.family: Theme.fontFamily
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.mode = modelData
                            }
                        }
                    }
                }
            }
        }
    }

    component YearView: Flickable {
        contentWidth: width
        contentHeight: yearGrid.height + 48
        clip: true

        GridLayout {
            id: yearGrid
            width: parent.width - 80
            x: 40
            y: 28
            columns: 4
            columnSpacing: 62
            rowSpacing: 54

            Repeater {
                model: 12

                delegate: ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 260
                    spacing: 14

                    Text {
                        text: root.monthNames[index]
                        color: "#f5f5f5"
                        font.pixelSize: 22
                        font.bold: true
                        font.family: Theme.fontFamily
                    }

                    GridLayout {
                        columns: 7
                        columnSpacing: 0
                        rowSpacing: 0

                        Repeater {
                            model: root.dayNames
                            Text {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 26
                                text: modelData.substring(0, 1)
                                color: "#747474"
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: 12
                            }
                        }

                        Repeater {
                            model: root.monthCells(root.focusYear, index)

                            Rectangle {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 31
                                color: {
                                    if (!modelData.current) return "transparent"
                                    var count = root.taskCountForDate(modelData.key)
                                    if (modelData.today) return Theme.primary
                                    if (count > 1) return "#3f57b9"
                                    if (count === 1) return "#26356a"
                                    return "transparent"
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    color: modelData.current ? "#f2f2f2" : "#5a5a5a"
                                    font.pixelSize: 13
                                    font.family: Theme.fontFamily
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component MonthView: GridLayout {
        columns: 7
        rowSpacing: 0
        columnSpacing: 0
        anchors.margins: 0

        Repeater {
            model: root.dayNames
            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                text: modelData
                color: "#777777"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
                font.family: Theme.fontFamily
            }
        }

        Repeater {
            model: root.monthCells(root.focusYear, root.focusMonth)

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#181818"
                border.color: "#2b2b2b"
                border.width: 1

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.leftMargin: 8
                    anchors.topMargin: 6
                    text: modelData.current ? modelData.day : root.monthNames[(root.focusMonth + (modelData.day > 20 ? -1 : 1) + 12) % 12].substring(0, 3) + " " + modelData.day
                    color: modelData.today ? "white" : (modelData.current ? "#f5f5f5" : "#6a6a6a")
                    font.pixelSize: 13
                    font.bold: modelData.today
                    font.family: Theme.fontFamily

                    Rectangle {
                        anchors.centerIn: parent
                        z: -1
                        width: 24
                        height: 24
                        radius: 12
                        color: modelData.today ? Theme.primary : "transparent"
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 30
                    spacing: 2

                    Repeater {
                        model: root.tasksForDate(modelData.key).slice(0, 4)

                        Rectangle {
                            width: parent.width - 6
                            x: 3
                            height: 18
                            radius: 3
                            color: modelData.color
                            opacity: 0.86

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 4
                                verticalAlignment: Text.AlignVCenter
                                text: "□ " + modelData.title
                                color: "#eeeeee"
                                font.pixelSize: 11
                                font.family: Theme.fontFamily
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }

    component TimelineView: Rectangle {
        property int dayCount: 7
        color: "#181818"

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.preferredWidth: 68
                Layout.fillHeight: true
                color: "#181818"

                Column {
                    y: 54
                    width: parent.width
                    Repeater {
                        model: ["00:00", "-07:00", "08:00", "09:00", "10:00", "Noon", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00"]
                        Text {
                            width: parent.width - 10
                            height: 60
                            text: modelData
                            color: "#747474"
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                        }
                    }
                }
            }

            Repeater {
                model: root.periodDays(dayCount)

                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#181818"
                    border.color: "#2b2b2b"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: (dayCount === 1 ? "" : modelData.label + " ") + modelData.day
                            color: modelData.today ? "white" : "#f5f5f5"
                            font.pixelSize: 15
                            font.bold: true
                            font.family: Theme.fontFamily

                            Rectangle {
                                anchors.centerIn: parent
                                z: -1
                                width: 24
                                height: 24
                                radius: 12
                                color: modelData.today ? Theme.primary : "transparent"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 2

                            Repeater {
                                model: root.tasksForDate(modelData.key)

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Math.max(58, dayCount === 1 ? 88 : 78)
                                    radius: 4
                                    color: modelData.color
                                    opacity: 0.9

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 4

                                        Text {
                                            text: "□ " + modelData.title
                                            color: "#f2f2f2"
                                            font.pixelSize: 13
                                            font.bold: true
                                            font.family: Theme.fontFamily
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: modelData.time !== "" ? modelData.time : "08:00"
                                            color: "#d8d8d8"
                                            font.pixelSize: 10
                                            font.family: Theme.fontFamily
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component AgendaView: Flickable {
        contentWidth: width
        contentHeight: agendaColumn.height + 140
        clip: true

        ColumnLayout {
            id: agendaColumn
            width: Math.min(parent.width - 120, 900)
            x: (parent.width - width) / 2
            y: 28
            spacing: 12

            Repeater {
                model: root.agendaTasks()

                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: 28

                    Text {
                        Layout.preferredWidth: 150
                        text: modelData.date
                        color: "#f5f5f5"
                        font.pixelSize: 18
                        font.bold: true
                        font.family: Theme.fontFamily
                    }

                    Text {
                        Layout.preferredWidth: 70
                        text: modelData.time
                        color: "#8a8a8a"
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 60
                        radius: 5
                        color: modelData.color
                        opacity: 0.55

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            Text {
                                text: modelData.time
                                color: Theme.primary
                                font.pixelSize: 12
                                font.family: Theme.fontFamily
                            }

                            Text {
                                text: modelData.title
                                color: "#f5f5f5"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: Theme.fontFamily
                            }
                        }
                    }
                }
            }
        }
    }

    component MultiWeekView: GridLayout {
        columns: 7
        rowSpacing: 0
        columnSpacing: 0

        Repeater {
            model: root.periodDays(14)

            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#181818"
                border.color: "#2b2b2b"
                border.width: 1

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.leftMargin: 8
                    anchors.topMargin: 8
                    text: modelData.today ? modelData.day : modelData.day
                    color: modelData.today ? "white" : "#f5f5f5"
                    font.pixelSize: 13
                    font.bold: modelData.today
                    font.family: Theme.fontFamily

                    Rectangle {
                        anchors.centerIn: parent
                        z: -1
                        width: 24
                        height: 24
                        radius: 12
                        color: modelData.today ? Theme.primary : "transparent"
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 34
                    spacing: 2

                    Repeater {
                        model: root.tasksForDate(modelData.key).slice(0, 4)

                        Rectangle {
                            width: parent.width - 6
                            x: 3
                            height: 18
                            radius: 3
                            color: modelData.color
                            opacity: 0.8

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 4
                                verticalAlignment: Text.AlignVCenter
                                text: "□ " + modelData.title
                                color: "#eeeeee"
                                font.pixelSize: 11
                                font.family: Theme.fontFamily
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import "../theme"

Rectangle {
    id: root
    color: "#181818"

    // Habits stored as JSON in QSettings via a helper property
    // Format: [{name, color, completions: ["yyyy-MM-dd", ...], archived}]
    property var habitData: []
    property string habitStatus: "Active"

    // Persist via Settings (uses QSettings internally)
    Settings {
        id: habitSettings
        property string habitsJson: "[]"
    }

    Component.onCompleted: {
        try {
            var parsed = JSON.parse(habitSettings.habitsJson)
            if (Array.isArray(parsed)) root.habitData = parsed
        } catch(e) { root.habitData = [] }
    }

    function saveHabits() {
        habitSettings.habitsJson = JSON.stringify(habitData)
    }

    function todayStr() { return Qt.formatDate(new Date(), "yyyy-MM-dd") }

    function dayStr(offset) {
        var d = new Date(); d.setDate(d.getDate() - 6 + offset)
        return Qt.formatDate(d, "yyyy-MM-dd")
    }

    function dayLabel(offset) {
        var labels = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        var d = new Date(); d.setDate(d.getDate() - 6 + offset)
        return labels[d.getDay()]
    }

    function dayNumber(offset) {
        var d = new Date(); d.setDate(d.getDate() - 6 + offset)
        return d.getDate()
    }

    function isCompleted(habit, dateStr) {
        return habit.completions && habit.completions.indexOf(dateStr) !== -1
    }

    function toggleHabitDay(habitIndex, dateStr) {
        var copy = JSON.parse(JSON.stringify(habitData))
        if (!copy[habitIndex].completions) copy[habitIndex].completions = []
        var idx = copy[habitIndex].completions.indexOf(dateStr)
        if (idx === -1) copy[habitIndex].completions.push(dateStr)
        else            copy[habitIndex].completions.splice(idx, 1)
        habitData = copy
        saveHabits()
    }

    function getStreak(habit) {
        var streak = 0; var d = new Date()
        while (true) {
            var s = Qt.formatDate(d, "yyyy-MM-dd")
            if (!habit.completions || habit.completions.indexOf(s) === -1) break
            streak++; d.setDate(d.getDate() - 1)
        }
        return streak
    }

    function visibleHabits() {
        return habitData.filter(function(h) {
            return habitStatus === "Active" ? !h.archived : !!h.archived
        })
    }

    property var habitColors: ["#3b82f6","#22c55e","#f59e0b","#ef4444","#bb68ef","#14b8a6","#f97316","#e879f9"]

    RowLayout {
        anchors.fill: parent; spacing:0

        // ── Main habits panel ────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true
            color: "#181818"; border.color:"#303030"; border.width:0

            ColumnLayout {
                anchors.fill: parent; anchors.margins:14; spacing:16

                // Header
                RowLayout { Layout.fillWidth:true
                    Text {
                        text: habitStatus + " Habits ⌄"; color:"#f5f5f5"
                        font.pixelSize:20; font.bold:true; font.family:Theme.fontFamily; Layout.fillWidth:true
                        MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:statusPopup.open() }
                    }
                    Text { text:"▦"; color:"#eeeeee"; font.pixelSize:18 }
                    Rectangle { width:28;height:28;radius:6; color:addHabHov.containsMouse?"#252525":"transparent"
                        Text { anchors.centerIn:parent;text:"+";color:Theme.primary;font.pixelSize:22;font.bold:true }
                        HoverHandler{id:addHabHov}
                        MouseArea { anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:addHabitPopup.open() }
                    }
                }

                // 7-day column headers
                RowLayout {
                    Layout.fillWidth:true; Layout.leftMargin:180; spacing:0
                    Repeater {
                        model: 7
                        ColumnLayout { Layout.fillWidth:true; spacing:4
                            Text { Layout.alignment:Qt.AlignHCenter; text:root.dayLabel(index); color:index===6?Theme.primary:"#6a6a6a"; font.pixelSize:10; font.family:Theme.fontFamily }
                            Text { Layout.alignment:Qt.AlignHCenter; text:root.dayNumber(index); color:index===6?Theme.primary:"#cccccc"; font.pixelSize:12; font.bold:true; font.family:Theme.fontFamily }
                        }
                    }
                }

                // Habits list
                Item { Layout.fillWidth:true; Layout.fillHeight:true

                    // Empty state
                    ColumnLayout { anchors.centerIn:parent; spacing:12; visible:root.visibleHabits().length===0
                        Rectangle { Layout.alignment:Qt.AlignHCenter; width:100;height:80;radius:20;color:"#222222"
                            Text { anchors.centerIn:parent;text:"◷";color:Theme.primary;font.pixelSize:52 } }
                        Text { Layout.alignment:Qt.AlignHCenter;text:"Develop a habit";color:"#f1f1f1";font.pixelSize:14;font.bold:true;font.family:Theme.fontFamily }
                        Text { Layout.alignment:Qt.AlignHCenter;text:"Every little bit counts";color:"#9a9a9a";font.pixelSize:12;font.family:Theme.fontFamily }
                    }

                    ListView {
                        anchors.fill:parent; clip:true; spacing:8
                        model: root.visibleHabits().length

                        delegate: Rectangle {
                            width:ListView.view.width; height:60; radius:10; color:"#202020"
                            border.color:"#2a2a2a"; border.width:1

                            property var h: root.visibleHabits()[index]
                            property string hColor: h.color || root.habitColors[index % root.habitColors.length]

                            // Left color accent
                            Rectangle { width:4;height:parent.height;radius:2;color:parent.hColor; opacity:0.8 }

                            RowLayout { anchors.fill:parent; anchors.leftMargin:12; anchors.rightMargin:12; spacing:8

                                // Habit info
                                ColumnLayout { Layout.preferredWidth:160; spacing:2
                                    Text { text:h.name; color:"#f0f0f0"; font.pixelSize:13; font.bold:true; font.family:Theme.fontFamily; elide:Text.ElideRight }
                                    RowLayout { spacing:4
                                        Text { text:"🔥"; font.pixelSize:10 }
                                        Text { text:root.getStreak(h)+" day streak"; color:"#888888"; font.pixelSize:10; font.family:Theme.fontFamily }
                                    }
                                }

                                // 7 day checkboxes
                                Repeater {
                                    model: 7
                                    Rectangle {
                                        Layout.fillWidth:true; width:34;height:34;radius:8
                                        property string ds: root.dayStr(index)
                                        property bool done: root.isCompleted(h, ds)
                                        color: done ? Qt.rgba(
                                            parseInt(hColor.slice(1,3),16)/255,
                                            parseInt(hColor.slice(3,5),16)/255,
                                            parseInt(hColor.slice(5,7),16)/255, 0.3) : "#1a1a1a"
                                        border.color: done ? hColor : "#333333"; border.width:1.5

                                        Text { anchors.centerIn:parent; visible:done; text:"✓"; color:hColor; font.pixelSize:14; font.bold:true }

                                        MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                            onClicked:{
                                                var realIdx = root.habitData.indexOf(root.visibleHabits()[parent.parent.parent.parent.index])
                                                if(realIdx!==-1) root.toggleHabitDay(realIdx, ds)
                                            }
                                        }
                                    }
                                }

                                // Archive/Delete button
                                Rectangle { width:24;height:24;radius:5; color:habitMenuHov.containsMouse?"#2a2a2a":"transparent"
                                    Text { anchors.centerIn:parent;text:"…";color:"#666666";font.pixelSize:14 }
                                    HoverHandler{id:habitMenuHov}
                                    MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                        onClicked:{
                                            var realIdx = root.habitData.indexOf(root.visibleHabits()[index])
                                            if(realIdx!==-1){
                                                var copy=JSON.parse(JSON.stringify(root.habitData))
                                                copy[realIdx].archived = !copy[realIdx].archived
                                                root.habitData=copy; root.saveHabits()
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

        // ── Stats sidebar ────────────────────────────────────────────
        Rectangle {
            Layout.preferredWidth:300; Layout.fillHeight:true
            color:"#161616"; border.color:"#252525"; border.width:1

            ColumnLayout { anchors.fill:parent; anchors.margins:16; spacing:16

                Text { text:"Stats"; color:"#f0f0f0"; font.pixelSize:18; font.bold:true; font.family:Theme.fontFamily }

                // Completion rate today
                Rectangle { Layout.fillWidth:true; height:70; radius:10; color:"#1e1e1e"; border.color:"#2a2a2a"; border.width:1
                    ColumnLayout { anchors.fill:parent; anchors.margins:14; spacing:4
                        Text { text:"Today's Completion"; color:"#777777"; font.pixelSize:11; font.family:Theme.fontFamily }
                        Text {
                            text: {
                                var vis=root.visibleHabits(); if(vis.length===0) return "0%"
                                var done=0; var today=root.todayStr()
                                for(var i=0;i<vis.length;i++){if(root.isCompleted(vis[i],today))done++}
                                return Math.round(done/vis.length*100)+"%"
                            }
                            color:"#f0f0f0"; font.pixelSize:28; font.bold:true; font.family:Theme.fontFamily
                        }
                    }
                }

                // Per habit stats
                Text { text:"Habit Details"; color:"#777777"; font.pixelSize:12; font.bold:true; font.family:Theme.fontFamily }

                ListView { Layout.fillWidth:true; Layout.fillHeight:true; clip:true; spacing:8
                    model: root.visibleHabits().length
                    delegate: Rectangle { width:ListView.view.width; height:64; radius:8; color:"#1c1c1c"; border.color:"#252525"; border.width:1
                        property var hab: root.visibleHabits()[index]
                        property string hc: hab.color || root.habitColors[index % root.habitColors.length]
                        ColumnLayout { anchors.fill:parent; anchors.margins:12; spacing:6
                            RowLayout { Layout.fillWidth:true; spacing:6
                                Rectangle { width:8;height:8;radius:4; color:parent.parent.hc }
                                Text { text:hab.name; color:"#e0e0e0"; font.pixelSize:12; font.bold:true; font.family:Theme.fontFamily; Layout.fillWidth:true; elide:Text.ElideRight }
                            }
                            RowLayout { Layout.fillWidth:true; spacing:16
                                ColumnLayout { spacing:2
                                    Text { text:"Streak"; color:"#555555"; font.pixelSize:9; font.family:Theme.fontFamily }
                                    Text { text:root.getStreak(hab)+"d"; color:parent.parent.hc; font.pixelSize:14; font.bold:true; font.family:Theme.fontFamily }
                                }
                                ColumnLayout { spacing:2
                                    Text { text:"This Week"; color:"#555555"; font.pixelSize:9; font.family:Theme.fontFamily }
                                    Text {
                                        text:{
                                            var c=0; for(var j=0;j<7;j++){if(root.isCompleted(hab,root.dayStr(j)))c++}
                                            return c+"/7"
                                        }
                                        color:"#cccccc"; font.pixelSize:14; font.bold:true; font.family:Theme.fontFamily
                                    }
                                }
                                ColumnLayout { spacing:2
                                    Text { text:"Total"; color:"#555555"; font.pixelSize:9; font.family:Theme.fontFamily }
                                    Text { text:(hab.completions?hab.completions.length:0)+""; color:"#cccccc"; font.pixelSize:14; font.bold:true; font.family:Theme.fontFamily }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Status popup ─────────────────────────────────────────────────
    Popup { id:statusPopup; parent:Overlay.overlay; modal:false; width:164; height:78; padding:0; x:78; y:39
        closePolicy:Popup.CloseOnEscape|Popup.CloseOnPressOutside
        background:Rectangle{color:"#222222";radius:10;border.color:"#3b3b3b";border.width:1}
        ColumnLayout { anchors.fill:parent; anchors.margins:8; spacing:0
            Repeater { model:["Active","Archived"]
                Rectangle { Layout.fillWidth:true; height:30; radius:6; color:stMouse.containsMouse?"#303030":"transparent"
                    RowLayout { anchors.fill:parent; anchors.leftMargin:8; anchors.rightMargin:8
                        Text { text:modelData; color:root.habitStatus===modelData?Theme.primary:"#f1f1f1"; font.pixelSize:13; font.family:Theme.fontFamily; Layout.fillWidth:true }
                        Text { text:"✓"; visible:root.habitStatus===modelData; color:Theme.primary; font.pixelSize:12 }
                    }
                    HoverHandler{id:stMouse}
                    MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:{root.habitStatus=modelData;statusPopup.close()}}
                }
            }
        }
    }

    // ── Add habit popup ──────────────────────────────────────────────
    Popup { id:addHabitPopup; parent:Overlay.overlay; modal:true; width:340; padding:0
        property string selectedColor: "#3b82f6"
        x:(parent.width-width)/2; y:90
        closePolicy:Popup.CloseOnEscape|Popup.CloseOnPressOutside
        Overlay.modal:Rectangle{color:"#88000000"}
        onOpened:{ habitNameInput.text=""; habitNameInput.forceActiveFocus() }
        background:Rectangle{color:"#252525";radius:12;border.color:"#3b3b3b";border.width:1}
        ColumnLayout { anchors.fill:parent; anchors.margins:20; spacing:14
            Text { text:"New Habit"; color:"#f5f5f5"; font.pixelSize:16; font.bold:true; font.family:Theme.fontFamily }
            TextField { id:habitNameInput; Layout.fillWidth:true; placeholderText:"Habit name (e.g. Exercise 30min)"; color:"#f5f5f5"; placeholderTextColor:"#666666"; font.pixelSize:13; font.family:Theme.fontFamily
                background:Rectangle{color:"#1e1e1e";radius:7;border.color:"#333333";border.width:1}
                padding:10
                onAccepted:addHabitPopup.create() }
            Text { text:"Color"; color:"#999999"; font.pixelSize:12; font.family:Theme.fontFamily }
            Flow { Layout.fillWidth:true; spacing:8
                Repeater { model:root.habitColors
                    Rectangle { width:24;height:24;radius:12; color:modelData; border.color:addHabitPopup.selectedColor===modelData?"white":"transparent"; border.width:2
                        MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:addHabitPopup.selectedColor=modelData}
                    }
                }
            }
            RowLayout { Layout.fillWidth:true; spacing:10
                Item{Layout.fillWidth:true}
                Rectangle{width:80;height:32;radius:7;color:cnHov.containsMouse?"#333333":"transparent";border.color:"#333333";border.width:1
                    Text{anchors.centerIn:parent;text:"Cancel";color:"#bdbdbd";font.pixelSize:13;font.family:Theme.fontFamily}
                    HoverHandler{id:cnHov}
                    MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:addHabitPopup.close()}}
                Rectangle{width:80;height:32;radius:7; color:habitNameInput.text.trim()===""?"#303030":Theme.primary; opacity:habitNameInput.text.trim()===""?0.6:1
                    Text{anchors.centerIn:parent;text:"Add";color:"white";font.pixelSize:13;font.bold:true;font.family:Theme.fontFamily}
                    MouseArea{anchors.fill:parent;cursorShape:habitNameInput.text.trim()===""?Qt.ArrowCursor:Qt.PointingHandCursor;onClicked:addHabitPopup.create()}}
            }
        }
        function create() {
            var name=habitNameInput.text.trim(); if(name==="")return
            var copy=JSON.parse(JSON.stringify(root.habitData))
            copy.push({name:name,color:addHabitPopup.selectedColor,completions:[],archived:false})
            root.habitData=copy; root.saveHabits(); addHabitPopup.close()
        }
    }
}
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    color: "#181818"
    border.color: "#303030"
    border.width: 1

    property bool hasSelection: taskListViewModel.selectedTaskIndex >= 0

    // ── Subtask helpers ─────────────────────────────────────────────────
    function lines()          { return taskListViewModel.selectedTaskDescription.split("\n") }
    function isSubtaskLine(l) { return l.indexOf("- [ ] ")===0||l.indexOf("- [x] ")===0 }
    function subtaskTitle(l)  { return l.substring(6) }

    function subtasks() {
        var result=[]; var src=lines()
        for(var i=0;i<src.length;i++){
            if(isSubtaskLine(src[i]))
                result.push({lineIndex:i,title:subtaskTitle(src[i]),done:src[i].indexOf("- [x] ")===0})
        }
        return result
    }

    function notesText() {
        var result=[]; var src=lines()
        for(var i=0;i<src.length;i++){ if(!isSubtaskLine(src[i]))result.push(src[i]) }
        return result.join("\n").trim()
    }

    function rebuildDescription(newNotes) {
        var src=lines(); var taskLines=[]
        for(var i=0;i<src.length;i++){ if(isSubtaskLine(src[i]))taskLines.push(src[i]) }
        var pieces=[]
        if(taskLines.length>0)pieces.push(taskLines.join("\n"))
        if(newNotes.trim()!=="")pieces.push(newNotes.trim())
        taskListViewModel.updateSelectedTaskDescription(pieces.join("\n"))
    }

    function addSubtask(title) {
        var clean=title.trim(); if(clean==="")return
        var cur=taskListViewModel.selectedTaskDescription.trim()
        taskListViewModel.updateSelectedTaskDescription(cur===""?"- [ ] "+clean:cur+"\n- [ ] "+clean)
    }

    function toggleSubtask(lineIndex,done) {
        var src=lines()
        if(lineIndex<0||lineIndex>=src.length)return
        src[lineIndex]=(done?"- [ ] ":"- [x] ")+subtaskTitle(src[lineIndex])
        taskListViewModel.updateSelectedTaskDescription(src.join("\n"))
    }

    // ── Date picker popup (reusable inline) ────────────────────────────
    Popup {
        id: detailDatePicker
        parent: Overlay.overlay
        modal: false; width:320; padding:0; z:2000
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color:"#242424"; radius:10; border.color:"#3a3a3a"; border.width:1 }

        function openBelow(anchor) {
            var pos = anchor.mapToItem(Overlay.overlay,0,0)
            x = Math.max(12, Math.min(pos.x, Overlay.overlay.width - width - 12))
            y = pos.y + anchor.height + 6
            if (y + 380 > Overlay.overlay.height) y = pos.y - 380 - 6
            open()
        }

        ColumnLayout { anchors.fill:parent; anchors.margins:12; spacing:10

            // Shortcuts
            RowLayout { Layout.fillWidth:true; spacing:4
                Repeater {
                    model:[{l:"Today",d:0},{l:"Tomorrow",d:1},{l:"+7",d:7},{l:"Clear",d:-1}]
                    Rectangle { Layout.fillWidth:true; height:26; radius:6; color:dShov.containsMouse?"#383838":"#2a2a2a"; border.color:"#3a3a3a"; border.width:1
                        Text { anchors.centerIn:parent; text:modelData.l; color:"#cccccc"; font.pixelSize:11; font.family:Theme.fontFamily }
                        HoverHandler{id:dShov}
                        MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                            onClicked:{
                                if(modelData.d===-1){ taskListViewModel.updateSelectedTaskDueAt(""); detailDatePicker.close(); return }
                                var d=new Date(); d.setDate(d.getDate()+modelData.d)
                                var s=Qt.formatDate(d,"yyyy-MM-dd")
                                taskListViewModel.updateSelectedTaskDueAt(s)
                                detCalHelper.currentMonth=d; detCalHelper.selectDate(s)
                                detailDatePicker.close()
                            }
                        }
                    }
                }
            }

            // Month nav
            RowLayout { Layout.fillWidth:true; spacing:6
                Text { text:"◀"; color:Theme.textMuted; font.pixelSize:14
                    MouseArea{anchors.fill:parent;anchors.margins:-6;cursorShape:Qt.PointingHandCursor;onClicked:{var d=detCalHelper.currentMonth;d.setMonth(d.getMonth()-1);detCalHelper.currentMonth=d}} }
                Text { text:detCalHelper.monthYearString; color:Theme.textPrimary; font.pixelSize:13; font.bold:true; font.family:Theme.fontFamily; Layout.fillWidth:true; horizontalAlignment:Text.AlignHCenter }
                Text { text:"▶"; color:Theme.textMuted; font.pixelSize:14
                    MouseArea{anchors.fill:parent;anchors.margins:-6;cursorShape:Qt.PointingHandCursor;onClicked:{var d=detCalHelper.currentMonth;d.setMonth(d.getMonth()+1);detCalHelper.currentMonth=d}} }
            }

            // Day headers
            GridLayout { Layout.fillWidth:true; columns:7; columnSpacing:2; rowSpacing:2
                Repeater { model:["Su","Mo","Tu","We","Th","Fr","Sa"]
                    Text { text:modelData; color:Theme.textMuted; font.pixelSize:10; font.family:Theme.fontFamily; Layout.fillWidth:true; horizontalAlignment:Text.AlignHCenter } }
            }

            // Days grid
            GridLayout { Layout.fillWidth:true; columns:7; columnSpacing:2; rowSpacing:2
                Repeater { id:detDaysRep; model:detCalHelper.days
                    Rectangle { Layout.fillWidth:true; Layout.preferredHeight:32; radius:4
                        color:{ if(!modelData.isCurrentMonth)return"transparent"; if(modelData.isSelected)return Theme.primary; if(modelData.isToday)return Theme.primary+"33"; return"transparent" }
                        border.color:modelData.isToday?Theme.primary:"transparent"; border.width:1
                        Text { anchors.centerIn:parent; text:modelData.day; font.pixelSize:12; font.family:Theme.fontFamily; font.bold:modelData.isToday||modelData.isSelected
                            color:{ if(!modelData.isCurrentMonth)return Theme.textMuted; if(modelData.isSelected)return"white"; if(modelData.isToday)return Theme.primary; return Theme.textPrimary } }
                        MouseArea { anchors.fill:parent; enabled:modelData.isCurrentMonth; cursorShape:enabled?Qt.PointingHandCursor:Qt.ArrowCursor
                            onClicked:{ taskListViewModel.updateSelectedTaskDueAt(modelData.dateString); detCalHelper.selectDate(modelData.dateString); detailDatePicker.close() } }
                    }
                }
            }

            RowLayout { Layout.fillWidth:true; spacing:4
                Button { text:"Today"; Layout.fillWidth:true; palette.buttonText:Theme.textPrimary
                    onClicked:{ var t=new Date(); var s=Qt.formatDate(t,"yyyy-MM-dd"); taskListViewModel.updateSelectedTaskDueAt(s); detCalHelper.currentMonth=t; detCalHelper.selectDate(s); detailDatePicker.close() } }
                Button { text:"Clear"; Layout.fillWidth:true; palette.buttonText:Theme.textPrimary
                    onClicked:{ taskListViewModel.updateSelectedTaskDueAt(""); detailDatePicker.close() } }
            }
        }

        QtObject {
            id: detCalHelper
            property date currentMonth: new Date()
            property var days: []
            onCurrentMonthChanged: updateDays()
            function updateDays() {
                var month=currentMonth.getMonth(); var year=currentMonth.getFullYear()
                var first=new Date(year,month,1); var start=new Date(first); start.setDate(start.getDate()-first.getDay())
                var arr=[]; var d=new Date(start); var today=new Date()
                var sel=taskListViewModel.selectedTaskDueAt
                for(var i=0;i<42;i++){
                    arr.push({day:d.getDate(),dateString:Qt.formatDate(d,"yyyy-MM-dd"),
                        isCurrentMonth:d.getMonth()===month,
                        isToday:d.toDateString()===today.toDateString(),
                        isSelected:Qt.formatDate(d,"yyyy-MM-dd")===sel})
                    d.setDate(d.getDate()+1)
                }
                days=arr; detDaysRep.model=arr
            }
            function selectDate(s){
                var arr=[];for(var i=0;i<days.length;i++){var c=days[i];c.isSelected=(c.dateString===s);arr.push(c)}days=arr;detDaysRep.model=arr
            }
            property string monthYearString:{
                var months=["January","February","March","April","May","June","July","August","September","October","November","December"]
                return months[currentMonth.getMonth()]+" "+currentMonth.getFullYear()
            }
            Component.onCompleted: updateDays()
        }
    }

    // ── Tag edit popup ─────────────────────────────────────────────────
    Popup {
        id: tagEditPopup
        parent: Overlay.overlay; modal:false; width:280; padding:0; z:2001
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color:"#222222"; radius:10; border.color:"#3a3a3a"; border.width:1 }

        ColumnLayout { anchors.fill:parent; anchors.margins:14; spacing:10
            Text { text:"Edit Tags"; color:"#f0f0f0"; font.pixelSize:14; font.bold:true; font.family:Theme.fontFamily }

            Flow { Layout.fillWidth:true; spacing:6
                Repeater {
                    model: taskListViewModel.getAllTags()
                    Rectangle {
                        property bool isSel: { var tgs=taskListViewModel.selectedTaskTags; return tgs&&tgs.indexOf(modelData)!==-1 }
                        property color tc: { var s=taskListViewModel.getSavedTagColor(modelData); return s!==""?s:Theme.primary }
                        height:24; width:tgLbl.width+18; radius:5
                        color:isSel?Qt.rgba(tc.r,tc.g,tc.b,0.22):"#2a2a2a"
                        border.color:isSel?tc:"#3a3a3a"; border.width:1
                        Text { id:tgLbl; anchors.centerIn:parent; text:modelData; color:parent.isSel?parent.tc:"#aaaaaa"; font.pixelSize:11; font.family:Theme.fontFamily }
                        MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                            onClicked:{
                                var tgs=taskListViewModel.selectedTaskTags?taskListViewModel.selectedTaskTags.slice():[]
                                var idx=tgs.indexOf(modelData)
                                if(idx===-1)tgs.push(modelData); else tgs.splice(idx,1)
                                taskListViewModel.updateSelectedTaskTags(tgs.join(","))
                            }
                        }
                    }
                }
            }

            TextField { Layout.fillWidth:true
                placeholderText:"Add tag name…"; color:"#f0f0f0"; placeholderTextColor:"#555555"; font.pixelSize:12; font.family:Theme.fontFamily
                background:Rectangle{color:"#1a1a1a";radius:6;border.color:"#333333";border.width:1}
                padding:6
                onAccepted:{
                    if(text.trim()!==""){
                        var tgs=taskListViewModel.selectedTaskTags?taskListViewModel.selectedTaskTags.slice():[]
                        tgs.push(text.trim()); taskListViewModel.updateSelectedTaskTags(tgs.join(","))
                        text=""
                    }
                }
            }

            Rectangle { Layout.alignment:Qt.AlignRight; width:60;height:28;radius:6; color:Theme.primary
                Text{anchors.centerIn:parent;text:"Done";color:"white";font.pixelSize:12;font.family:Theme.fontFamily}
                MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:tagEditPopup.close()}
            }
        }
    }

    // ── List picker popup ──────────────────────────────────────────────
    Popup {
        id: listEditPopup
        parent: Overlay.overlay; modal:false; width:200; padding:8; z:2001
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color:"#222222"; radius:10; border.color:"#3a3a3a"; border.width:1 }

        ColumnLayout { width:parent.width; spacing:4
            Repeater {
                model: taskListViewModel.getAllLists()
                Rectangle { width:parent.parent.width-16; height:32; radius:6
                    color:taskListViewModel.selectedTaskList===modelData?"#2a3050":(listItemHov.containsMouse?"#2a2a2a":"transparent")
                    border.color:taskListViewModel.selectedTaskList===modelData?Theme.primary:"transparent"; border.width:1
                    Text { anchors.verticalCenter:parent.verticalCenter; anchors.left:parent.left; anchors.leftMargin:10
                        text:modelData; color:"#e0e0e0"; font.pixelSize:13; font.family:Theme.fontFamily }
                    Text { visible:taskListViewModel.selectedTaskList===modelData; anchors.verticalCenter:parent.verticalCenter; anchors.right:parent.right; anchors.rightMargin:10
                        text:"✓"; color:Theme.primary; font.pixelSize:12 }
                    HoverHandler{id:listItemHov}
                    MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:{taskListViewModel.updateSelectedTaskList(modelData);listEditPopup.close()}}
                }
            }
        }
    }

    // ── Empty state ────────────────────────────────────────────────────
    Item {
        anchors.fill: parent; visible: !root.hasSelection
        ColumnLayout { anchors.centerIn:parent; spacing:16
            Text { Layout.alignment:Qt.AlignHCenter; text:"✧"; color:"#252525"; font.pixelSize:90 }
            Text { Layout.alignment:Qt.AlignHCenter; text:"Select a task"; color:"#777777"; font.pixelSize:14; font.family:Theme.fontFamily }
        }
    }

    // ── Detail panel ───────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent; visible: root.hasSelection; spacing:0

        // ── Top action bar ───────────────────────────────────────────
        RowLayout {
            Layout.fillWidth:true; Layout.preferredHeight:44
            Layout.leftMargin:20; Layout.rightMargin:12; spacing:10

            // Completion checkbox
            Rectangle {
                width:16;height:16;radius:3
                color:taskListViewModel.selectedTaskDueAt!==""&&isOverdue?"#3a1a1a":"transparent"
                border.color:{ var p=taskListViewModel.selectedTaskPriority; if(p===3)return"#ef4444"; if(p===2)return"#f59e0b"; if(p===1)return"#3b82f6"; return"#7a7f89" }
                border.width:1.4
                property bool isOverdue:{ var d=taskListViewModel.selectedTaskDueAt; if(!d)return false; return new Date(d)<new Date() }
                MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                    onClicked:taskListViewModel.toggleTaskCompletion(taskListViewModel.selectedTaskIndex) }
            }

            // Due date button — opens picker
            Rectangle {
                id: dueDateBtn
                height:28; width:dueDateText.width+22; radius:6
                color:dueDateHov.containsMouse?"#252525":"transparent"
                border.color:"#333333"; border.width:1

                property bool hasDate: taskListViewModel.selectedTaskDueAt !== ""
                property bool overdue: {
                    if(!hasDate)return false
                    var d=new Date(taskListViewModel.selectedTaskDueAt); d.setHours(0,0,0,0)
                    var t=new Date(); t.setHours(0,0,0,0)
                    return d<t
                }

                RowLayout { anchors.fill:parent; anchors.leftMargin:8; anchors.rightMargin:8; spacing:5
                    SidebarIcon { width:12;height:12; iconName:"calendar"; iconColor:parent.overdue?"#ef4444":(parent.hasDate?Theme.primary:"#777777"); strokeWidth:1.5 }
                    Text { id:dueDateText
                        text:dueDateBtn.hasDate?taskListViewModel.selectedTaskDueAt:"No date"
                        color:dueDateBtn.overdue?"#ef4444":(dueDateBtn.hasDate?Theme.primary:"#777777")
                        font.pixelSize:12; font.family:Theme.fontFamily }
                }

                HoverHandler{id:dueDateHov}
                MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                    onClicked:{ detCalHelper.updateDays(); detailDatePicker.openBelow(dueDateBtn) }
                }
            }

            Item { Layout.fillWidth:true }

            // Pin
            Rectangle { width:28;height:28;radius:6; color:pinHov.containsMouse?"#252525":"transparent"; border.color:taskListViewModel.selectedTaskIndex>=0?"#2a3060":"transparent"; border.width:1
                Text { anchors.centerIn:parent; text:"📌"; font.pixelSize:12 }
                HoverHandler{id:pinHov}
                MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:taskListViewModel.updateSelectedTaskPinned(!taskListViewModel.selectedTaskPinned)}
            }

            // Delete
            Rectangle { width:28;height:28;radius:6; color:delTopHov.containsMouse?"#3a1a1a":"transparent"
                SidebarIcon { anchors.centerIn:parent;width:15;height:15; iconName:"trash"; iconColor:delTopHov.containsMouse?"#ef4444":"#a8a8a8"; strokeWidth:1.5 }
                HoverHandler{id:delTopHov}
                MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:taskListViewModel.softDeleteTask(taskListViewModel.selectedTaskIndex)}
            }
        }

        Rectangle { Layout.fillWidth:true; height:1; color:"#303030" }

        // ── Scrollable body ──────────────────────────────────────────
        Flickable {
            Layout.fillWidth:true; Layout.fillHeight:true
            contentWidth:width; contentHeight:detailColumn.height+24; clip:true

            ColumnLayout {
                id: detailColumn; width:parent.width; spacing:18

                // Title (editable)
                TextArea {
                    id: titleArea
                    Layout.fillWidth:true; Layout.leftMargin:20; Layout.rightMargin:20; Layout.topMargin:16
                    text: taskListViewModel.selectedTaskTitle
                    color:"#f5f5f5"; font.pixelSize:20; font.bold:true; font.family:Theme.fontFamily
                    wrapMode:TextArea.Wrap; selectByMouse:true
                    background: Rectangle { color:"transparent" }
                    onEditingFinished: {
                        if(text.trim()!==""&&text!==taskListViewModel.selectedTaskTitle)
                            taskListViewModel.renameTask(taskListViewModel.selectedTaskIndex,text.trim())
                    }
                }

                // Tags row
                RowLayout {
                    Layout.fillWidth:true; Layout.leftMargin:20; Layout.rightMargin:20; spacing:8
                    Repeater {
                        model: taskListViewModel.selectedTaskTags
                        Rectangle {
                            height:22; width:tgLabel.width+18; radius:11
                            property color tc: { var s=taskListViewModel.getSavedTagColor(modelData); return s!==""?Qt.color(s):Qt.rgba(0.5,0.3,0.8,1) }
                            color:Qt.rgba(tc.r,tc.g,tc.b,0.2); border.color:Qt.rgba(tc.r,tc.g,tc.b,0.5); border.width:1
                            Text { id:tgLabel; anchors.centerIn:parent; text:modelData; color:Qt.rgba(parent.tc.r,parent.tc.g,parent.tc.b,0.9); font.pixelSize:11; font.family:Theme.fontFamily }
                        }
                    }
                    Rectangle { id:addTagBtn; height:22;width:22;radius:11; color:addTagHov.containsMouse?"#252525":"transparent"; border.color:"#3a3a3a"; border.width:1
                        Text { anchors.centerIn:parent;text:"+";color:Theme.primary;font.pixelSize:14 }
                        HoverHandler{id:addTagHov}
                        MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor
                            onClicked:{var pos=addTagBtn.mapToItem(Overlay.overlay,0,0);tagEditPopup.x=Math.max(12,pos.x-100);tagEditPopup.y=pos.y+30;tagEditPopup.open()}}
                    }
                }

                // Subtasks
                ColumnLayout {
                    Layout.fillWidth:true; Layout.leftMargin:20; Layout.rightMargin:20; spacing:4

                    Repeater {
                        model: root.subtasks()
                        RowLayout { Layout.fillWidth:true; height:34; spacing:10
                            Rectangle { width:15;height:15;radius:3
                                color:modelData.done?"#3b3b3b":"transparent"; border.color:modelData.done?"#3b3b3b":"#777777"; border.width:1
                                Text { anchors.centerIn:parent; visible:modelData.done; text:"✓"; color:"#777777"; font.pixelSize:10 }
                                MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:root.toggleSubtask(modelData.lineIndex,modelData.done)}
                            }
                            Text { text:modelData.title; color:modelData.done?"#777777":"#f2f2f2"; font.pixelSize:14; font.strikeout:modelData.done; font.family:Theme.fontFamily; Layout.fillWidth:true; elide:Text.ElideRight }
                            Rectangle { width:20;height:20;radius:4; color:stDelHov.containsMouse?"#3a1a1a":"transparent"
                                Text{anchors.centerIn:parent;text:"×";color:stDelHov.containsMouse?"#ef4444":"#555555";font.pixelSize:14}
                                HoverHandler{id:stDelHov}
                                MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor
                                    onClicked:{
                                        var src=root.lines(); src.splice(modelData.lineIndex,1)
                                        taskListViewModel.updateSelectedTaskDescription(src.join("\n"))
                                    }
                                }
                            }
                        }
                    }

                    RowLayout { Layout.fillWidth:true; spacing:8
                        Text { text:"↳"; color:"#777777"; font.pixelSize:16 }
                        TextField { id:subtaskInput; Layout.fillWidth:true
                            placeholderText:"Add Subtask"; color:"#f5f5f5"; placeholderTextColor:"#777777"
                            background:null; font.pixelSize:14; font.family:Theme.fontFamily
                            onAccepted:{ root.addSubtask(text); text="" }
                        }
                    }
                }

                Rectangle { Layout.fillWidth:true; height:1; color:"#2a2a2a" }

                // ── Properties ───────────────────────────────────────
                ColumnLayout { Layout.fillWidth:true; Layout.leftMargin:20; Layout.rightMargin:20; spacing:12

                    // List
                    RowLayout { Layout.fillWidth:true; spacing:10
                        Text { text:"List"; color:"#666666"; font.pixelSize:12; font.family:Theme.fontFamily; Layout.preferredWidth:72 }
                        Rectangle { id:listPickerBtn; height:30; Layout.fillWidth:true; radius:7
                            color:listPickerHov.containsMouse?"#222222":"#1c1c1c"; border.color:"#333333"; border.width:1
                            RowLayout { anchors.fill:parent; anchors.leftMargin:10; anchors.rightMargin:8; spacing:6
                                SidebarIcon { width:13;height:13; iconName:"list"; iconColor:"#888888"; strokeWidth:1.5 }
                                Text { text:taskListViewModel.selectedTaskList; color:"#e0e0e0"; font.pixelSize:12; font.family:Theme.fontFamily; Layout.fillWidth:true; elide:Text.ElideRight }
                                Text { text:"⌄"; color:"#666666"; font.pixelSize:12 }
                            }
                            HoverHandler{id:listPickerHov}
                            MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor
                                onClicked:{var pos=listPickerBtn.mapToItem(Overlay.overlay,0,0);listEditPopup.x=Math.max(12,Math.min(pos.x,Overlay.overlay.width-listEditPopup.width-12));listEditPopup.y=pos.y+listPickerBtn.height+4;listEditPopup.open()}}
                        }
                    }

                    // Due date (secondary row)
                    RowLayout { Layout.fillWidth:true; spacing:10
                        Text { text:"Due"; color:"#666666"; font.pixelSize:12; font.family:Theme.fontFamily; Layout.preferredWidth:72 }
                        Rectangle { id:dueDateBtn2; height:30; Layout.fillWidth:true; radius:7
                            color:dueDateHov2.containsMouse?"#222222":"#1c1c1c"; border.color:"#333333"; border.width:1
                            RowLayout { anchors.fill:parent; anchors.leftMargin:10; anchors.rightMargin:8; spacing:6
                                SidebarIcon { width:13;height:13; iconName:"calendar"; iconColor:taskListViewModel.selectedTaskDueAt!==""?Theme.primary:"#888888"; strokeWidth:1.5 }
                                Text { text:taskListViewModel.selectedTaskDueAt!==""?taskListViewModel.selectedTaskDueAt:"Set date"; color:taskListViewModel.selectedTaskDueAt!==""?Theme.primary:"#666666"; font.pixelSize:12; font.family:Theme.fontFamily; Layout.fillWidth:true }
                                Text { text:"⌄"; color:"#666666"; font.pixelSize:12 }
                            }
                            HoverHandler{id:dueDateHov2}
                            MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:{detCalHelper.updateDays();detailDatePicker.openBelow(dueDateBtn2)}}
                        }
                    }

                    // Priority
                    RowLayout { Layout.fillWidth:true; spacing:10
                        Text { text:"Priority"; color:"#666666"; font.pixelSize:12; font.family:Theme.fontFamily; Layout.preferredWidth:72 }
                        RowLayout { spacing:6
                            Repeater {
                                model:[{v:3,c:"#ef4444",l:"High"},{v:2,c:"#f59e0b",l:"Med"},{v:1,c:"#3b82f6",l:"Low"},{v:0,c:"#6b7280",l:"None"}]
                                Rectangle { height:30; width:priLabel.width+20; radius:7
                                    color:taskListViewModel.selectedTaskPriority===modelData.v?modelData.c+"22":"#1c1c1c"
                                    border.color:taskListViewModel.selectedTaskPriority===modelData.v?modelData.c:"#333333"; border.width:1
                                    RowLayout { anchors.centerIn:parent; spacing:5
                                        SidebarIcon { width:12;height:12; iconName:modelData.v>0?"flag":"flag-empty"; iconColor:modelData.c; strokeWidth:1.5 }
                                        Text { id:priLabel; text:modelData.l; color:taskListViewModel.selectedTaskPriority===modelData.v?modelData.c:"#888888"; font.pixelSize:11; font.family:Theme.fontFamily }
                                    }
                                    MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:taskListViewModel.updateSelectedTaskPriority(modelData.v)}
                                }
                            }
                        }
                    }

                    // Tags (text field for direct edit)
                    RowLayout { Layout.fillWidth:true; spacing:10
                        Text { text:"Tags"; color:"#666666"; font.pixelSize:12; font.family:Theme.fontFamily; Layout.preferredWidth:72 }
                        TextField { Layout.fillWidth:true
                            text:taskListViewModel.selectedTaskTags?taskListViewModel.selectedTaskTags.join(", "):""
                            placeholderText:"comma-separated"; color:"#f5f5f5"; placeholderTextColor:"#777777"
                            background:Rectangle{color:"#1c1c1c";radius:6;border.color:"#333333";border.width:1}
                            font.pixelSize:12; font.family:Theme.fontFamily; padding:6
                            onEditingFinished:taskListViewModel.updateSelectedTaskTags(text)
                        }
                    }
                }

                // ── Notes ────────────────────────────────────────────
                Rectangle { Layout.fillWidth:true; height:1; color:"#2a2a2a" }

                TextArea {
                    id: notesInput
                    Layout.fillWidth:true; Layout.preferredHeight:160; Layout.leftMargin:20; Layout.rightMargin:20
                    text: root.notesText()
                    placeholderText:"Add notes"; color:"#f5f5f5"; placeholderTextColor:"#777777"
                    wrapMode:TextArea.Wrap; font.pixelSize:14; font.family:Theme.fontFamily; selectByMouse:true
                    background:Rectangle{color:"#181818";radius:8;border.color:"#2a2a2a";border.width:1}
                    onActiveFocusChanged:{ if(!activeFocus)root.rebuildDescription(text) }
                }

                Item { height:8 }
            }
        }

        // ── Bottom bar ───────────────────────────────────────────────
        Rectangle { Layout.fillWidth:true; height:1; color:"#252525" }
        RowLayout {
            Layout.fillWidth:true; Layout.preferredHeight:40
            Layout.leftMargin:20; Layout.rightMargin:16; spacing:14
            Text { text:"▰ "+taskListViewModel.selectedTaskList; color:"#5a5a5a"; font.pixelSize:12; font.family:Theme.fontFamily; Layout.fillWidth:true }
            Text { text:"A"; color:"#d8d8d8"; font.pixelSize:14 }
            Text { text:"◱"; color:"#d8d8d8"; font.pixelSize:16 }
            Text { text:"..."; color:"#d8d8d8"; font.pixelSize:18 }
        }
    }
}
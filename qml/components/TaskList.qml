import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    color: Theme.background

    // Determine if current list is a Notes list
    property bool isNotesList: {
        var lists = taskListViewModel.getAllLists()
        // We need listType - stored via naming convention or we track it
        return false // overridden by listTypeMap lookup below
    }

    property string currentListType: {
        root.refreshHack
        var lt = taskListViewModel.getListType(taskListViewModel.activeFilterList)
        return lt
    }

    property int refreshHack: 0

    Connections {
        target: taskListViewModel
        function onFilterChanged()  { root.refreshHack++ }
        function onTasksModified()  { root.refreshHack++ }
    }

    // ── view mode: "list" | "board" | "timeline" ──────────────────────
    property string viewMode: "list"

    onCurrentListTypeChanged: {
        if (currentListType === "Notes List") viewMode = "notes"
        else if (currentListType === "Board")  viewMode = "board"
        else                                   viewMode = "list"
    }

    // ── popups ─────────────────────────────────────────────────────────

    function openPopupNear(popup, anchorItem, alignRight) {
        if (!Overlay.overlay || !anchorItem) return
        popup.close()
        var margin = 12
        var gap = 8
        var anchorPos = anchorItem.mapToItem(Overlay.overlay, 0, 0)
        var rootPos   = root.mapToItem(Overlay.overlay, 0, 0)
        var leftBound  = Math.max(margin, rootPos.x + margin)
        var rightBound = Math.min(Overlay.overlay.width  - margin, rootPos.x + root.width - margin)
        var popupHeight = popup.implicitHeight > 0 ? popup.implicitHeight : popup.height
        var preferredX  = alignRight ? anchorPos.x + anchorItem.width - popup.width : anchorPos.x
        var belowY      = anchorPos.y + anchorItem.height + gap
        var spaceBelow  = Overlay.overlay.height - belowY - margin
        var spaceAbove  = anchorPos.y - margin
        popup.x = Math.max(leftBound, Math.min(preferredX, rightBound - popup.width))
        popup.y = spaceBelow < popupHeight && spaceAbove > spaceBelow
                ? Math.max(margin, anchorPos.y - popupHeight - gap)
                : Math.min(belowY, Overlay.overlay.height - popupHeight - margin)
        popup.open()
    }

    function openAddOptionsPopup(anchorItem) {
        datePicker.close()
        priorityPicker.close()
        openPopupNear(addOptionsPopup, anchorItem, true)
    }

    // ── Priority picker ────────────────────────────────────────────────
    Popup {
        id: priorityPicker
        parent: Overlay.overlay
        modal: false
        width: 220; height: 60; padding: 0; z: 1001
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color:"#1e1e2e"; radius: Theme.radiusMedium; border.color: Theme.divider; border.width:1 }

        RowLayout {
            anchors.fill: parent; anchors.margins: 8; spacing: 6
            Repeater {
                model: [
                    { label:"High", color:"#ef4444", value:3 },
                    { label:"Med",  color:"#f59e0b", value:2 },
                    { label:"Low",  color:"#3b82f6", value:1 },
                    { label:"None", color:"#475569", value:0 }
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true; height: 36; radius: Theme.radiusSmall
                    color: addBar.selectedPriority === modelData.value ? modelData.color + "33" : "transparent"
                    border.color: addBar.selectedPriority === modelData.value ? modelData.color : "transparent"
                    ColumnLayout { anchors.centerIn: parent; spacing: 2
                        SidebarIcon { Layout.alignment:Qt.AlignHCenter; Layout.preferredWidth:14; Layout.preferredHeight:14; iconName:"flag"; iconColor:modelData.color; strokeWidth:1.8 }
                        Text { Layout.alignment:Qt.AlignHCenter; text:modelData.label; color:Theme.textSecondary; font.pixelSize:9; font.family:Theme.fontFamily }
                    }
                    MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:{ addBar.selectedPriority = modelData.value; priorityPicker.close() } }
                }
            }
        }
    }

    // ── Date picker ────────────────────────────────────────────────────
    Popup {
        id: datePicker
        objectName: "datePicker"
        parent: Overlay.overlay
        modal: false; width: 320; height: Math.min(380, Overlay.overlay.height - 80)
        padding: 0; z: 1000
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color:"#242424"; radius:10; border.color:"#3a3a3a"; border.width:1 }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 12; spacing: 12

            Rectangle {
                Layout.fillWidth: true; height:30; radius:7; color:"#303030"
                RowLayout { anchors.fill:parent; anchors.margins:3; spacing:3
                    Rectangle { Layout.fillWidth:true; Layout.fillHeight:true; radius:6; color:"#3a3a3a"
                        Text { anchors.centerIn:parent; text:"Date"; color:"#f2f2f2"; font.pixelSize:12; font.family:Theme.fontFamily } }
                    Rectangle { Layout.fillWidth:true; Layout.fillHeight:true; radius:6; color:"transparent"
                        Text { anchors.centerIn:parent; text:"Duration"; color:"#a8a8a8"; font.pixelSize:12; font.family:Theme.fontFamily } }
                }
            }

            // Quick shortcuts
            RowLayout {
                Layout.fillWidth: true; spacing: 4
                Repeater {
                    model: [
                        { label:"Today",    days:0  },
                        { label:"Tomorrow", days:1  },
                        { label:"+7 days",  days:7  },
                        { label:"Clear",    days:-1 }
                    ]
                    Rectangle {
                        Layout.fillWidth:true; height:28; radius:6
                        color: shortcutHov.containsMouse ? "#383838" : "#2a2a2a"
                        border.color:"#3a3a3a"; border.width:1
                        Text { anchors.centerIn:parent; text:modelData.label; color:"#cccccc"; font.pixelSize:11; font.family:Theme.fontFamily }
                        HoverHandler { id: shortcutHov }
                        MouseArea {
                            anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.days === -1) {
                                    addBar.selectedDate = ""
                                    calHelper.selectDate("")
                                } else {
                                    var d = new Date()
                                    d.setDate(d.getDate() + modelData.days)
                                    var s = Qt.formatDate(d, "yyyy-MM-dd")
                                    addBar.selectedDate = s
                                    calHelper.currentMonth = d
                                    calHelper.selectDate(s)
                                }
                                datePicker.close()
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth:true; spacing:10
                Button { text:"◀"; flat:true; padding:4; contentItem: Text { text:parent.text; color:Theme.textMuted; font.pixelSize:14 }
                    onClicked: { var d=calHelper.currentMonth; d.setMonth(d.getMonth()-1); calHelper.currentMonth=d } }
                Text { text:calHelper.monthYearString; color:Theme.textPrimary; font.pixelSize:14; font.bold:true; font.family:Theme.fontFamily; Layout.fillWidth:true; horizontalAlignment:Text.AlignHCenter }
                Button { text:"▶"; flat:true; padding:4; contentItem: Text { text:parent.text; color:Theme.textMuted; font.pixelSize:14 }
                    onClicked: { var d=calHelper.currentMonth; d.setMonth(d.getMonth()+1); calHelper.currentMonth=d } }
            }

            GridLayout { Layout.fillWidth:true; columns:7; columnSpacing:2; rowSpacing:2
                Repeater { model:["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
                    delegate: Text { text:modelData; color:Theme.textMuted; font.pixelSize:11; font.bold:true; font.family:Theme.fontFamily; Layout.fillWidth:true; horizontalAlignment:Text.AlignHCenter; topPadding:4; bottomPadding:4 } }
            }

            GridLayout {
                Layout.fillWidth:true; columns:7; columnSpacing:2; rowSpacing:2
                Repeater {
                    id: daysRep
                    model: calHelper.days
                    delegate: Rectangle {
                        Layout.fillWidth:true; Layout.preferredHeight:36; radius:4
                        color: {
                            if (!modelData.isCurrentMonth) return "transparent"
                            if (modelData.isSelected)      return Theme.primary
                            if (modelData.isToday)         return Theme.primary + "33"
                            return "transparent"
                        }
                        border.color: modelData.isToday ? Theme.primary : "transparent"; border.width:1
                        Text { anchors.centerIn:parent; text:modelData.day
                            color: {
                                if (!modelData.isCurrentMonth) return Theme.textMuted
                                if (modelData.isSelected)      return "white"
                                if (modelData.isToday)         return Theme.primary
                                return Theme.textPrimary
                            }
                            font.pixelSize:12; font.family:Theme.fontFamily; font.bold:modelData.isToday||modelData.isSelected }
                        MouseArea { anchors.fill:parent; enabled:modelData.isCurrentMonth; cursorShape:enabled?Qt.PointingHandCursor:Qt.ArrowCursor
                            onClicked: { addBar.selectedDate = modelData.dateString; calHelper.selectDate(modelData.dateString); datePicker.close() } }
                    }
                }
            }

            RowLayout { Layout.fillWidth:true; spacing:4
                Button { text:"Today"; Layout.fillWidth:true; palette.buttonText:Theme.textPrimary
                    onClicked: { var t=new Date(); addBar.selectedDate=Qt.formatDate(t,"yyyy-MM-dd"); calHelper.currentMonth=t; datePicker.close() } }
                Button { text:"Clear"; Layout.fillWidth:true; palette.buttonText:Theme.textPrimary
                    onClicked: { addBar.selectedDate=""; datePicker.close() } }
            }
        }

        QtObject {
            id: calHelper
            property date currentMonth: new Date()
            property var days: []
            onCurrentMonthChanged: updateDays()
            function updateDays() {
                var month=currentMonth.getMonth(); var year=currentMonth.getFullYear()
                var first=new Date(year,month,1); var start=new Date(first)
                start.setDate(start.getDate()-first.getDay())
                var arr=[]; var d=new Date(start); var today=new Date()
                var selStr = addBar.selectedDate
                for (var i=0;i<42;i++) {
                    arr.push({ day:d.getDate(), dateString:Qt.formatDate(d,"yyyy-MM-dd"),
                        isCurrentMonth:d.getMonth()===month,
                        isToday:d.toDateString()===today.toDateString(),
                        isSelected:Qt.formatDate(d,"yyyy-MM-dd")===selStr })
                    d.setDate(d.getDate()+1)
                }
                days=arr; daysRep.model=arr
            }
            function selectDate(s) {
                var arr=[]; for(var i=0;i<days.length;i++){var copy=days[i]; copy.isSelected=(copy.dateString===s); arr.push(copy)} days=arr; daysRep.model=arr
            }
            property string monthYearString: {
                var months=["January","February","March","April","May","June","July","August","September","October","November","December"]
                return months[currentMonth.getMonth()]+" "+currentMonth.getFullYear()
            }
            Component.onCompleted: updateDays()
        }
    }

    // ── Add-options popup ──────────────────────────────────────────────
    Popup {
        id: addOptionsPopup
        parent: Overlay.overlay; modal:false; width:320
        height: addOptionsContent.implicitHeight+28; padding:0; z:1002
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color:"#242424"; radius:10; border.color:"#3a3a3a"; border.width:1 }

        ColumnLayout {
            id: addOptionsContent; x:14; y:14; width:addOptionsPopup.width-28; spacing:12

            Text { text:"Priority"; color:"#858585"; font.pixelSize:11; font.family:Theme.fontFamily }

            RowLayout { Layout.fillWidth:true; spacing:8
                Repeater {
                    model:[{value:3,color:"#ef4444",iconName:"flag"},{value:2,color:"#f59e0b",iconName:"flag"},{value:1,color:"#4b6fff",iconName:"flag"},{value:0,color:"#c7c7c7",iconName:"flag-empty"}]
                    Rectangle { Layout.preferredWidth:42; height:34; radius:7; color:addBar.selectedPriority===modelData.value?modelData.color+"33":"#2d2d2d"
                        SidebarIcon { anchors.centerIn:parent; width:18; height:18; iconName:modelData.iconName; iconColor:modelData.color; strokeWidth:1.9 }
                        MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:addBar.selectedPriority=modelData.value } }
                }
            }

            Rectangle { Layout.fillWidth:true; height:1; color:"#333333" }

            RowLayout { Layout.fillWidth:true; spacing:10
                SidebarIcon { Layout.preferredWidth:16; Layout.preferredHeight:16; iconName:addBar.selectedList==="Inbox"?"inbox":"list"; iconColor:"#dcdcdc"; strokeWidth:1.7 }
                ComboBox {
                    id: addListCombo; Layout.fillWidth:true
                    model: taskListViewModel.getAllLists()
                    currentIndex: Math.max(0, taskListViewModel.getAllLists().indexOf(addBar.selectedList))
                    onActivated: addBar.selectedList = currentText
                }
            }

            RowLayout { Layout.fillWidth:true; spacing:10
                SidebarIcon { Layout.preferredWidth:16; Layout.preferredHeight:16; iconName:"tag"; iconColor:"#dcdcdc"; strokeWidth:1.6 }
                Text { text:"Tags"; color:"#bdbdbd"; font.pixelSize:13; font.family:Theme.fontFamily }
            }

            Flow { Layout.fillWidth:true; spacing:6
                Repeater {
                    model: taskListViewModel.getAllTags()
                    Rectangle {
                        property bool isSelected: addBar.selectedTags.split(",").map(function(t){return t.trim()}).indexOf(modelData)!==-1
                        property color tc: { var s=taskListViewModel.getSavedTagColor(modelData); return s!==""?s:Qt.rgba(0.5,0.5,1,1) }
                        height:22; width:chipLbl.width+18; radius:4
                        color: isSelected?Qt.rgba(tc.r,tc.g,tc.b,0.28):"#2a2a2a"
                        border.color: isSelected?tc:"#444444"; border.width:1
                        Rectangle { width:3; height:parent.height; radius:2; color:parent.tc; opacity:parent.isSelected?1:0.5 }
                        Text { id:chipLbl; anchors.verticalCenter:parent.verticalCenter; anchors.left:parent.left; anchors.leftMargin:7
                            text:modelData; color:parent.isSelected?parent.tc:"#aaaaaa"; font.pixelSize:11; font.family:Theme.fontFamily }
                        MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                            onClicked: {
                                var cur=addBar.selectedTags.trim()===""?[]:addBar.selectedTags.split(",").map(function(t){return t.trim()}).filter(function(t){return t!==""})
                                var idx=cur.indexOf(modelData)
                                if(idx===-1)cur.push(modelData); else cur.splice(idx,1)
                                addBar.selectedTags=cur.join(", "); tagsInputOpts.text=addBar.selectedTags
                            }
                        }
                    }
                }
            }

            TextField {
                id: tagsInputOpts; Layout.fillWidth:true; text:addBar.selectedTags
                placeholderText:"Or type tags, comma-separated"; color:"#f1f1f1"; placeholderTextColor:"#777777"
                font.pixelSize:12; font.family:Theme.fontFamily
                background: Rectangle { color:"#1c1c1c"; radius:6; border.color:"#363636"; border.width:1 }
                padding:6; onTextChanged: addBar.selectedTags=text
            }
        }
    }

    // ── Main layout ────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 20; spacing: 10

        Shortcut { sequence:"Ctrl+K"; onActivated:{ addBar.expanded=true; taskInput.forceActiveFocus() } }

        // ── Header ──────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: taskListViewModel.activeFilterList !== ""
                      ? taskListViewModel.activeFilterList
                      : (taskListViewModel.activeFilterDate===""?"All":taskListViewModel.activeFilterDate)
                color: Theme.textPrimary; font.pixelSize:26; font.bold:true; font.family:Theme.fontFamily
            }

            Item { Layout.fillWidth:true }

            // View mode switcher (only for task lists)
            Rectangle {
                visible: root.currentListType !== "Notes List"
                width: 130; height:30; radius:8; color:"#222222"; border.color:"#333333"; border.width:1
                RowLayout { anchors.fill:parent; anchors.margins:3; spacing:3
                    Repeater {
                        model:[{icon:"all",mode:"list"},{icon:"matrix",mode:"board"},{icon:"summary",mode:"timeline"}]
                        Rectangle {
                            Layout.fillWidth:true; Layout.fillHeight:true; radius:6
                            color:root.viewMode===modelData.mode?"#3a3a3a":"transparent"
                            SidebarIcon { anchors.centerIn:parent; width:14; height:14; iconName:modelData.icon
                                iconColor:root.viewMode===modelData.mode?"#f2f2f2":"#777777"; strokeWidth:1.6 }
                            MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:root.viewMode=modelData.mode }
                        }
                    }
                }
            }

            // Active tag badge
            Rectangle {
                visible: taskListViewModel.activeFilterTag !== ""
                height:28; width:filterText.width+30; radius:14
                color:Theme.primary+"33"; border.color:Theme.primary; border.width:1
                RowLayout { anchors.fill:parent; anchors.margins:8; spacing:5
                    Text { id:filterText; text:"Tagged: #"+taskListViewModel.activeFilterTag; color:Theme.primary; font.pixelSize:13; font.bold:true; font.family:Theme.fontFamily }
                    Text { text:"✕"; color:Theme.primary; font.pixelSize:12; font.bold:true
                        MouseArea { anchors.fill:parent; anchors.margins:-5; cursorShape:Qt.PointingHandCursor; onClicked:taskListViewModel.clearFilters() } }
                }
            }
        }

        // ── Add task bar (hidden for Notes list) ───────────────────────
        Item {
            id: addBar
            Layout.fillWidth: true
            visible: root.currentListType !== "Notes List"
            Layout.preferredHeight: visible ? height : 0

            property bool expanded: false
            property int  selectedPriority: 0
            property string selectedDate: ""
            property string selectedTags: ""
            property string selectedList: taskListViewModel.activeFilterList !== "" ? taskListViewModel.activeFilterList : "Inbox"
            property string selectedSubtasks: ""
            property var priorityColors: ["#475569","#3b82f6","#f59e0b","#ef4444"]
            property var priorityLabels: ["","Low","Med","High"]

            Connections {
                target: taskListViewModel
                function onFilterChanged() {
                    if (!addBar.expanded)
                        addBar.selectedList = taskListViewModel.activeFilterList !== "" ? taskListViewModel.activeFilterList : "Inbox"
                }
            }

            function submit() {
                var title = taskInput.text.trim()
                if (title === "") return
                var tags = []
                if (addBar.selectedTags.trim() !== "") {
                    var ts = addBar.selectedTags.split(",")
                    for (var i=0;i<ts.length;i++){ var tg=ts[i].trim(); if(tg!=="")tags.push(tg) }
                }
                var details = ""
                if (addBar.selectedSubtasks.trim()!=="") {
                    var ss=addBar.selectedSubtasks.split(",")
                    for(var s=0;s<ss.length;s++){var st=ss[s].trim();if(st!=="")details+="- [ ] "+st+"\n"}
                }
                taskListViewModel.addTask(title, details.trim(), addBar.selectedPriority, addBar.selectedDate, tags, addBar.selectedList)
                taskInput.text=""; tagsInput.text=""; addBar.selectedPriority=0; addBar.selectedDate=""
                addBar.selectedTags=""; addBar.selectedSubtasks=""; addBar.expanded=false
                addBar.selectedList=taskListViewModel.activeFilterList!==""?taskListViewModel.activeFilterList:"Inbox"
            }

            height: expanded ? expandedContainer.height : collapsedBar.height
            Behavior on height { NumberAnimation { duration:180; easing.type:Easing.OutCubic } }

            Rectangle {
                id: collapsedBar; width:parent.width; height:40; visible:!addBar.expanded
                color:Theme.panel; radius:Theme.radiusMedium; border.color:Theme.primary
                RowLayout { anchors.fill:parent; anchors.leftMargin:12; anchors.rightMargin:12; spacing:10
                    Text { text:"+"; color:Theme.primary; font.pixelSize:20; font.bold:true }
                    Text { text:addBar.selectedList==="Inbox"?"Add task":"Add task to \""+addBar.selectedList+"\""
                        color:Theme.textMuted; font.pixelSize:14; font.family:Theme.fontFamily; Layout.fillWidth:true }
                    Rectangle { width:28; height:28; radius:6; color:dateCollMouse.containsMouse?"#2f2f2f":"transparent"
                        SidebarIcon { anchors.centerIn:parent; width:15; height:15; iconName:"calendar"; iconColor:addBar.selectedDate===""?"#858585":Theme.primary; strokeWidth:1.6 }
                        MouseArea { id:dateCollMouse; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor
                            onClicked: { var pos=parent.mapToItem(Overlay.overlay,0,0); datePicker.x=Math.max(12,Math.min(pos.x-datePicker.width+parent.width,Overlay.overlay.width-datePicker.width-12)); datePicker.y=pos.y+parent.height+8; datePicker.open() } }
                    }
                    Rectangle { width:28; height:28; radius:6; color:optCollMouse.containsMouse?"#2f2f2f":"transparent"
                        SidebarIcon { anchors.centerIn:parent; width:14; height:14; iconName:"chevronDown"; iconColor:"#b8b8b8"; strokeWidth:1.8 }
                        MouseArea { id:optCollMouse; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:openAddOptionsPopup(parent) }
                    }
                }
                HoverHandler {}
                TapHandler { onTapped:{ if(!dateCollMouse.containsMouse&&!optCollMouse.containsMouse){addBar.expanded=true;taskInput.forceActiveFocus()} } }
            }

            Rectangle {
                id: expandedContainer; width:parent.width; visible:addBar.expanded
                height:visible?innerCol.height+2:0; color:Theme.surface; radius:Theme.radiusMedium
                border.color:Theme.primary; border.width:1.5
                ColumnLayout {
                    id: innerCol; width:parent.width; spacing:0
                    RowLayout { Layout.fillWidth:true; Layout.margins:12; spacing:10
                        Rectangle { width:18;height:18;radius:9;color:"transparent"; border.color:addBar.priorityColors[addBar.selectedPriority]; border.width:2 }
                        TextField { id:taskInput; Layout.fillWidth:true; placeholderText:"Task name"; color:Theme.textPrimary; font.pixelSize:15; font.family:Theme.fontFamily; background:null; leftPadding:0; rightPadding:0
                            Keys.onReturnPressed:addBar.submit(); Keys.onEnterPressed:addBar.submit()
                            Keys.onEscapePressed:{text="";addBar.expanded=false} }
                    }
                    Rectangle { Layout.fillWidth:true; height:1; color:Theme.divider }
                    ColumnLayout { Layout.fillWidth:true; spacing:8
                        RowLayout { Layout.fillWidth:true; spacing:6
                            Rectangle { height:28; Layout.minimumWidth:100; Layout.maximumWidth:150; radius:Theme.radiusSmall
                                color:addBar.selectedDate!==""?Theme.primary+"22":"transparent"
                                border.color:addBar.selectedDate!==""?Theme.primary:"transparent"
                                RowLayout { anchors.fill:parent; anchors.leftMargin:8; anchors.rightMargin:8; spacing:4
                                    SidebarIcon { Layout.preferredWidth:13; Layout.preferredHeight:13; iconName:"calendar"; iconColor:addBar.selectedDate!==""?Theme.primary:Theme.textMuted; strokeWidth:1.5 }
                                    Text { text:addBar.selectedDate!==""?addBar.selectedDate:"Date"; color:addBar.selectedDate!==""?Theme.primary:Theme.textMuted; font.pixelSize:11; font.family:Theme.fontFamily; elide:Text.ElideRight; Layout.fillWidth:true }
                                }
                                MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                    onClicked:{ datePicker.close(); var pos=mapToItem(Overlay.overlay,0,0); var sb=Overlay.overlay.height-(pos.y+height+8); datePicker.y=sb<datePicker.height+12?Math.max(12,pos.y-datePicker.height-8):pos.y+height+8; datePicker.x=Math.max(12,Math.min(pos.x,Overlay.overlay.width-datePicker.width-12)); datePicker.open() }
                                }
                            }
                            Rectangle { height:28; Layout.minimumWidth:80; Layout.maximumWidth:120; radius:Theme.radiusSmall
                                color:addBar.selectedPriority>0?addBar.priorityColors[addBar.selectedPriority]+"22":"transparent"
                                border.color:addBar.selectedPriority>0?addBar.priorityColors[addBar.selectedPriority]:"transparent"
                                RowLayout { anchors.fill:parent; anchors.leftMargin:8; anchors.rightMargin:8; spacing:4
                                    SidebarIcon { Layout.preferredWidth:13; Layout.preferredHeight:13; iconName:addBar.selectedPriority>0?"flag":"flag-empty"; iconColor:addBar.selectedPriority>0?addBar.priorityColors[addBar.selectedPriority]:Theme.textMuted; strokeWidth:1.5 }
                                    Text { visible:addBar.selectedPriority>0; text:addBar.priorityLabels[addBar.selectedPriority]; color:addBar.priorityColors[addBar.selectedPriority]; font.pixelSize:11; font.family:Theme.fontFamily; elide:Text.ElideRight; Layout.fillWidth:true }
                                }
                                MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                    onClicked:{ priorityPicker.close(); var pos=mapToItem(Overlay.overlay,0,0); var sb=Overlay.overlay.height-(pos.y+height+8); priorityPicker.y=sb<priorityPicker.height+12?Math.max(12,pos.y-priorityPicker.height-8):pos.y+height+8; priorityPicker.x=Math.max(12,Math.min(pos.x,Overlay.overlay.width-priorityPicker.width-12)); priorityPicker.open() }
                                }
                            }
                            Item { Layout.fillWidth:true }
                        }
                        RowLayout { Layout.fillWidth:true; Layout.leftMargin:12; Layout.rightMargin:12; spacing:4
                            Text { text:"#"; color:Theme.textMuted; font.pixelSize:12; font.bold:true }
                            TextField { id:tagsInput; Layout.fillWidth:true; placeholderText:"Tags (comma-separated)"; color:Theme.textPrimary; font.pixelSize:12; font.family:Theme.fontFamily
                                background:Rectangle{color:Theme.background;radius:4;border.color:Theme.divider;border.width:1}
                                padding:6
                                onTextChanged:{addBar.selectedTags=text}
                                onAccepted:{addBar.submit()}
                            }
                        }
                        RowLayout { Layout.fillWidth:true; spacing:6
                            Item { Layout.fillWidth:true }
                            Rectangle { height:28;width:82;radius:Theme.radiusSmall; color:optExpHov.containsMouse?Theme.surfaceHover:"transparent"
                                Text { anchors.centerIn:parent;text:"Options";color:Theme.textSecondary;font.pixelSize:12;font.family:Theme.fontFamily }
                                HoverHandler{id:optExpHov}
                                MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:openAddOptionsPopup(parent)} }
                            Rectangle { height:28;width:64;radius:Theme.radiusSmall; color:cancelHov.containsMouse?Theme.surfaceHover:"transparent"
                                Text { anchors.centerIn:parent;text:"Cancel";color:Theme.textSecondary;font.pixelSize:12;font.family:Theme.fontFamily }
                                HoverHandler{id:cancelHov}
                                MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:{taskInput.text="";addBar.expanded=false}} }
                            Rectangle { height:28;width:64;radius:Theme.radiusSmall
                                color:taskInput.text.trim()!==""?(addBtnHov.containsMouse?Theme.primaryHover:Theme.primary):Theme.surface
                                opacity:taskInput.text.trim()!==""?1:0.5
                                Behavior on color{ColorAnimation{duration:120}}
                                Text { anchors.centerIn:parent;text:"Add";color:taskInput.text.trim()!==""?"white":Theme.textMuted;font.pixelSize:12;font.bold:true;font.family:Theme.fontFamily }
                                HoverHandler{id:addBtnHov}
                                MouseArea{anchors.fill:parent;cursorShape:taskInput.text.trim()!==""?Qt.PointingHandCursor:Qt.ArrowCursor;onClicked:addBar.submit()} }
                        }
                    }
                }
            }
        }

        // ── Content switcher ───────────────────────────────────────────
        Item {
            Layout.fillWidth:  true
            Layout.fillHeight: true

            // ── LIST VIEW ────────────────────────────────────────────
            ListView {
                id: taskListView
                anchors.fill: parent
                visible: root.viewMode === "list"
                model: taskListViewModel; clip:true; spacing:8

                add: Transition { NumberAnimation{property:"opacity";from:0;to:1;duration:250;easing.type:Easing.OutQuad} NumberAnimation{property:"scale";from:0.8;to:1;duration:250;easing.type:Easing.OutBack} }
                remove: Transition { NumberAnimation{property:"opacity";to:0;duration:200} NumberAnimation{property:"scale";to:0.8;duration:200} }

                section.property: "section"
                section.delegate: Rectangle {
                    width: ListView.view ? ListView.view.width : 0; height:40; color:"transparent"
                    property bool isCollapsed: taskListViewModel.isSectionCollapsed(section)
                    Connections { target:taskListViewModel; function onSectionToggled(){isCollapsed=taskListViewModel.isSectionCollapsed(section)} }
                    RowLayout { anchors.fill:parent; anchors.leftMargin:5
                        Text { text:isCollapsed?"▶":"▼"; color:Theme.textMuted; font.pixelSize:12 }
                        Text { text:section; color:Theme.textSecondary; font.pixelSize:14; font.bold:true; font.family:Theme.fontFamily }
                    }
                    MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:taskListViewModel.toggleSection(section) }
                }

                delegate: TaskItem {
                    width: ListView.view.width
                    taskIndex: index; taskTitle:model.title; taskCompleted:model.isCompleted
                    taskPriority:model.priority!==undefined?model.priority:0; taskSection:model.section
                    taskTags:model.tags!==undefined?model.tags:[]; taskList:model.listName!==undefined?model.listName:""
                    taskDueAt:model.dueAt!==undefined?model.dueAt:""
                    onToggled: taskListViewModel.toggleTaskCompletion(index)
                    onRenamed: function(nt){taskListViewModel.renameTask(index,nt)}
                    onDeleted: taskListViewModel.softDeleteTask(index)
                }
            }

            // ── BOARD VIEW ───────────────────────────────────────────
            BoardView {
                anchors.fill: parent
                visible: root.viewMode === "board"
            }

            // ── TIMELINE VIEW ────────────────────────────────────────
            TimelineView {
                anchors.fill: parent
                visible: root.viewMode === "timeline"
            }

            // ── NOTES VIEW ───────────────────────────────────────────
            NotesView {
                anchors.fill: parent
                visible: root.viewMode === "notes"
                listName: taskListViewModel.activeFilterList
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // BOARD VIEW component
    // ═══════════════════════════════════════════════════════════════════
    component BoardView: Rectangle {
        color: "transparent"
        property var columns: ["To Do", "In Progress", "Done"]
        id: boardRoot

        function tasksForCol(col) {
            var result = []
            for (var i = 0; i < taskListViewModel.rowCount(); i++) {
                var idx = taskListViewModel.index(i, 0)
                var status    = taskListViewModel.data(idx, 261) // StatusRole
                var completed = taskListViewModel.data(idx, 262) // IsCompletedRole
                if (col === "Done"        &&  completed) result.push(i)
                else if (col === "In Progress" && !completed && status === "in_progress") result.push(i)
                else if (col === "To Do"       && !completed && status !== "in_progress") result.push(i)
            }
            return result
        }

        RowLayout {
            anchors.fill: parent; anchors.margins: 4; spacing: 12

            Repeater {
                model: boardRoot.columns

                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    radius: 10; color: "#1e1e1e"; border.color:"#2e2e2e"; border.width:1

                    property color accent: modelData==="Done"?"#22c55e":(modelData==="In Progress"?"#f59e0b":"#3b82f6")
                    property var taskIndices: boardRoot.tasksForCol(modelData) || []

                    Connections {
                        target: taskListViewModel
                        function onTasksModified() { taskIndices = boardRoot.tasksForCol(modelData) }
                    }

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 10

                        // Column header
                        RowLayout { Layout.fillWidth:true
                            Rectangle { width:10;height:10;radius:5; color:parent.parent.parent.accent }
                            Text { text:modelData; color:"#f0f0f0"; font.pixelSize:14; font.bold:true; font.family:Theme.fontFamily; Layout.fillWidth:true }
                            Text { text:parent.parent.parent.taskIndices.length; color:"#666666"; font.pixelSize:12; font.family:Theme.fontFamily }
                        }

                        Rectangle { Layout.fillWidth:true; height:1; color:"#2e2e2e" }

                        // Task cards
                        Flickable {
                            Layout.fillWidth:true; Layout.fillHeight:true
                            contentHeight: cardsCol.height; clip:true

                            ColumnLayout {
                                id: cardsCol; width:parent.width; spacing:8

                                Repeater {
                                    model: parent.parent.parent.parent.parent.taskIndices

                                    Rectangle {
                                        Layout.fillWidth: true; radius:8
                                        height: cardContent.implicitHeight + 20
                                        color: cardHov.containsMouse?"#2a2a2a":"#252525"
                                        border.color:"#333333"; border.width:1

                                        HoverHandler { id:cardHov }

                                        property var taskData: {
                                            var idx2 = taskListViewModel.index(modelData, 0)
                                            return {
                                                id:    taskListViewModel.data(idx2, 257), // IdRole
                                                title: taskListViewModel.data(idx2, 258),
                                                priority: taskListViewModel.data(idx2, 260),
                                                tags:  taskListViewModel.data(idx2, 266),
                                                dueAt: taskListViewModel.data(idx2, 263),
                                                completed: taskListViewModel.data(idx2, 262)
                                            }
                                        }

                                        ColumnLayout {
                                            id:cardContent; anchors.left:parent.left; anchors.right:parent.right
                                            anchors.top:parent.top; anchors.margins:12; spacing:8

                                            // Priority bar
                                            Rectangle {
                                                Layout.fillWidth:true; height:3; radius:2
                                                color: {
                                                    var p=parent.parent.taskData.priority
                                                    if(p===3)return"#ef4444"; if(p===2)return"#f59e0b"; if(p===1)return"#3b82f6"; return"#333333"
                                                }
                                            }

                                            Text { text:parent.parent.taskData.title; color:"#f0f0f0"; font.pixelSize:13; font.family:Theme.fontFamily; wrapMode:Text.WordWrap; Layout.fillWidth:true }

                                            RowLayout { Layout.fillWidth:true; spacing:6
                                                Repeater {
                                                    model: parent.parent.parent.taskData.tags ? parent.parent.parent.taskData.tags.slice(0,2) : []
                                                    Rectangle {
                                                        height:18; width:tagTxt2.width+12; radius:4; color:"#2d2d2d"
                                                        Text { id:tagTxt2; anchors.centerIn:parent; text:modelData; color:"#8a8a8a"; font.pixelSize:10; font.family:Theme.fontFamily }
                                                    }
                                                }
                                                Item { Layout.fillWidth:true }
                                                Text {
                                                    visible: parent.parent.parent.taskData.dueAt !== ""
                                                    text: {
                                                        var d=parent.parent.parent.taskData.dueAt
                                                        if(!d)return""
                                                        var dt=new Date(d)
                                                        var months=["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
                                                        return months[dt.getMonth()]+" "+dt.getDate()
                                                    }
                                                    color:"#666666"; font.pixelSize:11; font.family:Theme.fontFamily
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                            onClicked: taskListViewModel.selectTask(modelData)
                                        }
                                    }
                                }

                                // Add card button
                                Rectangle {
                                    Layout.fillWidth:true; height:36; radius:8; color:"transparent"
                                    border.color:"#2e2e2e"; border.width:1
                                    RowLayout { anchors.centerIn:parent; spacing:6
                                        Text { text:"+"; color:"#555555"; font.pixelSize:16 }
                                        Text { text:"Add card"; color:"#555555"; font.pixelSize:13; font.family:Theme.fontFamily }
                                    }
                                    MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                        onClicked: { addBar.selectedList=taskListViewModel.activeFilterList; addBar.expanded=true } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // TIMELINE VIEW component
    // ═══════════════════════════════════════════════════════════════════
    component TimelineView: Rectangle {
        id: timelineRoot
        color: "transparent"

        property var monthNames: ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        property int startOffset: 0   // days offset from today

        function dateLabel(offset) {
            var d = new Date(); d.setDate(d.getDate() + startOffset + offset)
            return monthNames[d.getMonth()] + " " + d.getDate()
        }
        function dateKey(offset) {
            var d = new Date(); d.setDate(d.getDate() + startOffset + offset)
            return Qt.formatDate(d,"yyyy-MM-dd")
        }
        function tasksForDate(key) {
            var result = []
            for (var i = 0; i < taskListViewModel.rowCount(); i++) {
                var idx = taskListViewModel.index(i, 0)
                var due = taskListViewModel.data(idx, 263) // DueAtRole
                if (due && due.substring(0,10) === key) {
                    result.push({
                        title:    taskListViewModel.data(idx, 258),
                        priority: taskListViewModel.data(idx, 260),
                        completed:taskListViewModel.data(idx, 262),
                        index:    i
                    })
                }
            }
            return result
        }

        ColumnLayout {
            anchors.fill: parent; spacing: 0

            // Navigation bar
            RowLayout { Layout.fillWidth:true; height:44; Layout.leftMargin:8; Layout.rightMargin:8
                Rectangle { width:80;height:30;radius:6;color:prevHov.containsMouse?"#2a2a2a":"#1e1e1e"; border.color:"#333333";border.width:1
                    Text { anchors.centerIn:parent;text:"◀ Prev";color:"#cccccc";font.pixelSize:12;font.family:Theme.fontFamily }
                    HoverHandler{id:prevHov}
                    MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:startOffset-=14} }
                Item{Layout.fillWidth:true}
                Text { text:"Timeline – 14 Day View"; color:"#f0f0f0"; font.pixelSize:15; font.bold:true; font.family:Theme.fontFamily }
                Item{Layout.fillWidth:true}
                Rectangle { width:80;height:30;radius:6;color:nextHov.containsMouse?"#2a2a2a":"#1e1e1e"; border.color:"#333333";border.width:1
                    Text { anchors.centerIn:parent;text:"Next ▶";color:"#cccccc";font.pixelSize:12;font.family:Theme.fontFamily }
                    HoverHandler{id:nextHov}
                    MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:startOffset+=14} }
            }

            Rectangle { Layout.fillWidth:true; height:1; color:"#2a2a2a" }

            // 14-day grid
            Flickable {
                Layout.fillWidth:true; Layout.fillHeight:true
                contentHeight: tlGrid.height; clip:true

                GridLayout {
                    id: tlGrid; width:parent.width; columns:7; rowSpacing:1; columnSpacing:1

                    // Day headers
                    Repeater {
                        model: 14
                        Rectangle {
                            Layout.fillWidth:true; height:50; color:"#1a1a1a"; border.color:"#252525"; border.width:1
                            property string dk: timelineRoot.dateKey(index)
                            property bool isToday: dk === Qt.formatDate(new Date(),"yyyy-MM-dd")
                            ColumnLayout { anchors.centerIn:parent; spacing:2
                                Text { Layout.alignment:Qt.AlignHCenter
                                    text:["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][(new Date().getDay() + (timelineRoot.startOffset||0) + index)%7]
                                    color:isToday?Theme.primary:"#777777"; font.pixelSize:10; font.family:Theme.fontFamily }
                                Rectangle { Layout.alignment:Qt.AlignHCenter; width:28;height:28;radius:14
                                    color:isToday?Theme.primary:"transparent"
                                    Text { anchors.centerIn:parent; text:{ var d=new Date();d.setDate(d.getDate()+(timelineRoot.startOffset||0)+index);return d.getDate()}
                                        color:isToday?"white":"#dddddd"; font.pixelSize:13; font.bold:true; font.family:Theme.fontFamily }
                                }
                            }
                        }
                    }

                    // Task rows – 14 day cells
                    Repeater {
                        model: 14
                        Rectangle {
                            Layout.fillWidth:true; Layout.preferredHeight:Math.max(80, tlTasks.height+16)
                            color:"#181818"; border.color:"#222222"; border.width:1

                            property string dKey: timelineRoot.dateKey(index)
                            property var dayTasks: timelineRoot.tasksForDate(dKey)

                            Connections { target:taskListViewModel; function onTasksModified(){dayTasks = timelineRoot.tasksForDate(dKey)} }

                            ColumnLayout {
                                id:tlTasks; anchors.left:parent.left; anchors.right:parent.right; anchors.top:parent.top; anchors.margins:6; spacing:4

                                Repeater {
                                    model: dayTasks
                                    Rectangle {
                                        Layout.fillWidth:true; height:36; radius:6
                                        color:{ var p=modelData.priority; if(p===3)return"#3a1a1a"; if(p===2)return"#2e2510"; if(p===1)return"#111a2e"; return"#1e1e1e" }
                                        border.color:{ var p=modelData.priority; if(p===3)return"#6a2a2a"; if(p===2)return"#5a4510"; if(p===1)return"#1a3060"; return"#2a2a2a" }
                                        border.width:1

                                        RowLayout { anchors.fill:parent; anchors.margins:6; spacing:6
                                            Rectangle { width:6;height:6;radius:3
                                                color:{ var p=modelData.priority; if(p===3)return"#ef4444"; if(p===2)return"#f59e0b"; if(p===1)return"#3b82f6"; return"#555555" } }
                                            Text { text:modelData.title; color:modelData.completed?"#666666":"#e0e0e0"; font.pixelSize:11; font.family:Theme.fontFamily; elide:Text.ElideRight; Layout.fillWidth:true; font.strikeout:modelData.completed }
                                        }
                                        MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:taskListViewModel.selectTask(modelData.index) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // NOTES VIEW component
    // ═══════════════════════════════════════════════════════════════════
    component NotesView: Rectangle {
        id: notesRoot
        color: "transparent"
        property string listName: ""
        property var notesList: []

        // Load notes from tasks with description as content
        function loadNotes() {
            var result = []
            for (var i = 0; i < taskListViewModel.rowCount(); i++) {
                var idx = taskListViewModel.index(i, 0)
                var list = taskListViewModel.data(idx, 267) // ListRole
                if (list === listName || listName === "") {
                    result.push({
                        index:   i,
                        id:      taskListViewModel.data(idx, 257),
                        title:   taskListViewModel.data(idx, 258),
                        content: taskListViewModel.data(idx, 259), // DescriptionRole
                        updatedAt: "Today"
                    })
                }
            }
            return result
        }

        property int selectedNote: -1
        property string editingContent: ""

        Connections {
            target: taskListViewModel
            function onTasksModified() { notesList = notesRoot.loadNotes() }
            function onFilterChanged() { notesList = notesRoot.loadNotes(); selectedNote = -1 }
        }

        Component.onCompleted: notesList = loadNotes()

        RowLayout {
            anchors.fill: parent; spacing: 0

            // Notes list panel
            Rectangle {
                Layout.preferredWidth: 240; Layout.fillHeight:true
                color:"#1a1a1a"; border.color:"#2a2a2a"; border.width:1

                ColumnLayout { anchors.fill:parent; anchors.margins:12; spacing:10

                    RowLayout { Layout.fillWidth:true
                        Text { text:"Notes"; color:"#f0f0f0"; font.pixelSize:16; font.bold:true; font.family:Theme.fontFamily; Layout.fillWidth:true }
                        Rectangle { width:28;height:28;radius:6; color:addNoteHov.containsMouse?"#2a2a2a":"transparent"
                            Text { anchors.centerIn:parent;text:"+";color:Theme.primary;font.pixelSize:20;font.bold:true }
                            HoverHandler{id:addNoteHov}
                            MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                onClicked: {
                                    taskListViewModel.addTask("New Note","",0,"",[],(listName===""?"Inbox":listName))
                                    notesList = notesRoot.loadNotes()
                                    selectedNote = notesList.length - 1
                                }
                            }
                        }
                    }

                    ListView {
                        Layout.fillWidth:true; Layout.fillHeight:true; clip:true; spacing:4

                        model: notesList.length > 0 ? notesList.length : 0

                        delegate: Rectangle {
                            width:ListView.view.width; height:72; radius:8
                            color: selectedNote===index?"#2a2a3a":(noteItemHov.containsMouse?"#222222":"transparent")
                            border.color: selectedNote===index?Theme.primary+"44":"transparent"; border.width:1

                            ColumnLayout { anchors.fill:parent; anchors.margins:10; spacing:4
                                Text { text:notesList[index].title; color:"#f0f0f0"; font.pixelSize:13; font.bold:true; font.family:Theme.fontFamily; elide:Text.ElideRight; Layout.fillWidth:true }
                                Text { text:notesList[index].content!==""?notesList[index].content:"No content"; color:"#777777"; font.pixelSize:11; font.family:Theme.fontFamily; elide:Text.ElideRight; Layout.fillWidth:true; maximumLineCount:2 }
                                Text { text:notesList[index].updatedAt; color:"#555555"; font.pixelSize:10; font.family:Theme.fontFamily }
                            }

                            HoverHandler{id:noteItemHov}
                            MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                onClicked: {
                                    selectedNote = index
                                    editingContent = notesList[index].content
                                }
                            }
                        }
                    }
                }
            }

            // Note editor
            Rectangle {
                Layout.fillWidth:true; Layout.fillHeight:true; color:"#161616"

                Item {
                    anchors.fill:parent
                    visible: selectedNote >= 0 && selectedNote < notesList.length

                    ColumnLayout {
                        anchors.fill:parent; anchors.margins:24; spacing:16

                        // Note title
                        TextField {
                            Layout.fillWidth:true
                            text: selectedNote>=0&&selectedNote<notesList.length?notesList[selectedNote].title:""
                            color:"#f5f5f5"; font.pixelSize:22; font.bold:true; font.family:Theme.fontFamily
                            background:null; leftPadding:0; rightPadding:0
                            onEditingFinished: {
                                if(selectedNote>=0&&selectedNote<notesList.length)
                                    taskListViewModel.renameTask(notesList[selectedNote].index, text)
                            }
                        }

                        Rectangle { Layout.fillWidth:true; height:1; color:"#252525" }

                        // Formatting toolbar
                        RowLayout { Layout.fillWidth:true; spacing:8
                            Repeater {
                                model:["B","I","U","H1","H2","• List","Code"]
                                Rectangle { width:toolText.width+16;height:26;radius:5;color:toolHov.containsMouse?"#252525":"transparent"; border.color:"#2e2e2e"; border.width:1
                                    Text { id:toolText; anchors.centerIn:parent; text:modelData; color:"#aaaaaa"; font.pixelSize:12; font.family:Theme.fontFamily }
                                    HoverHandler{id:toolHov}
                                    MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor
                                        onClicked:{
                                            var prefix=""
                                            if(modelData==="H1")prefix="# "
                                            else if(modelData==="H2")prefix="## "
                                            else if(modelData==="• List")prefix="- "
                                            else if(modelData==="Code")prefix="`"
                                            if(prefix!==""&&noteEditor.text.length>=0)
                                                noteEditor.insert(noteEditor.cursorPosition,prefix)
                                        }
                                    }
                                }
                            }
                        }

                        // Note editor body
                        ScrollView {
                            Layout.fillWidth:true; Layout.fillHeight:true; clip:true

                            TextArea {
                                id:noteEditor
                                text: selectedNote>=0&&selectedNote<notesList.length?notesList[selectedNote].content:""
                                color:"#e8e8e8"; font.pixelSize:14; font.family:Theme.fontFamily
                                wrapMode:TextArea.Wrap; selectByMouse:true
                                placeholderText:"Start writing your note..."
                                placeholderTextColor:"#444444"
                                background: Rectangle { color:"transparent" }
                                onTextChanged: {
                                    if(selectedNote>=0&&selectedNote<notesList.length)
                                        taskListViewModel.updateSelectedTaskDescription(text)
                                }
                                onActiveFocusChanged: {
                                    if(!activeFocus&&selectedNote>=0&&selectedNote<notesList.length)
                                        taskListViewModel.updateSelectedTaskDescription(text)
                                }
                            }
                        }
                    }
                }

                // Empty state
                ColumnLayout {
                    anchors.centerIn:parent; spacing:12
                    visible: selectedNote < 0 || selectedNote >= notesList.length

                    Text { Layout.alignment:Qt.AlignHCenter; text:"📝"; font.pixelSize:48 }
                    Text { Layout.alignment:Qt.AlignHCenter; text:"Select a note to edit"; color:"#555555"; font.pixelSize:14; font.family:Theme.fontFamily }
                    Rectangle { Layout.alignment:Qt.AlignHCenter; width:140;height:36;radius:8; color:Theme.primary
                        Text { anchors.centerIn:parent;text:"Create Note";color:"white";font.pixelSize:13;font.bold:true;font.family:Theme.fontFamily }
                        MouseArea { anchors.fill:parent;cursorShape:Qt.PointingHandCursor
                            onClicked:{ taskListViewModel.addTask("New Note","",0,"",[],(listName===""?"Inbox":listName)); notesList = notesRoot.loadNotes(); selectedNote=notesList.length-1 } }
                    }
                }
            }
        }
    }
}
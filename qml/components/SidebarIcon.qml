import QtQuick

Item {
    id: root

    property string iconName: "tasks"
    property color iconColor: "#dcdcdc"
    property real strokeWidth: 1.8

    implicitWidth: 16
    implicitHeight: 16

    onIconNameChanged: iconCanvas.requestPaint()
    onIconColorChanged: iconCanvas.requestPaint()
    onStrokeWidthChanged: iconCanvas.requestPaint()
    onWidthChanged: iconCanvas.requestPaint()
    onHeightChanged: iconCanvas.requestPaint()

    Canvas {
        id: iconCanvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            var w = width
            var h = height
            var s = Math.min(w, h)
            var cx = w / 2
            var cy = h / 2
            var r = s / 2

            ctx.clearRect(0, 0, w, h)
            ctx.strokeStyle = root.iconColor
            ctx.fillStyle = root.iconColor
            ctx.lineWidth = root.strokeWidth
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            function line(x1, y1, x2, y2) {
                ctx.beginPath()
                ctx.moveTo(x1, y1)
                ctx.lineTo(x2, y2)
                ctx.stroke()
            }

            function rect(x, y, rw, rh) {
                ctx.beginPath()
                ctx.rect(x, y, rw, rh)
                ctx.stroke()
            }

            function circle(x, y, rr, fill) {
                ctx.beginPath()
                ctx.arc(x, y, rr, 0, Math.PI * 2)
                fill ? ctx.fill() : ctx.stroke()
            }

            switch (root.iconName) {
            case "tasks":
                line(r * 0.55, r * 1.05, r * 0.9, r * 1.4)
                line(r * 0.9, r * 1.4, r * 1.5, r * 0.65)
                break
            case "calendar":
                rect(r * 0.45, r * 0.5, r * 1.1, r * 1.0)
                line(r * 0.45, r * 0.8, r * 1.55, r * 0.8)
                line(r * 0.75, r * 0.35, r * 0.75, r * 0.65)
                line(r * 1.25, r * 0.35, r * 1.25, r * 0.65)
                break
            case "matrix":
                rect(r * 0.42, r * 0.42, r * 0.44, r * 0.44)
                rect(r * 1.14, r * 0.42, r * 0.44, r * 0.44)
                rect(r * 0.42, r * 1.14, r * 0.44, r * 0.44)
                rect(r * 1.14, r * 1.14, r * 0.44, r * 0.44)
                break
            case "pomodoro":
                circle(cx, cy, r * 0.58, false)
                line(cx, cy, cx, r * 0.62)
                line(cx, cy, r * 1.38, cy)
                break
            case "habit":
                ctx.beginPath()
                ctx.arc(cx, cy, r * 0.58, -Math.PI / 2, Math.PI * 0.85)
                ctx.stroke()
                circle(cx, cy, r * 0.18, true)
                break
            case "search":
                circle(r * 0.85, r * 0.85, r * 0.34, false)
                line(r * 1.12, r * 1.12, r * 1.55, r * 1.55)
                break
            case "sync":
                ctx.beginPath()
                ctx.arc(cx, cy, r * 0.52, Math.PI * 0.2, Math.PI * 1.45)
                ctx.stroke()
                line(r * 0.78, r * 0.42, r * 1.03, r * 0.18)
                line(r * 0.78, r * 0.42, r * 0.72, r * 0.08)
                ctx.beginPath()
                ctx.arc(cx, cy, r * 0.52, Math.PI * 1.2, Math.PI * 2.45)
                ctx.stroke()
                line(r * 1.22, r * 1.58, r * 0.97, r * 1.82)
                line(r * 1.22, r * 1.58, r * 1.28, r * 1.92)
                break
            case "notifications":
                circle(cx, cy, r * 0.38, true)
                break
            case "help":
                ctx.font = "bold " + Math.round(s * 0.82) + "px sans-serif"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.fillText("?", cx, cy + r * 0.04)
                break
            case "all":
                line(r * 0.48, r * 0.6, r * 1.52, r * 0.6)
                line(r * 0.48, r * 1.0, r * 1.52, r * 1.0)
                line(r * 0.48, r * 1.4, r * 1.52, r * 1.4)
                break
            case "today":
                rect(r * 0.46, r * 0.48, r * 1.08, r * 1.08)
                line(r * 0.46, r * 0.78, r * 1.54, r * 0.78)
                circle(cx, r * 1.18, r * 0.16, true)
                break
            case "next":
                rect(r * 0.45, r * 0.48, r * 1.1, r * 1.08)
                line(r * 0.45, r * 0.78, r * 1.55, r * 0.78)
                ctx.font = "bold " + Math.round(s * 0.5) + "px sans-serif"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.fillText("7", cx, r * 1.18)
                break
            case "inbox":
            case "list":
                line(r * 0.48, r * 0.7, r * 1.52, r * 0.7)
                line(r * 0.36, r * 1.18, r * 0.58, r * 0.7)
                line(r * 1.64, r * 1.18, r * 1.42, r * 0.7)
                line(r * 0.36, r * 1.18, r * 1.64, r * 1.18)
                break
            case "folder":
                line(r * 0.35, r * 0.68, r * 0.78, r * 0.68)
                line(r * 0.78, r * 0.68, r * 0.98, r * 0.88)
                line(r * 0.98, r * 0.88, r * 1.65, r * 0.88)
                line(r * 1.65, r * 0.88, r * 1.52, r * 1.48)
                line(r * 1.52, r * 1.48, r * 0.35, r * 1.48)
                line(r * 0.35, r * 1.48, r * 0.35, r * 0.68)
                break
            case "summary":
                rect(r * 0.52, r * 0.42, r * 0.96, r * 1.16)
                line(r * 0.72, r * 0.78, r * 1.28, r * 0.78)
                line(r * 0.72, r * 1.02, r * 1.28, r * 1.02)
                line(r * 0.72, r * 1.26, r * 1.08, r * 1.26)
                break
            case "flag":
            case "flag-empty":
                line(r * 0.62, r * 0.45, r * 0.62, r * 1.58)
                ctx.beginPath()
                ctx.moveTo(r * 0.62, r * 0.5)
                ctx.lineTo(r * 1.42, r * 0.72)
                ctx.lineTo(r * 0.62, r * 0.94)
                if (root.iconName === "flag") {
                    ctx.closePath()
                    ctx.fill()
                } else {
                    ctx.stroke()
                }
                break
            case "tag":
                line(cx, r * 0.38, r * 1.62, cy)
                line(r * 1.62, cy, cx, r * 1.62)
                line(cx, r * 1.62, r * 0.38, cy)
                line(r * 0.38, cy, cx, r * 0.38)
                break
            case "subtasks":
                line(r * 0.55, r * 0.45, r * 0.55, r * 1.25)
                line(r * 0.55, r * 1.25, r * 0.88, r * 1.25)
                line(r * 0.88, r * 1.25, r * 0.72, r * 1.08)
                line(r * 0.88, r * 1.25, r * 0.72, r * 1.42)
                line(r * 1.05, r * 0.65, r * 1.5, r * 0.65)
                line(r * 1.05, r * 1.25, r * 1.5, r * 1.25)
                break
            case "attachment":
                ctx.beginPath()
                ctx.arc(r * 0.95, r * 0.95, r * 0.42, Math.PI * 0.15, Math.PI * 1.55)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(r * 1.06, r * 0.95, r * 0.26, Math.PI * 0.15, Math.PI * 1.6)
                ctx.stroke()
                break
            case "template":
                rect(r * 0.55, r * 0.38, r * 0.9, r * 1.24)
                line(r * 0.75, r * 0.72, r * 1.25, r * 0.72)
                line(r * 0.75, r * 1.0, r * 1.25, r * 1.0)
                line(r * 0.75, r * 1.28, r * 1.06, r * 1.28)
                break
            case "settings":
                circle(cx, cy, r * 0.2, false)
                for (var i = 0; i < 8; i++) {
                    var a = i * Math.PI / 4
                    line(cx + Math.cos(a) * r * 0.38,
                         cy + Math.sin(a) * r * 0.38,
                         cx + Math.cos(a) * r * 0.58,
                         cy + Math.sin(a) * r * 0.58)
                }
                break
            case "chevronDown":
                line(r * 0.55, r * 0.75, cx, r * 1.2)
                line(cx, r * 1.2, r * 1.45, r * 0.75)
                break
            case "completed":
                rect(r * 0.46, r * 0.46, r * 1.08, r * 1.08)
                line(r * 0.68, r * 1.02, r * 0.92, r * 1.26)
                line(r * 0.92, r * 1.26, r * 1.34, r * 0.74)
                break
            case "trash":
                line(r * 0.55, r * 0.68, r * 1.45, r * 1.48)
                line(r * 1.45, r * 0.68, r * 0.55, r * 1.48)
                rect(r * 0.46, r * 0.58, r * 1.08, r * 0.98)
                break
            case "premium":
                line(cx, r * 0.42, r * 1.5, r * 1.34)
                line(cx, r * 0.42, r * 0.5, r * 1.34)
                line(r * 0.5, r * 1.34, r * 1.5, r * 1.34)
                break
            default:
                circle(cx, cy, r * 0.4, false)
                break
            }
        }
    }
}

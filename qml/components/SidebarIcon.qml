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
                ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke()
            }

            function circle(x, y, rr, fill) {
                ctx.beginPath(); ctx.arc(x, y, rr, 0, Math.PI * 2)
                fill ? ctx.fill() : ctx.stroke()
            }

            function roundRect(x, y, rw, rh, rad) {
                ctx.beginPath()
                ctx.moveTo(x + rad, y)
                ctx.lineTo(x + rw - rad, y)
                ctx.arcTo(x + rw, y, x + rw, y + rad, rad)
                ctx.lineTo(x + rw, y + rh - rad)
                ctx.arcTo(x + rw, y + rh, x + rw - rad, y + rh, rad)
                ctx.lineTo(x + rad, y + rh)
                ctx.arcTo(x, y + rh, x, y + rh - rad, rad)
                ctx.lineTo(x, y + rad)
                ctx.arcTo(x, y, x + rad, y, rad)
                ctx.closePath()
                ctx.stroke()
            }

            var p = s * 0.1  // padding

            switch (root.iconName) {
            case "tasks":
                roundRect(p, p, s - p*2, s - p*2, s*0.18)
                line(s*0.28, s*0.54, s*0.44, s*0.7)
                line(s*0.44, s*0.7, s*0.72, s*0.36)
                break
            case "calendar":
                roundRect(p, s*0.2, s - p*2, s*0.72, s*0.1)
                line(p, s*0.42, s - p, s*0.42)
                line(s*0.32, p, s*0.32, s*0.3)
                line(s*0.68, p, s*0.68, s*0.3)
                circle(s*0.36, s*0.68, s*0.06, true)
                circle(s*0.5,  s*0.68, s*0.06, true)
                circle(s*0.64, s*0.68, s*0.06, true)
                break
            case "matrix":
                roundRect(p, p, s*0.38, s*0.38, s*0.06)
                roundRect(s*0.52, p, s*0.38, s*0.38, s*0.06)
                roundRect(p, s*0.52, s*0.38, s*0.38, s*0.06)
                roundRect(s*0.52, s*0.52, s*0.38, s*0.38, s*0.06)
                break
            case "pomodoro":
                circle(cx, cy, s*0.38, false)
                line(cx, s*0.22, cx, cy)
                line(cx, cy, s*0.72, s*0.36)
                line(s*0.38, p*0.5, s*0.62, p*0.5)
                break
            case "habit":
                ctx.beginPath()
                ctx.arc(cx, cy, s*0.32, -Math.PI*0.65, Math.PI*0.7)
                ctx.stroke()
                line(s*0.76, s*0.66, s*0.88, s*0.54)
                line(s*0.76, s*0.66, s*0.64, s*0.58)
                break
            case "search":
                circle(s*0.4, s*0.4, s*0.26, false)
                ctx.lineWidth = root.strokeWidth * 1.2
                line(s*0.59, s*0.59, s*0.88, s*0.88)
                ctx.lineWidth = root.strokeWidth
                break
            case "sync":
                ctx.beginPath()
                ctx.arc(cx, cy, s*0.3, -Math.PI*0.5, Math.PI*0.55)
                ctx.stroke()
                line(s*0.76, s*0.56, s*0.88, s*0.7)
                line(s*0.76, s*0.56, s*0.62, s*0.64)
                ctx.beginPath()
                ctx.arc(cx, cy, s*0.3, Math.PI*0.55, Math.PI*1.5)
                ctx.stroke()
                line(s*0.24, s*0.44, s*0.12, s*0.3)
                line(s*0.24, s*0.44, s*0.38, s*0.36)
                break
            case "notifications":
                ctx.beginPath()
                ctx.arc(cx, s*0.42, s*0.22, Math.PI, 0)
                ctx.lineTo(s*0.78, s*0.72)
                ctx.lineTo(s*0.22, s*0.72)
                ctx.closePath()
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(cx, s*0.74, s*0.1, 0, Math.PI)
                ctx.stroke()
                line(s*0.42, s*0.22, s*0.58, s*0.22)
                break
            case "help":
                circle(cx, cy, s*0.38, false)
                ctx.font = "bold " + Math.round(s*0.46) + "px sans-serif"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.fillText("?", cx, cy + s*0.02)
                break
            case "all":
                circle(s*0.18, s*0.28, s*0.07, true)
                line(s*0.3, s*0.28, s*0.9, s*0.28)
                circle(s*0.18, s*0.5, s*0.07, true)
                line(s*0.3, s*0.5, s*0.9, s*0.5)
                circle(s*0.18, s*0.72, s*0.07, true)
                line(s*0.3, s*0.72, s*0.9, s*0.72)
                break
            case "today":
                roundRect(p, s*0.2, s - p*2, s*0.72, s*0.1)
                line(p, s*0.42, s - p, s*0.42)
                line(s*0.32, p, s*0.32, s*0.3)
                line(s*0.68, p, s*0.68, s*0.3)
                circle(cx, s*0.65, s*0.1, true)
                break
            case "next":
                roundRect(p, s*0.2, s - p*2, s*0.72, s*0.1)
                line(p, s*0.42, s - p, s*0.42)
                line(s*0.32, p, s*0.32, s*0.3)
                line(s*0.68, p, s*0.68, s*0.3)
                ctx.font = "bold " + Math.round(s*0.3) + "px sans-serif"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.fillText("7", cx, s*0.65)
                break
            case "inbox":
            case "list":
                line(p, s*0.55, p, s*0.88)
                line(p, s*0.88, s-p, s*0.88)
                line(s-p, s*0.88, s-p, s*0.55)
                ctx.beginPath()
                ctx.moveTo(p, s*0.55)
                ctx.quadraticCurveTo(s*0.24, s*0.34, s*0.38, s*0.34)
                ctx.lineTo(s*0.62, s*0.34)
                ctx.quadraticCurveTo(s*0.76, s*0.34, s-p, s*0.55)
                ctx.stroke()
                break
            case "folder":
                ctx.beginPath()
                ctx.moveTo(p, s*0.38)
                ctx.lineTo(p, s*0.88)
                ctx.lineTo(s-p, s*0.88)
                ctx.lineTo(s-p, s*0.46)
                ctx.lineTo(s*0.52, s*0.46)
                ctx.lineTo(s*0.38, s*0.3)
                ctx.lineTo(p*2, s*0.3)
                ctx.closePath()
                ctx.stroke()
                break
            case "summary":
                roundRect(s*0.2, p, s*0.6, s - p*2, s*0.08)
                line(s*0.34, s*0.36, s*0.66, s*0.36)
                line(s*0.34, s*0.5,  s*0.66, s*0.5)
                line(s*0.34, s*0.64, s*0.54, s*0.64)
                break
            case "flag":
                line(s*0.26, p, s*0.26, s-p)
                ctx.beginPath()
                ctx.moveTo(s*0.26, s*0.14)
                ctx.lineTo(s*0.86, s*0.36)
                ctx.lineTo(s*0.26, s*0.58)
                ctx.closePath()
                ctx.fill()
                break
            case "flag-empty":
                line(s*0.26, p, s*0.26, s-p)
                ctx.beginPath()
                ctx.moveTo(s*0.26, s*0.14)
                ctx.lineTo(s*0.86, s*0.36)
                ctx.lineTo(s*0.26, s*0.58)
                ctx.closePath()
                ctx.stroke()
                break
            case "tag":
                ctx.beginPath()
                ctx.moveTo(s*0.18, s*0.18)
                ctx.lineTo(s*0.62, s*0.18)
                ctx.lineTo(s*0.88, s*0.5)
                ctx.lineTo(s*0.62, s*0.82)
                ctx.lineTo(s*0.18, s*0.82)
                ctx.closePath()
                ctx.stroke()
                circle(s*0.34, s*0.34, s*0.08, true)
                break
            case "subtasks":
                line(s*0.24, s*0.2, s*0.24, s*0.72)
                line(s*0.24, s*0.72, s*0.46, s*0.72)
                line(s*0.46, s*0.72, s*0.38, s*0.62)
                line(s*0.46, s*0.72, s*0.38, s*0.82)
                circle(s*0.24, s*0.2, s*0.07, true)
                line(s*0.56, s*0.3, s*0.88, s*0.3)
                line(s*0.56, s*0.5, s*0.88, s*0.5)
                line(s*0.56, s*0.7, s*0.76, s*0.7)
                break
            case "attachment":
                ctx.beginPath()
                ctx.arc(s*0.54, s*0.5, s*0.28, -Math.PI*0.8, Math.PI*0.2)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(s*0.54, s*0.5, s*0.16, -Math.PI*0.8, Math.PI*0.2)
                ctx.stroke()
                break
            case "template":
                roundRect(s*0.2, p, s*0.6, s - p*2, s*0.08)
                line(s*0.34, s*0.36, s*0.66, s*0.36)
                line(s*0.34, s*0.5,  s*0.66, s*0.5)
                line(s*0.34, s*0.64, s*0.54, s*0.64)
                break
            case "settings":
                circle(cx, cy, s*0.14, false)
                for (var i = 0; i < 6; i++) {
                    var a = i * Math.PI / 3
                    line(cx + Math.cos(a)*s*0.22, cy + Math.sin(a)*s*0.22,
                        cx + Math.cos(a)*s*0.38, cy + Math.sin(a)*s*0.38)
                }
                break
            case "chevronDown":
                line(s*0.24, s*0.36, cx, s*0.64)
                line(cx, s*0.64, s*0.76, s*0.36)
                break
            case "completed":
                roundRect(p, p, s - p*2, s - p*2, s*0.14)
                line(s*0.28, s*0.52, s*0.44, s*0.7)
                line(s*0.44, s*0.7, s*0.74, s*0.3)
                break
            case "trash":
                line(s*0.14, s*0.28, s*0.86, s*0.28)
                line(s*0.36, s*0.28, s*0.36, s*0.16)
                line(s*0.36, s*0.16, s*0.64, s*0.16)
                line(s*0.64, s*0.16, s*0.64, s*0.28)
                ctx.beginPath()
                ctx.moveTo(s*0.22, s*0.28)
                ctx.lineTo(s*0.3,  s*0.86)
                ctx.lineTo(s*0.7,  s*0.86)
                ctx.lineTo(s*0.78, s*0.28)
                ctx.stroke()
                line(s*0.5,  s*0.4, s*0.5,  s*0.76)
                line(s*0.38, s*0.41, s*0.4, s*0.76)
                line(s*0.62, s*0.41, s*0.6, s*0.76)
                break
            case "premium":
                ctx.beginPath()
                ctx.moveTo(s*0.1, s*0.78)
                ctx.lineTo(s*0.1, s*0.44)
                ctx.lineTo(s*0.34, s*0.62)
                ctx.lineTo(s*0.5,  s*0.2)
                ctx.lineTo(s*0.66, s*0.62)
                ctx.lineTo(s*0.9,  s*0.44)
                ctx.lineTo(s*0.9,  s*0.78)
                ctx.closePath()
                ctx.stroke()
                break
            default:
                circle(cx, cy, s*0.3, false)
                break
            }
        }
    }
}

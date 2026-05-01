pragma Singleton
import QtQuick

QtObject {
    id: theme

    // Colors - Premium Dark Mode
    readonly property color background: "#111214"
    readonly property color surface: "#17191d"
    readonly property color surfaceHover: "#20242b"
    readonly property color panel: "#15171b"
    readonly property color panelAlt: "#101216"
    
    readonly property color primary: "#3b82f6" // Vibrant Blue
    readonly property color primaryHover: "#2563eb"
    
    readonly property color textPrimary: "#f8fafc"
    readonly property color textSecondary: "#aeb4bf"
    readonly property color textMuted: "#6f7683"

    readonly property color divider: "#252a32"
    
    readonly property color accentRed: "#ef4444"
    readonly property color accentGreen: "#10b981"
    readonly property color accentYellow: "#f59e0b"

    // Typography
    readonly property string fontFamily: "Inter, Roboto, sans-serif"
    
    // Spacing & Radii
    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 10
    readonly property int radiusLarge: 12
}

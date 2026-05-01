pragma Singleton
import QtQuick

QtObject {
    id: theme

    // Colors - Premium Dark Mode
    readonly property color background: "#0a0a0a" // Very dark gray/black
    readonly property color surface: "#141414"   // Slightly lighter for cards/sidebar
    readonly property color surfaceHover: "#232323" // Hover states
    
    readonly property color primary: "#3b82f6" // Vibrant Blue
    readonly property color primaryHover: "#2563eb"
    
    readonly property color textPrimary: "#f8fafc"
    readonly property color textSecondary: "#94a3b8"
    readonly property color textMuted: "#475569"

    readonly property color divider: "#1e293b"
    
    readonly property color accentRed: "#ef4444"
    readonly property color accentGreen: "#10b981"
    readonly property color accentYellow: "#f59e0b"

    // Typography
    readonly property string fontFamily: "Inter, Roboto, sans-serif"
    
    // Spacing & Radii
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 12
}

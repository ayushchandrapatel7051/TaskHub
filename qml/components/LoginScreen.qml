import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    color: Theme.background
    anchors.fill: parent

    property bool isLoginMode: true

    // Listen for auth errors
    Connections {
        target: authService
        function onAuthError(errorMessage) {
            errorText.text = errorMessage
            errorText.visible = true
            loginButtonRect.enabled = true
            loginButtonText.text = isLoginMode ? "Login" : "Sign Up"
        }
        function onAuthStateChanged(isAuthenticated) {
            if (isAuthenticated) {
                // Main.qml will handle the view switch, just clean up state
                loginButtonRect.enabled = true
                loginButtonText.text = isLoginMode ? "Login" : "Sign Up"
                errorText.visible = false
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(400, parent.width * 0.9)
        spacing: 20

        // Logo/Title
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "TaskHub"
            color: Theme.primary
            font.pixelSize: 36
            font.bold: true
            font.family: Theme.fontFamily
            Layout.bottomMargin: 10
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: isLoginMode ? "Welcome back" : "Create an account"
            color: Theme.textSecondary
            font.pixelSize: 18
            font.family: Theme.fontFamily
            Layout.bottomMargin: 20
        }

        // Email Input
        Rectangle {
            Layout.fillWidth: true
            height: 50
            color: Theme.surface
            radius: Theme.radiusMedium
            border.color: emailField.activeFocus ? Theme.primary : Theme.divider
            border.width: emailField.activeFocus ? 2 : 1

            TextField {
                id: emailField
                anchors.fill: parent
                anchors.margins: 10
                placeholderText: "Email"
                color: Theme.textPrimary
                font.pixelSize: 16
                font.family: Theme.fontFamily
                background: null
                KeyNavigation.tab: passwordField
            }
        }

        // Password Input
        Rectangle {
            Layout.fillWidth: true
            height: 50
            color: Theme.surface
            radius: Theme.radiusMedium
            border.color: passwordField.activeFocus ? Theme.primary : Theme.divider
            border.width: passwordField.activeFocus ? 2 : 1

            TextField {
                id: passwordField
                anchors.fill: parent
                anchors.margins: 10
                placeholderText: "Password"
                color: Theme.textPrimary
                font.pixelSize: 16
                font.family: Theme.fontFamily
                echoMode: TextInput.Password
                background: null
                
                onAccepted: loginMouseArea.clicked(null)
            }
        }

        // Error Message
        Text {
            id: errorText
            Layout.fillWidth: true
            color: Theme.accentRed
            font.pixelSize: 14
            font.family: Theme.fontFamily
            visible: false
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        // Login Button
        Rectangle {
            id: loginButtonRect
            Layout.fillWidth: true
            Layout.topMargin: 10
            height: 50
            color: loginMouseArea.pressed ? Theme.primaryHover : Theme.primary
            radius: Theme.radiusMedium
            
            Text {
                id: loginButtonText
                anchors.centerIn: parent
                text: isLoginMode ? "Login" : "Sign Up"
                color: "white"
                font.pixelSize: 16
                font.bold: true
                font.family: Theme.fontFamily
            }
            
            MouseArea {
                id: loginMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (emailField.text.trim() === "" || passwordField.text.trim() === "") {
                        errorText.text = "Please enter both email and password."
                        errorText.visible = true
                        return
                    }
                    
                    errorText.visible = false
                    loginButtonText.text = "Authenticating..."
                    loginButtonRect.enabled = false
                    
                    if (isLoginMode) {
                        authService.login(emailField.text, passwordField.text)
                    } else {
                        authService.signup(emailField.text, passwordField.text)
                    }
                }
            }
        }

        // Mode Toggle
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            text: isLoginMode ? "Don't have an account? Sign up" : "Already have an account? Login"
            color: Theme.textMuted
            font.pixelSize: 14
            font.family: Theme.fontFamily
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    isLoginMode = !isLoginMode
                    errorText.visible = false
                }
            }
        }
    }
}

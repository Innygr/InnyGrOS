import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: 1280
    height: 720
    property string loginError: ""
    property int sessionIndex: 0
    property color neon: "#54ff9a"
    property color paleNeon: "#c6ffdc"
    property color dimNeon: "#1b8e51"

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#020805" }
            GradientStop { position: 0.48; color: "#06150d" }
            GradientStop { position: 1.0; color: "#010302" }
        }
    }

    // Subtle terminal grid gives the background depth without needing image assets.
    Repeater {
        model: 18
        delegate: Rectangle {
            x: index * root.width / 18
            width: 1
            height: root.height
            color: "#16452b"
            opacity: 0.22
        }
    }
    Repeater {
        model: 12
        delegate: Rectangle {
            y: index * root.height / 12
            width: root.width
            height: 1
            color: "#16452b"
            opacity: 0.18
        }
    }

    // Animated binary rain; the brighter foreground lanes make the theme visible at a glance.
    Repeater {
        model: 34
        delegate: Item {
            id: rainLane
            property int lane: index
            width: root.width / 34
            height: root.height
            x: lane * width

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: -height
                text: "1\n0\n1\n1\n0\n0\n1\n0\n1\n0\n1\n1\n0\n1\n0"
                color: root.neon
                opacity: 0.20 + ((lane * 7) % 5) * 0.035
                font.family: "monospace"
                font.pixelSize: 15
                lineHeight: 1.15

                NumberAnimation on y {
                    from: -parent.height * 1.4
                    to: root.height
                    duration: 5200 + ((rainLane.lane * 379) % 5900)
                    loops: Animation.Infinite
                }
            }
        }
    }

    // Corner brackets and perimeter lights frame the screen like a secure system console.
    Repeater {
        model: [
            { x: 28, y: 28, sx: 1, sy: 1 },
            { x: root.width - 88, y: 28, sx: -1, sy: 1 },
            { x: 28, y: root.height - 58, sx: 1, sy: -1 },
            { x: root.width - 88, y: root.height - 58, sx: -1, sy: -1 }
        ]
        delegate: Item {
            x: modelData.x
            y: modelData.y
            width: 60
            height: 30
            Rectangle {
                x: modelData.sx > 0 ? 0 : parent.width - width
                y: modelData.sy > 0 ? 0 : parent.height - height
                width: 60
                height: 2
                color: root.neon
                opacity: 0.9
            }
            Rectangle {
                x: modelData.sx > 0 ? 0 : parent.width - width
                y: modelData.sy > 0 ? 0 : parent.height - height
                width: 2
                height: 30
                color: root.neon
                opacity: 0.9
            }
        }
    }

    Row {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 30
        spacing: 10

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: root.neon
            anchors.verticalCenter: parent.verticalCenter
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.25; duration: 650 }
                NumberAnimation { to: 1.0; duration: 650 }
            }
        }
        Text {
            text: "INNYGRCORP  //  BLACKLIGHT SECURE NODE"
            color: root.paleNeon
            font.family: "monospace"
            font.pixelSize: 12
            font.letterSpacing: 2
        }
    }

    Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 54
        spacing: 10
        visible: root.width >= 1100
        Text {
            text: "NETWORK"
            color: root.dimNeon
            font.family: "monospace"
            font.pixelSize: 10
            font.bold: true
        }
        Text {
            text: "BLACKLIGHT"
            color: root.neon
            font.family: "monospace"
            font.pixelSize: 17
            font.bold: true
        }
        Text {
            text: "LOCAL NODE: ACTIVE\nENCRYPTION: READY\nAUTH: REQUIRED"
            color: "#79a98b"
            font.family: "monospace"
            font.pixelSize: 10
            lineHeight: 1.5
        }
        Rectangle { width: 150; height: 1; color: root.dimNeon; opacity: 0.8 }
        Text {
            text: "SYS://INNYGROS"
            color: "#447858"
            font.family: "monospace"
            font.pixelSize: 10
        }
    }

    Column {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 54
        spacing: 10
        visible: root.width >= 1100
        Text {
            text: "BOOT STATUS"
            color: root.dimNeon
            font.family: "monospace"
            font.pixelSize: 10
            font.bold: true
        }
        Text {
            text: "KERNEL ........ OK\nDISPLAY ....... OK\nUSER SESSION .. WAIT"
            color: "#79a98b"
            font.family: "monospace"
            font.pixelSize: 10
            lineHeight: 1.5
        }
        Rectangle { width: 150; height: 1; color: root.dimNeon; opacity: 0.8 }
        Text {
            text: "AWAITING INPUT_"
            color: root.neon
            font.family: "monospace"
            font.pixelSize: 10
        }
    }

    Rectangle {
        id: panel
        width: Math.min(root.width - 48, 500)
        height: 530
        anchors.centerIn: parent
        radius: 4
        color: "#07110c"
        border.color: root.neon
        border.width: 1

        Rectangle {
            anchors.fill: parent
            anchors.margins: 5
            color: "transparent"
            border.color: "#1a6039"
            border.width: 1
            radius: 2
        }

        Rectangle {
            width: parent.width
            height: 3
            color: root.neon
        }
        Rectangle {
            width: 72
            height: 3
            anchors.right: parent.right
            anchors.top: parent.top
            color: "#c8ffdc"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 34
            spacing: 13

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 58
                height: 58
                radius: 29
                color: "#061c10"
                border.color: root.neon
                border.width: 1
                Layout.bottomMargin: 2

                Text {
                    anchors.centerIn: parent
                    text: "B"
                    color: root.neon
                    font.family: "monospace"
                    font.pixelSize: 34
                    font.bold: true
                }
            }

            Text {
                text: "INNYGRCORP"
                color: root.neon
                font.family: "monospace"
                font.pixelSize: 27
                font.bold: true
                font.letterSpacing: 3
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "// BLACKLIGHT MATRIX"
                color: root.paleNeon
                font.family: "monospace"
                font.pixelSize: 13
                font.letterSpacing: 2
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 3
                Layout.bottomMargin: 3
                height: 1
                color: root.dimNeon
            }

            Text {
                text: "AUTHENTICATION REQUIRED"
                color: root.neon
                font.family: "monospace"
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1
                Layout.alignment: Qt.AlignHCenter
            }

            TextField {
                id: usernameField
                Layout.fillWidth: true
                Layout.preferredHeight: 43
                placeholderText: "USERNAME"
                selectByMouse: true
                color: root.paleNeon
                placeholderTextColor: "#739681"
                font.family: "monospace"
                leftPadding: 13
                background: Rectangle {
                    color: "#020805"
                    border.color: usernameField.activeFocus ? root.neon : "#28563a"
                    border.width: usernameField.activeFocus ? 2 : 1
                    radius: 2
                }
                onAccepted: passwordField.forceActiveFocus()
            }

            TextField {
                id: passwordField
                Layout.fillWidth: true
                Layout.preferredHeight: 43
                placeholderText: "PASSWORD"
                echoMode: TextInput.Password
                selectByMouse: true
                color: root.paleNeon
                placeholderTextColor: "#739681"
                font.family: "monospace"
                leftPadding: 13
                background: Rectangle {
                    color: "#020805"
                    border.color: passwordField.activeFocus ? root.neon : "#28563a"
                    border.width: passwordField.activeFocus ? 2 : 1
                    radius: 2
                }
                onAccepted: loginButton.clicked()
            }

            ComboBox {
                id: sessionBox
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                model: sessionModel
                textRole: "name"
                currentIndex: root.sessionIndex
                enabled: sessionModel.count > 1
                font.family: "monospace"
                background: Rectangle {
                    color: "#020805"
                    border.color: "#28563a"
                    radius: 2
                }
                contentItem: Text {
                    leftPadding: 12
                    text: sessionBox.displayText
                    color: root.paleNeon
                    font: sessionBox.font
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                onActivated: root.sessionIndex = currentIndex
            }

            Text {
                Layout.fillWidth: true
                visible: root.loginError.length > 0
                text: root.loginError
                color: "#ff7777"
                wrapMode: Text.Wrap
                font.family: "monospace"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                id: loginButton
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                text: "INITIALIZE SESSION  >"
                enabled: usernameField.text.length > 0 && passwordField.text.length > 0
                onClicked: {
                    root.loginError = ""
                    sddm.login(usernameField.text, passwordField.text, sessionBox.currentIndex)
                }
                contentItem: Text {
                    text: loginButton.text
                    color: loginButton.enabled ? "#021108" : "#72927d"
                    font.family: "monospace"
                    font.bold: true
                    font.pixelSize: 12
                    font.letterSpacing: 1
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 2
                    color: loginButton.enabled ? root.neon : "#183323"
                    border.color: root.neon
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                text: "SECURE SYSTEM ACCESS  //  LOCAL LOGIN"
                color: "#4e8061"
                font.family: "monospace"
                font.pixelSize: 9
                font.letterSpacing: 1
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 26
        text: "BLACKLIGHT MATRIX  /  INNYGROS  /  SYSTEM READY"
        color: "#447858"
        font.family: "monospace"
        font.pixelSize: 10
        font.letterSpacing: 2
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.loginError = "Authentication failed. Check credentials and try again."
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
    }

    Component.onCompleted: usernameField.forceActiveFocus()
}

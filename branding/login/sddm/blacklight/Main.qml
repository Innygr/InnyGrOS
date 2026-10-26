import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: 1280
    height: 720
    property string loginError: ""
    property int sessionIndex: 0

    Rectangle {
        anchors.fill: parent
        color: "#030706"
    }

    // Lightweight code-rain background: no external images or network access.
    Repeater {
        model: 28
        delegate: Item {
            id: rainLane
            property int lane: index
            width: root.width / 28
            height: root.height
            x: lane * width

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: -height
                text: "1\n0\n1\n1\n0\n0\n1\n0\n1\n0\n1\n1\n0\n1\n0"
                color: "#35ff82"
                opacity: 0.13 + ((lane * 7) % 5) * 0.025
                font.family: "monospace"
                font.pixelSize: 15
                lineHeight: 1.15

                NumberAnimation on y {
                    from: -parent.height * 1.4
                    to: root.height
                    duration: 6500 + ((rainLane.lane * 379) % 6200)
                    loops: Animation.Infinite
                }
            }
        }
    }

    Rectangle {
        id: panel
        width: Math.min(root.width - 48, 500)
        height: 510
        anchors.centerIn: parent
        radius: 10
        color: "#08120d"
        border.color: "#1d9f54"
        border.width: 1

        Rectangle {
            width: parent.width
            height: 3
            color: "#39ff88"
            radius: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 34
            spacing: 15

            Text {
                text: "INNYGRCORP"
                color: "#47ff91"
                font.family: "monospace"
                font.pixelSize: 28
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "// BLACKLIGHT MATRIX"
                color: "#9cc8ae"
                font.family: "monospace"
                font.pixelSize: 14
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 5
                Layout.bottomMargin: 5
                height: 1
                color: "#245b3a"
            }

            Text {
                text: "AUTHENTICATION REQUIRED"
                color: "#47ff91"
                font.family: "monospace"
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter
            }

            TextField {
                id: usernameField
                Layout.fillWidth: true
                placeholderText: "Username"
                selectByMouse: true
                color: "#e2ffeb"
                placeholderTextColor: "#739681"
                font.family: "monospace"
                background: Rectangle {
                    color: "#030906"
                    border.color: usernameField.activeFocus ? "#47ff91" : "#28563a"
                    radius: 4
                }
                onAccepted: passwordField.forceActiveFocus()
            }

            TextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: "Password"
                echoMode: TextInput.Password
                selectByMouse: true
                color: "#e2ffeb"
                placeholderTextColor: "#739681"
                font.family: "monospace"
                background: Rectangle {
                    color: "#030906"
                    border.color: passwordField.activeFocus ? "#47ff91" : "#28563a"
                    radius: 4
                }
                onAccepted: loginButton.clicked()
            }

            ComboBox {
                id: sessionBox
                Layout.fillWidth: true
                model: sessionModel
                textRole: "name"
                currentIndex: root.sessionIndex
                enabled: sessionModel.count > 1
                font.family: "monospace"
                onActivated: root.sessionIndex = currentIndex
            }

            Text {
                Layout.fillWidth: true
                visible: root.loginError.length > 0
                text: root.loginError
                color: "#ff7b7b"
                wrapMode: Text.Wrap
                font.family: "monospace"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                id: loginButton
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                text: "INITIALIZE SESSION"
                enabled: usernameField.text.length > 0 && passwordField.text.length > 0
                onClicked: {
                    root.loginError = ""
                    sddm.login(usernameField.text, passwordField.text, sessionBox.currentIndex)
                }
                contentItem: Text {
                    text: loginButton.text
                    color: loginButton.enabled ? "#031108" : "#72927d"
                    font.family: "monospace"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 4
                    color: loginButton.enabled ? "#47ff91" : "#183323"
                    border.color: "#47ff91"
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                text: "INNYGROS // SYSTEM ACCESS"
                color: "#4e8061"
                font.family: "monospace"
                font.pixelSize: 10
                Layout.alignment: Qt.AlignHCenter
            }
        }
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

/*
    IntegerOS startup splash for KDE Plasma (KSplashQML).
    Uses only QtQuick so it loads on Plasma 5 (Qt 5) and Plasma 6 (Qt 6).
    KSplash sets `stage` from 1 to 6 while the session starts.
*/
import QtQuick 2.15

Rectangle {
    id: root
    color: "#080b16"

    property int stage

    gradient: Gradient {
        GradientStop { position: 0.0; color: "#080b16" }
        GradientStop { position: 0.55; color: "#111025" }
        GradientStop { position: 1.0; color: "#06131d" }
    }

    onStageChanged: {
        if (stage === 2) {
            introAnimation.running = true;
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Image {
            id: logo
            readonly property real size: Math.round(Math.min(root.width, root.height) * 0.16)
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -size * 0.25
            source: "images/logo.svg"
            sourceSize.width: size
            sourceSize.height: size
            asynchronous: true
        }

        Text {
            id: title
            anchors.top: logo.bottom
            anchors.topMargin: logo.size * 0.18
            anchors.horizontalCenter: parent.horizontalCenter
            text: "IntegerOS"
            color: "#f5f2ff"
            font.pixelSize: Math.max(18, logo.size * 0.22)
            font.weight: Font.DemiBold
            font.letterSpacing: 2
        }

        // Progress follows the startup stages; it is not a time estimate.
        Rectangle {
            id: track
            anchors.top: title.bottom
            anchors.topMargin: logo.size * 0.2
            anchors.horizontalCenter: parent.horizontalCenter
            width: logo.size * 1.4
            height: Math.max(3, Math.round(logo.size * 0.025))
            radius: height / 2
            color: "#24203d"

            Rectangle {
                height: parent.height
                radius: parent.radius
                width: parent.width * Math.min(1, Math.max(0, root.stage) / 6)
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#b18cff" }
                    GradientStop { position: 1.0; color: "#00d9f5" }
                }
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }

        Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Math.max(16, logo.size * 0.15)
            text: "IntegerOS · Team Blacklight"
            color: "#8e91ac"
            font.pixelSize: Math.max(12, logo.size * 0.09)
            font.letterSpacing: 1
        }
    }

    OpacityAnimator {
        id: introAnimation
        running: false
        target: content
        from: 0
        to: 1
        duration: 600
        easing.type: Easing.InOutQuad
    }
}

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var theme: ({})

    function t(key, fallback) { return theme[key] || fallback }

    // Active fcitx5 input method, e.g. "keyboard-us" or "unikey".
    // Kept in sync by polling `fcitx5-remote -n`.
    property string imName: ""

    // Turn a fcitx5 input method name into a short badge.
    // "unikey" -> "VI", "keyboard-us" -> "EN".
    function shortCode(name) {
        if (name === "unikey")
            return "VI"
        if (name === "" || name.indexOf("keyboard-us") === 0)
            return "EN"
        return name.replace(/[^A-Za-z]/g, "").slice(0, 2).toUpperCase()
    }

    // Poll fcitx5 for the currently active input method.
    Process {
        id: queryIm
        command: ["fcitx5-remote", "-n"]
        stdout: SplitParser {
            onRead: line => {
                const s = line.trim()
                if (s)
                    root.imName = s
            }
        }
    }

    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: queryIm.running = true
    }

    implicitWidth: layoutRow.implicitWidth
    implicitHeight: parent ? parent.height : 28
    visible: root.imName !== ""

    Row {
        id: layoutRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰌌"
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font Propo"
            color: kbMa.containsMouse ? root.t("accent", "#89b4fa") : root.t("muted", "#585b70")
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.shortCode(root.imName)
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.family: "JetBrainsMono Nerd Font Propo"
            color: kbMa.containsMouse ? root.t("accent", "#89b4fa") : root.t("fg", "#cdd6f4")
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: kbMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // Toggle fcitx5 between English (keyboard-us) and Vietnamese (Unikey).
        onClicked: {
            const target = root.imName === "unikey" ? "keyboard-us" : "unikey"
            Quickshell.execDetached(["fcitx5-remote", "-s", target])
        }
    }
}

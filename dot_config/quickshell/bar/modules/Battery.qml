import QtQuick
import Quickshell.Services.UPower

Item {
    id: root

    property var theme: ({})

    function t(key, fallback) { return theme[key] || fallback }

    readonly property var device: UPower.displayDevice
    readonly property real percent: device ? device.percentage * 100 : 0
    readonly property bool charging: device
        && (device.state === UPowerDeviceState.Charging
            || device.state === UPowerDeviceState.FullyCharged)
    readonly property bool low: !charging && root.percent <= 15

    function icon() {
        const discharge = ["\u{f008e}", "\u{f007a}", "\u{f007b}", "\u{f007c}", "\u{f007d}",
                           "\u{f007e}", "\u{f007f}", "\u{f0080}", "\u{f0081}", "\u{f0082}", "\u{f0079}"]
        const charge    = ["\u{f089f}", "\u{f089c}", "\u{f0086}", "\u{f0087}", "\u{f0088}",
                           "\u{f089d}", "\u{f0089}", "\u{f089e}", "\u{f008a}", "\u{f008b}", "\u{f0085}"]
        const idx = Math.min(10, Math.max(0, Math.round(root.percent / 10)))
        return root.charging ? charge[idx] : discharge[idx]
    }

    implicitWidth: batRow.implicitWidth
    implicitHeight: parent ? parent.height : 28
    visible: device && device.isLaptopBattery

    Row {
        id: batRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon()
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font Propo"
            color: root.low
                ? root.t("red", "#f38ba8")
                : root.charging
                    ? root.t("green", "#a6e3a1")
                    : root.t("muted", "#585b70")
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.percent) + "%"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.family: "JetBrainsMono Nerd Font Propo"
            color: root.low ? root.t("red", "#f38ba8") : root.t("fg", "#cdd6f4")
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }
}

pragma Singleton
import QtQuick

QtObject {
    id: root

    function buildTree() {
        return [
            {
                icon: "󰀻", label: "Apps",
                action: "apps"
            },
            {
                icon: "󰅌", label: "Clipboard",
                action: "openClipboard"
            },
            {
                icon: "󰐥", label: "Power",
                children: [
                    { icon: "󰐥", label: "Shutdown", cmd: "systemctl poweroff" },
                    { icon: "󰜉", label: "Restart",  cmd: "systemctl reboot" },
                    { icon: "󰒲", label: "Sleep",    cmd: "systemctl suspend" },
                ]
            },
        ]
    }
}

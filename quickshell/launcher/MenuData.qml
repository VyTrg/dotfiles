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
        ]
    }
}

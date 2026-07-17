//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "bar"
import "bar/modules"

import "settings"
import "launcher"
import "taskmanager"

ShellRoot {
    id: shell

    property string bg:        "#1e1e2e"
    property string fg:        "#cdd6f4"
    property string accent:    "#89b4fa"
    property string dim:       "#45475a"
    property string highlight: "#cba6f7"
    property string red:       "#f38ba8"
    property string green:     "#a6e3a1"
    property string muted:     "#585b70"
    readonly property var palette: ({
        bg:        shell.bg,
        fg:        shell.fg,
        accent:    shell.accent,
        dim:       shell.dim,
        muted:     shell.muted,
        highlight: shell.highlight,
        red:       shell.red,
        green:     shell.green
    })

    SettingsState {
        id: settingsState
    }

    // The QsScreen the bar + popups should live on: the configured main screen
    // when connected, otherwise the only screen present. Re-evaluates on hotplug.
    readonly property var mainScreen: {
        const wanted = settingsState.mainScreen
        const list = Quickshell.screens
        for (let i = 0; i < list.length; i++)
            if (list[i].name === wanted)
                return list[i]
        return list.length > 0 ? list[0] : null
    }

    QtObject {
        id: powerActions

        property bool open: false
        property string title: ""
        property string message: ""
        property var command: null
        property int selectedIndex: 0

        function requestAction(titleText, messageText, cmd) {
            title = titleText
            message = messageText
            command = cmd
            selectedIndex = 0
            open = true
        }

        function close() {
            open = false
            command = null
            selectedIndex = 0
        }

        function moveSelection(delta) {
            selectedIndex = (selectedIndex + delta + 2) % 2
        }

        function activateSelected() {
            if (selectedIndex === 0) close()
            else confirm()
        }

        function confirm() {
            if (!command) {
                close()
                return
            }

            // `command` may be a plain string, a JS Array, or a QVariantList
            // (when it comes from a QML model via modelData — Array.isArray()
            // returns false for those). Normalize to a real string array.
            if (typeof command === "string") {
                Quickshell.execDetached(["bash", "-lc", command])
            } else {
                var argv = []
                for (var i = 0; i < command.length; i++)
                    argv.push("" + command[i])
                Quickshell.execDetached(argv)
            }

            close()
        }
    }

    Bar {
        screen: shell.mainScreen
        launcher:  appLauncher
        notifServer: notifServer
        settings: settingsState
        bg:        shell.bg
        fg:        shell.fg
        accent:    shell.accent
        dim:       shell.dim
        highlight: shell.highlight
        red:       shell.red
        green:     shell.green
        muted:     shell.muted
    }

    ControlCenter {
        id: controlCenter
        screen: shell.mainScreen
        theme: shell.palette
        notifServer: notifServer
        powerActions: powerActions
        settingsWindow: settingsWindow
    }

    Launcher {
        id: appLauncher
        theme: shell.palette
    }

    Clipboard {
        id: clipboardManager
        theme: shell.palette
    }

    TaskManager {
        id: taskManager
        theme: shell.palette
    }

    SettingsWindow {
        id: settingsWindow
        theme: shell.palette
        state: settingsState
    }

    NotificationPanel {
        theme: shell.palette
        settings: settingsState
    }

    OsdService {
        id: osdService
    }

    Osd {
        service: osdService
        settings: settingsState
        theme: shell.palette
    }

    NotificationServer {
        id: notifServer
    }

    IpcHandler {
        target: "openSettings"
        function handle() {
            settingsWindow.showing = true
        }
    }

    PanelWindow {
        id: powerConfirm
        screen: shell.mainScreen
        visible: powerActions.open
        color: "transparent"
        anchors { top: true; left: true; right: true; bottom: true }
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        onVisibleChanged: {
            if (visible)
                powerConfirm.forceActiveFocus()
        }

        Keys.onPressed: event => {
            if (!powerActions.open) return

            if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                powerActions.moveSelection(-1)
                event.accepted = true
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                powerActions.moveSelection(1)
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                powerActions.activateSelected()
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                powerActions.close()
                event.accepted = true
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: powerActions.close()

            Rectangle {
                id: powerConfirmCard
                width: 320
                implicitHeight: contentColumn.implicitHeight + 32
                radius: 14
                color: shell.bg
                border.color: shell.dim
                border.width: 1
                anchors.centerIn: parent
                opacity: powerActions.open ? 1 : 0
                scale: powerActions.open ? 1 : 0.96

                Behavior on opacity {
                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                }

                Behavior on scale {
                    NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                ColumnLayout {
                    id: contentColumn
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: powerActions.title
                        color: shell.fg
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: powerActions.message
                        color: shell.muted
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font Propo"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            id: cancelButton
                            Layout.fillWidth: true
                            height: 32
                            radius: 9
                            color: powerActions.selectedIndex === 0
                                ? Qt.alpha(shell.accent, 0.16)
                                : Qt.alpha(shell.dim, 0.45)
                            border.color: powerActions.selectedIndex === 0
                                ? Qt.alpha(shell.accent, 0.5)
                                : Qt.alpha(shell.dim, 0.7)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: powerActions.selectedIndex === 0 ? shell.accent : shell.fg
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font Propo"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: powerActions.selectedIndex = 0
                                onClicked: powerActions.close()
                            }
                        }

                        Rectangle {
                            id: confirmButton
                            Layout.fillWidth: true
                            height: 32
                            radius: 9
                            color: powerActions.selectedIndex === 1
                                ? Qt.alpha(shell.red, 0.28)
                                : Qt.alpha(shell.red, 0.2)
                            border.color: powerActions.selectedIndex === 1
                                ? Qt.alpha(shell.red, 0.72)
                                : Qt.alpha(shell.red, 0.45)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Confirm"
                                color: powerActions.selectedIndex === 1 ? shell.fg : shell.red
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: powerActions.selectedIndex = 1
                                onClicked: powerActions.confirm()
                            }
                        }
                    }
                }
            }
        }
    }

    // ALL IpcHandler here for keybinds
    IpcHandler {
        target: "openMenu"
        function handle() {
            appLauncher.mode    = "menu"
            appLauncher.showing = true
        }
    }

    IpcHandler {
        target: "openApps"
        function handle() {
            appLauncher.mode          = "apps"
            appLauncher.appSearchText = ""
            appLauncher.showing       = true
        }
    }

    IpcHandler {
        target: "openClipboard"
        function handle() {
            clipboardManager.showing = true
        }
    }

    IpcHandler {
        target: "openTaskManager"
        function handle() {
            taskManager.showing = true
        }
    }

    IpcHandler {
        target: "toggleDnd"
        function handle() {
            notifServer.toggleDnd()
        }
    }

    IpcHandler {
        target: "osdVolume"
        function handle() {
            osdService.showVolume()
        }
    }

    IpcHandler {
        target: "osdVolumeUp"
        function handle() {
            osdService.volumeStep(5)
        }
    }

    IpcHandler {
        target: "osdVolumeDown"
        function handle() {
            osdService.volumeStep(-5)
        }
    }

    IpcHandler {
        target: "osdVolumeMute"
        function handle() {
            osdService.toggleMute()
        }
    }

    IpcHandler {
        target: "osdBrightness"
        function handle() {
            osdService.showBrightness()
        }
    }

    IpcHandler {
        target: "osdBrightnessUp"
        function handle() {
            osdService.brightnessStep(5)
        }
    }

    IpcHandler {
        target: "osdBrightnessDown"
        function handle() {
            osdService.brightnessStep(-5)
        }
    }

    IpcHandler {
        target: "osdMic"
        function handle() {
            osdService.showMic()
        }
    }

    IpcHandler {
        target: "osdMedia"
        function handle() {
            osdService.showMediaStatus()
        }
    }

    IpcHandler {
        target: "osdMediaPlayPause"
        function handle() {
            osdService.mediaPlayPause()
        }
    }

    IpcHandler {
        target: "osdMediaNext"
        function handle() {
            osdService.mediaNext()
        }
    }

    IpcHandler {
        target: "osdMediaPrev"
        function handle() {
            osdService.mediaPrev()
        }
    }

    // Click Catcher Here — one per monitor so an outside click dismisses in a
    // single click regardless of which screen the pointer is on.
    readonly property bool anyOverlayOpen: appLauncher.showing
        || clipboardManager.showing
        || notifServer.panelOpen
        || controlCenter.showing
        || controlCenter.wifiManagerOpen
        || controlCenter.btManagerOpen

    function dismissOverlays() {
        appLauncher.showing   = false
        clipboardManager.showing = false
        notifServer.panelOpen = false
        controlCenter.showing = false
        controlCenter.wifiManagerOpen = false
        controlCenter.btManagerOpen = false
    }

    Variants {
        model: Quickshell.screens
        ClickCatcher {
            required property var modelData
            screen: modelData
            active: shell.anyOverlayOpen
            onClicked: shell.dismissOverlays()
        }
    }

}

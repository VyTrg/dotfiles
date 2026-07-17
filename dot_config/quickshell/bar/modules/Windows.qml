import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// Open-apps taskbar: shows each open window as an app icon, resolved from the
// niri event stream. The focused window is highlighted and shows its name.
// Clicking a pill focuses that window. When `screenName` is set, only windows
// living on that output are shown (the bar passes its own output).
Item {
    id: root

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    property var theme: ({})

    // Output this bar lives on. Empty => show windows from every output.
    property string screenName: ""

    // [{ id, appId, title, wsId, focused }]
    property var windows: []
    // workspace_id -> output name, kept in sync from WorkspacesChanged.
    property var wsOutput: ({})

    readonly property var shownWindows: {
        const out = []
        for (let i = 0; i < windows.length; i++) {
            const w = windows[i]
            if (root.screenName === "" || root.wsOutput[w.wsId] === root.screenName)
                out.push(w)
        }
        return out
    }

    function _mk(w) {
        return {
            id:      w.id,
            appId:   w.app_id || "",
            title:   w.title || "",
            wsId:    w.workspace_id,
            focused: !!w.is_focused
        }
    }

    function handleEvent(line) {
        const text = line.trim()
        if (!text)
            return
        let ev
        try {
            ev = JSON.parse(text)
        } catch (e) {
            return
        }

        if (ev.WorkspacesChanged) {
            const map = {}
            for (const w of ev.WorkspacesChanged.workspaces)
                map[w.id] = w.output
            root.wsOutput = map
        } else if (ev.WindowsChanged) {
            root.windows = ev.WindowsChanged.windows.map(root._mk)
        } else if (ev.WindowOpenedOrChanged) {
            const w = ev.WindowOpenedOrChanged.window
            const arr = root.windows.slice()
            let found = false
            for (let i = 0; i < arr.length; i++) {
                if (arr[i].id === w.id) {
                    arr[i] = root._mk(w)
                    found = true
                    break
                }
            }
            if (!found)
                arr.push(root._mk(w))
            // niri marks the newly focused window; mirror that exclusivity.
            if (w.is_focused)
                for (let i = 0; i < arr.length; i++)
                    if (arr[i].id !== w.id)
                        arr[i].focused = false
            root.windows = arr
        } else if (ev.WindowClosed) {
            root.windows = root.windows.filter(x => x.id !== ev.WindowClosed.id)
        } else if (ev.WindowFocusChanged) {
            const id = ev.WindowFocusChanged.id
            const arr = root.windows.slice()
            for (let i = 0; i < arr.length; i++)
                arr[i].focused = (arr[i].id === id)
            root.windows = arr
        }
    }

    Process {
        id: niriWinEvents
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: line => root.handleEvent(line)
        }
    }

    // --- icon / name resolution ------------------------------------------
    function _entry(appId) {
        if (!appId)
            return null
        try {
            return DesktopEntries.heuristicLookup(appId)
        } catch (e) {
            return null
        }
    }
    function _iconFor(appId) {
        const e = _entry(appId)
        const name = (e && e.icon) ? e.icon : appId
        if (!name)
            return ""
        return Quickshell.iconPath(name, "application-x-executable")
    }
    implicitWidth: winRow.implicitWidth
    implicitHeight: parent ? parent.height : 28

    Row {
        id: winRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Repeater {
            model: root.shownWindows

            delegate: Rectangle {
                id: pill

                property bool focused: modelData.focused
                property bool hovered: winMa.containsMouse

                height: 24
                width: 26
                radius: 7
                color: focused
                    ? Qt.alpha(root.theme.accent || "#89b4fa", 0.18)
                    : hovered
                        ? Qt.alpha(root.theme.dim || "#45475a", 0.4)
                        : "transparent"

                Behavior on color { ColorAnimation { duration: 120 } }

                IconImage {
                    id: winIcon
                    anchors.centerIn: parent
                    implicitSize: 16
                    opacity: pill.focused ? 1.0 : (pill.hovered ? 0.95 : 0.75)
                    source: root._iconFor(modelData.appId)

                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                MouseArea {
                    id: winMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(
                        ["niri", "msg", "action", "focus-window", "--id", String(modelData.id)])
                }
            }
        }
    }
}

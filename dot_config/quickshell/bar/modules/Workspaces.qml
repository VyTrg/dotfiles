import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    property var theme: ({})
    property var settings: null

    // Output (monitor) this bar lives on. Empty => follow the focused output.
    property string screenName: ""

    readonly property string workspaceStyle: settings?.workspaceStyle || "og"
    readonly property var roman: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]

    // niri workspace state, kept in sync from the event stream.
    property var workspaces: []

    readonly property string focusedOutput: {
        for (let i = 0; i < workspaces.length; i++)
            if (workspaces[i].is_focused)
                return workspaces[i].output
        return screenName
    }
    readonly property string shownOutput: screenName !== "" ? screenName : focusedOutput

    // Workspace object occupying slot `idx` on the shown output, or null.
    function wsAt(idx) {
        for (let i = 0; i < workspaces.length; i++) {
            const w = workspaces[i]
            if (w.output === shownOutput && w.idx === idx)
                return w
        }
        return null
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
            root.workspaces = ev.WorkspacesChanged.workspaces.map(w => ({
                id:         w.id,
                idx:        w.idx,
                output:     w.output,
                is_active:  w.is_active,
                is_focused: w.is_focused,
                occupied:   w.active_window_id !== null
            }))
        } else if (ev.WorkspaceActivated) {
            const id = ev.WorkspaceActivated.id
            const focused = ev.WorkspaceActivated.focused
            const arr = root.workspaces.slice()
            let out = null
            for (let i = 0; i < arr.length; i++)
                if (arr[i].id === id)
                    out = arr[i].output
            for (let i = 0; i < arr.length; i++) {
                const w = arr[i]
                if (w.output === out)
                    w.is_active = (w.id === id)
                if (focused)
                    w.is_focused = (w.id === id)
            }
            root.workspaces = arr
        } else if (ev.WorkspaceActiveWindowChanged) {
            const wid = ev.WorkspaceActiveWindowChanged.workspace_id
            const awid = ev.WorkspaceActiveWindowChanged.active_window_id
            const arr = root.workspaces.slice()
            for (let i = 0; i < arr.length; i++)
                if (arr[i].id === wid)
                    arr[i].occupied = (awid !== null)
            root.workspaces = arr
        }
    }

    Process {
        id: niriEvents
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: line => root.handleEvent(line)
        }
    }

    implicitWidth: workspaceRow.implicitWidth
    implicitHeight: workspaceStyle === "strip" ? 17 : workspaceRow.implicitHeight

    Row {
        id: workspaceRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.workspaceStyle === "pulse" ? 5 : root.workspaceStyle === "strip" ? 7 : 0

        Repeater {
            model: 4

            delegate: Item {
                id: ws

                property int wsId: index + 1
                property bool occupied: { const w = root.wsAt(wsId); return w ? w.occupied : false }
                property bool active: { const w = root.wsAt(wsId); return w ? w.is_active : false }
                property bool hovered: mouseArea.containsMouse
                property bool pressed: mouseArea.pressed

                readonly property bool styleOg: root.workspaceStyle === "og"
                readonly property bool styleStrip: root.workspaceStyle === "strip"
                readonly property bool stylePulse: root.workspaceStyle === "pulse"
                readonly property string label: styleOg ? root.roman[index] : String(wsId)

                implicitWidth: styleOg
                    ? (active ? Math.max(labelText.implicitWidth + 14, 24) : 18)
                    : styleStrip
                        ? (active ? 11 : 13)
                        : (active ? 20 : occupied ? 12 : 10)
                implicitHeight: styleOg ? 28 : styleStrip ? 15 : 18

                Behavior on implicitWidth {
                    SmoothedAnimation { velocity: 360; easing.type: Easing.OutCubic }
                }

                transform: Scale {
                    origin.x: ws.width / 2
                    origin.y: ws.height / 2
                    xScale: ws.pressed ? 0.86 : 1.0
                    yScale: ws.pressed ? 0.86 : 1.0

                    Behavior on xScale { NumberAnimation { duration: 60; easing.type: Easing.OutCubic } }
                    Behavior on yScale { NumberAnimation { duration: 60; easing.type: Easing.OutCubic } }
                }

                Rectangle {
                    id: stripActiveBlock
                    visible: ws.styleStrip
                    anchors.centerIn: parent
                    width: ws.active ? 8 : 0
                    height: ws.active ? 8 : 0
                    radius: 2
                    color: root.theme.fg || "#cdd6f4"
                    opacity: ws.active ? 1 : 0

                    Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 80 } }
                    Behavior on color { ColorAnimation { duration: 90 } }
                }

                Rectangle {
                    id: pulseDot
                    visible: ws.stylePulse
                    anchors.centerIn: parent
                    width: ws.active ? 20 : ws.occupied ? 8 : 7
                    height: 7
                    radius: 99
                    color: ws.active
                        ? (root.theme.accent || "#89b4fa")
                        : ws.hovered
                            ? Qt.alpha(root.theme.fg || "#cdd6f4", 0.72)
                            : ws.occupied
                                ? Qt.alpha(root.theme.fg || "#cdd6f4", 0.42)
                                : Qt.alpha(root.theme.muted || "#585b70", 0.42)
                    opacity: visible ? 1 : 0.8

                    Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 110; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 90 } }
                }

                Rectangle {
                    id: pulseGlow
                    visible: ws.stylePulse && ws.active
                    anchors.centerIn: pulseDot
                    width: pulseDot.width + 8
                    height: pulseDot.height + 8
                    radius: 99
                    color: Qt.alpha(root.theme.accent || "#89b4fa", 0.12)
                    opacity: ws.active ? 1 : 0
                    z: -1

                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 110 } }
                }

                Text {
                    id: labelText
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: ws.styleOg ? -1 : 0
                    visible: !ws.stylePulse && !(ws.styleStrip && ws.active)
                    text: ws.label
                    color: ws.styleOg
                        ? (ws.active
                            ? (root.theme.accent || "#798186")
                            : ws.hovered
                                ? (root.theme.fg || "#cacccc")
                                : ws.occupied
                                    ? (root.theme.fg || "#cacccc")
                                    : (root.theme.muted || "#2a2e30"))
                        : (ws.hovered
                            ? Qt.alpha(root.theme.fg || "#cdd6f4", 0.82)
                            : ws.occupied
                                ? Qt.alpha(root.theme.fg || "#cdd6f4", 0.74)
                                : Qt.alpha(root.theme.muted || "#585b70", 0.56))
                    opacity: ws.pressed ? 0.6 : 1.0
                    font.pixelSize: ws.styleOg ? (ws.active || ws.hovered ? 11 : 10) : ws.styleStrip ? 9 : 0
                    font.family: "JetBrains Mono"
                    font.weight: ws.active || ws.hovered ? Font.DemiBold : Font.Medium

                    Behavior on color { ColorAnimation { duration: 100 } }
                    Behavior on opacity { NumberAnimation { duration: 60 } }
                    Behavior on font.pixelSize { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                }

                Rectangle {
                    id: ogUnderline
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    visible: ws.styleOg
                    width: (ws.active || ws.hovered) ? labelText.implicitWidth + 4 : 0
                    height: 1.5
                    radius: 99
                    opacity: ws.active ? 1.0 : 0.4
                    color: root.theme.accent || "#798186"

                    Behavior on width { SmoothedAnimation { velocity: 180; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(ws.wsId)])
                }
            }
        }
    }
}

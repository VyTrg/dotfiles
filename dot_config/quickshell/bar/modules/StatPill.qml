import QtQuick

Item {
    property string label:      ""
    property real   value:      0
    property color  accent:     "#89b4fa"
    property color  trackColor: "#45475a"
    property color  textColor:  "#cdd6f4"

    implicitWidth:  row.implicitWidth
    implicitHeight: 28

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:           label
            color:          textColor
            font.pixelSize: 10
            font.family:    "JetBrains Mono"
            opacity:        0.5
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:           Math.round(value) + "%"
            color:          accent
            font.pixelSize: 10
            font.family:    "JetBrains Mono"

            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }
}

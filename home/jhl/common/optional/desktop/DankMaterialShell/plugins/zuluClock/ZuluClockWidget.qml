import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// Replaces the built-in "clock" bar widget, whose time part is hard-coded
// to HH:mm local. Renders "1517z 0017j • Sat 24 Oct 26":
// UTC (z = Zulu), local (j = Juliett), then the local date.
PluginComponent {
    id: root

    layerNamespacePlugin: "zulu-clock"

    // Same click target as the built-in clock: the dash overview (calendar).
    pillClickAction: () => Quickshell.execDetached(["dms", "ipc", "call", "dash", "toggle", "overview"])

    readonly property var now: systemClock.date
    readonly property var dateLocale: Qt.locale("en_US")
    readonly property real fontSize: Theme.barTextSize(barThickness, barConfig?.fontScale, barConfig?.maximizeWidgetText)

    function pad2(n) {
        return String(n).padStart(2, "0");
    }

    readonly property string zuluStr: now ? pad2(now.getUTCHours()) + pad2(now.getUTCMinutes()) + "z" : ""
    readonly property string localStr: now ? pad2(now.getHours()) + pad2(now.getMinutes()) + "j" : ""
    readonly property string dateStr: now ? now.toLocaleDateString(dateLocale, "ddd dd MMM yy") : ""

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.zuluStr + " " + root.localStr
                font.pixelSize: root.fontSize
                color: Theme.widgetTextColor
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "•"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.outlineButton
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.dateStr
                font.pixelSize: root.fontSize
                color: Theme.widgetTextColor
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 0

            Repeater {
                model: [root.zuluStr, root.localStr]

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData
                    font.pixelSize: root.fontSize
                    color: Theme.widgetTextColor
                }
            }
        }
    }
}

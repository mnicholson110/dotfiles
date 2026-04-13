import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets
import "../components" as Components

PanelWindow {
    id: root

    Components.Theme {
        id: theme
    }

    required property QtObject shell

    readonly property int stackWidth: 392
    readonly property int stackSpacing: 10
    property var visibleNotifications: []
    signal notificationRefreshed(var notification)

    function rawIconSource(notification): string {
        if (!notification)
            return "";

        const hints = notification.hints || {};
        return String(notification.image || notification.appIcon || hints["image-path"] || hints["image_path"] || "");
    }

    function normalizedSource(source: string): url {
        source = String(source || "");
        if (!source)
            return "";

        if (source.startsWith("image://") || source.startsWith("file:"))
            return source;

        if (source.startsWith("/"))
            return `file://${source}`;

        return source;
    }

    function themeIconSource(notification): url {
        let icon = root.rawIconSource(notification);
        const aliases = {
            "audio-volume-high": "audio-volume-high",
            "audio-volume-medium": "audio-volume-medium",
            "audio-volume-low": "audio-volume-low",
            "audio-volume-muted": "audio-volume-muted",
            "notification": "dialog-information",
            "dialog-information-symbolic": "dialog-information",
            "dialog-warning-symbolic": "dialog-warning",
            "dialog-error-symbolic": "dialog-error"
        };

        if (!icon)
            return Quickshell.iconPath("dialog-information", "application-x-executable");

        if (icon.includes("?"))
            icon = icon.split("?")[0];

        if (icon.startsWith("image://icon/"))
            icon = icon.slice("image://icon/".length);

        if (icon.startsWith("image://") || icon.startsWith("file:") || icon.startsWith("/"))
            return "";

        if (aliases[icon])
            icon = aliases[icon];

        if (icon.endsWith("-symbolic"))
            icon = icon.slice(0, -9);

        const resolved = Quickshell.iconPath(icon, "dialog-information");
        if (resolved)
            return resolved;

        return Quickshell.iconPath("dialog-information", "application-x-executable");
    }

    function rasterIconSource(notification): url {
        const source = String(root.normalizedSource(root.rawIconSource(notification)));
        if (!source)
            return "";

        if (source.startsWith("file://"))
            return source;

        if (source.startsWith("image://") && !source.startsWith("image://icon/"))
            return source;

        return "";
    }

    function fallbackGlyph(notification): string {
        const icon = root.rawIconSource(notification);

        if (icon.includes("audio-volume-muted"))
            return "󰖁";
        if (icon.includes("audio-volume-low"))
            return "󰕿";
        if (icon.includes("audio-volume-medium"))
            return "󰖀";
        if (icon.includes("audio-volume-high"))
            return "󰕾";
        if (icon.includes("dialog-warning"))
            return "";
        if (icon.includes("dialog-error"))
            return "󰅚";
        if (icon.includes("dialog-information"))
            return "";
        if (notification.appName && notification.appName.length > 0)
            return notification.appName[0].toUpperCase();

        return "";
    }

    function progressValue(notification): int {
        if (!notification || !notification.hints)
            return -1;

        const value = Number(notification.hints.value);
        if (isNaN(value))
            return -1;

        return Math.max(0, Math.min(100, Math.round(value)));
    }

    function displayAppName(notification): string {
        if (!notification)
            return "";

        if (notification.appName === "changeVolume")
            return "";

        return notification.appName || "";
    }

    function timeoutMs(notification): int {
        if (!notification)
            return 0;

        if (notification.resident || notification.urgency === NotificationUrgency.Critical)
            return 0;

        if (notification.expireTimeout > 0) {
            // Quickshell docs say seconds, but in this build/system notify-send timeouts
            // are arriving as millisecond-sized values. Accept both shapes.
            if (notification.expireTimeout > 50)
                return Math.round(notification.expireTimeout);
            return Math.round(notification.expireTimeout * 1000);
        }

        if (notification.appName === "changeVolume")
            return 1400;

        return 5000;
    }

    function addNotification(notification): void {
        if (!notification)
            return;

        const existingIndex = root.visibleNotifications.findIndex(candidate => candidate === notification);
        if (existingIndex >= 0) {
            root.notificationRefreshed(notification);
            return;
        }

        if (notification.appName && notification.appName !== "") {
            const sameAppIndex = root.visibleNotifications.findIndex(candidate => candidate && candidate.appName === notification.appName);
            if (sameAppIndex >= 0) {
                const existing = root.visibleNotifications[sameAppIndex];
                const updated = root.visibleNotifications.slice();
                updated[sameAppIndex] = notification;
                root.visibleNotifications = updated;

                if (existing && existing !== notification && existing.tracked)
                    existing.tracked = false;

                root.notificationRefreshed(notification);
                return;
            }
        }

        root.visibleNotifications = [notification, ...root.visibleNotifications];
        root.notificationRefreshed(notification);
    }

    function removeVisibleNotification(notification): void {
        if (!notification)
            return;

        const existingIndex = root.visibleNotifications.findIndex(candidate => candidate === notification);
        if (existingIndex < 0)
            return;

        root.visibleNotifications = root.visibleNotifications.filter(candidate => candidate !== notification);
    }

    anchors {
        top: true
        right: true
    }
    margins.top: shell.barHeight + 12
    margins.right: 14

    color: "transparent"
    visible: root.visibleNotifications.length > 0
    implicitWidth: stackWidth
    implicitHeight: notificationColumn.implicitHeight

    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    NotificationServer {
        id: notificationServer

        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;
            root.addNotification(notification);
        }
    }

    Item {
        anchors.fill: parent

        Column {
            id: notificationColumn

            width: root.stackWidth
            spacing: root.stackSpacing

            Repeater {
                model: root.visibleNotifications

                delegate: Rectangle {
                    id: card

                    required property var modelData

                    readonly property var notification: modelData
                    readonly property int progress: root.progressValue(notification)
                    readonly property string appLabel: root.displayAppName(notification)
                    readonly property string summaryText: notification ? (notification.summary || notification.appName || "Notification") : "Notification"
                    readonly property string bodyText: notification ? (notification.body || "") : ""
                    readonly property var actionList: notification ? notification.actions : []
                    readonly property int dismissMs: root.timeoutMs(notification)
                    property bool entered: false
                    property bool closing: !notification || !notification.tracked

                    function startClose(untrack: bool): void {
                        if (closing)
                            return;

                        closing = true;
                        dismissTimer.stop();

                        if (untrack && notification && notification.tracked)
                            notification.tracked = false;

                        cleanupTimer.start();
                    }

                    width: notificationColumn.width
                    height: closing ? 0 : (contentColumn.implicitHeight + 28)
                    implicitHeight: height
                    radius: theme.radius
                    color: theme.surface
                    border.color: theme.borderStrong
                    border.width: 1
                    clip: true
                    opacity: entered && !closing ? 1 : 0
                    y: entered && !closing ? 0 : -10

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on y {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }

                    Component.onCompleted: {
                        entered = true;
                        if (dismissTimer.interval > 0)
                            dismissTimer.start();
                    }

                    Timer {
                        id: dismissTimer

                        interval: card.dismissMs
                        running: false
                        repeat: false
                        onTriggered: card.startClose(true)
                    }

                    Timer {
                        id: cleanupTimer

                        interval: 170
                        running: false
                        repeat: false
                        onTriggered: root.removeVisibleNotification(card.notification)
                    }

                    Connections {
                        target: card.notification

                        function onClosed(): void {
                            card.startClose(false);
                            root.removeVisibleNotification(card.notification);
                        }

                        function onSummaryChanged(): void {
                            if (!card.closing && dismissTimer.interval > 0)
                                dismissTimer.restart();
                        }

                        function onBodyChanged(): void {
                            if (!card.closing && dismissTimer.interval > 0)
                                dismissTimer.restart();
                        }

                        function onHintsChanged(): void {
                            if (!card.closing && dismissTimer.interval > 0)
                                dismissTimer.restart();
                        }

                        function onExpireTimeoutChanged(): void {
                            if (!card.closing && dismissTimer.interval > 0)
                                dismissTimer.restart();
                        }

                        function onImageChanged(): void {
                            if (!card.closing && dismissTimer.interval > 0)
                                dismissTimer.restart();
                        }

                        function onAppIconChanged(): void {
                            if (!card.closing && dismissTimer.interval > 0)
                                dismissTimer.restart();
                        }
                    }

                    Connections {
                        target: root

                        function onNotificationRefreshed(notification): void {
                            if (!notification || notification !== card.notification)
                                return;

                            cleanupTimer.stop();
                            dismissTimer.stop();
                            card.closing = false;
                            card.entered = true;

                            if (dismissTimer.interval > 0)
                                dismissTimer.start();
                        }
                    }

                    Column {
                        id: contentColumn

                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Row {
                            width: parent.width
                            spacing: 12

                            Item {
                                id: iconSlot

                                width: 38
                                height: 38

                                Loader {
                                    anchors.fill: parent
                                    active: parent.visible
                                    sourceComponent: themedIcon
                                }
                            }

                            Column {
                                width: parent.width - dismissButton.width - iconSlot.width - 24
                                spacing: 4

                                Text {
                                    visible: card.appLabel !== ""
                                    width: parent.width
                                    text: card.appLabel
                                    color: theme.textFaint
                                    elide: Text.ElideRight
                                    font.family: "GoMono Nerd Font Mono"
                                    font.bold: true
                                    font.pixelSize: 11
                                }

                                Text {
                                    width: parent.width
                                    text: card.summaryText
                                    color: theme.text
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    font.family: "GoMono Nerd Font Mono"
                                    font.bold: true
                                    font.pixelSize: 14
                                }

                                Text {
                                    visible: card.bodyText !== ""
                                    width: parent.width
                                    text: card.bodyText
                                    textFormat: Text.PlainText
                                    color: theme.textMuted
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 6
                                    elide: Text.ElideRight
                                    font.family: "GoMono Nerd Font Mono"
                                    font.pixelSize: 12
                                }
                            }

                            Button {
                                id: dismissButton
                                width: 22
                                height: 22
                                text: "x"

                                background: Rectangle {
                                    radius: theme.radius
                                    color: parent.down ? theme.primaryContainer : (parent.hovered ? theme.surfaceStrong : "transparent")
                                    border.color: parent.hovered ? theme.borderStrong : "transparent"
                                    border.width: 1
                                }

                                contentItem: Text {
                                    text: parent.text
                                    color: theme.textMuted
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.family: "GoMono Nerd Font Mono"
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                onClicked: {
                                    card.startClose(true);
                                }
                            }
                        }

                        Rectangle {
                            visible: card.progress >= 0
                            width: parent.width
                            height: 8
                            radius: 4
                            color: theme.surfaceRaised
                            border.color: theme.border
                            border.width: 1

                            Rectangle {
                                width: Math.max(0, (parent.width - 2) * card.progress / 100)
                                height: parent.height - 2
                                anchors.left: parent.left
                                anchors.leftMargin: 1
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 3
                                color: theme.primaryStrong
                            }
                        }

                        Flow {
                            visible: card.actionList.length > 0
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: card.actionList

                                delegate: Button {
                                    required property var modelData

                                    text: modelData.text
                                    padding: 0
                                    width: Math.min(contentItem.implicitWidth + 18, parent.width)
                                    height: 28

                                    background: Rectangle {
                                        radius: theme.radius
                                        color: parent.down ? theme.primaryContainer : (parent.hovered ? theme.surfaceStrong : theme.surfaceRaised)
                                        border.color: theme.border
                                        border.width: 1
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        color: theme.text
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                        font.family: "GoMono Nerd Font Mono"
                                        font.bold: true
                                        font.pixelSize: 12
                                    }

                                    onClicked: modelData.invoke()
                                }
                            }
                        }
                    }

                    Component {
                        id: themedIcon

                        Rectangle {
                            radius: theme.radius
                            color: theme.surfaceRaised
                            border.color: theme.border
                            border.width: 1

                            Image {
                                id: rasterIcon

                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                                source: root.rasterIconSource(card.notification)
                                visible: source !== "" && status === Image.Ready
                            }

                            IconImage {
                                id: themeIcon

                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                asynchronous: true
                                source: root.themeIconSource(card.notification)
                                visible: !rasterIcon.visible && source !== "" && status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !rasterIcon.visible && !themeIcon.visible
                                text: root.fallbackGlyph(card.notification)
                                color: theme.text
                                font.family: "GoMono Nerd Font Mono"
                                font.pixelSize: 16
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../components" as Components

PanelWindow {
    id: root

    Components.Theme {
        id: theme
    }

    required property QtObject shell
    property real revealHeight: 0
    property bool suspendAutoClose: false
    property string displayedMenu: ""
    property var displayedTrayItem: null
    property string pendingMenu: ""
    property var pendingTrayItem: null

    function popupComponent(menu: string): Component {
        if (menu === "clock")
            return clockMenu;
        if (menu === "tray" && displayedTrayItem && displayedTrayItem.hasMenu)
            return trayMenu;
        return null;
    }

    function normalizedMenu(menu: string, trayItem: var): string {
        if (menu === "clock")
            return "clock";
        if (menu === "tray" && trayItem && trayItem.hasMenu)
            return "tray";
        return "";
    }

    function requestPopup(menu: string, trayItem: var): void {
        autoCloseTimer.stop();
        suspendAutoClose = true;
        const nextMenu = normalizedMenu(menu, trayItem);
        const switchingTray = nextMenu === "tray" && displayedMenu === "tray" && displayedTrayItem !== trayItem;
        const switchingMenu = displayedMenu !== "" && (displayedMenu !== nextMenu || switchingTray);

        pendingMenu = nextMenu;
        pendingTrayItem = trayItem;

        if (closeAnim.running)
            return;

        if (switchingMenu) {
            openAnim.stop();
            closeAnim.stop();
            closeAnim.from = root.revealHeight;
            closeAnim.start();
            return;
        }

        applyPendingPopup();
    }

    function applyPendingPopup(): void {
        autoCloseTimer.stop();
        displayedMenu = pendingMenu;
        displayedTrayItem = pendingTrayItem;
        pendingMenu = "";
        pendingTrayItem = null;

        const component = popupComponent(displayedMenu);
        popupLoader.active = false;
        popupLoader.sourceComponent = component;
        popupLoader.active = !!component;

        Qt.callLater(() => root.syncPopupHeight());
    }

    function syncPopupHeight(): void {
        const targetHeight = popupLoader.item ? popupLoader.item.implicitHeight : 0;

            if (targetHeight > 0) {
                closeAnim.stop();
                openAnim.stop();
                openAnim.from = root.revealHeight;
                openAnim.to = targetHeight;
            openAnim.start();
            } else {
                openAnim.stop();
                closeAnim.stop();
                closeAnim.from = root.revealHeight;
                closeAnim.start();
        }
    }

    function menuIconSource(icon: string): url {
        if (!icon)
            return "";

        if (icon.startsWith("image://") || icon.startsWith("file:") || icon.startsWith("/"))
            return icon;

        if (icon.includes("?"))
            icon = icon.split("?")[0];

        const aliases = {
            "bluetooth-disabled-symbolic": "bluetooth",
            "bluetooth-disconnected-symbolic": "bluetooth",
            "bluetooth-symbolic": "bluetooth",
            "application-exit-symbolic": "system-log-out",
            "help-about-symbolic": "dialog-information",
            "application-x-addon-symbolic": "applications-system",
            "document-properties-symbolic": "preferences-system",
            "document-open-recent-symbolic": "document-open-recent",
            "edit-find-symbolic": "edit-find"
        };

        if (aliases[icon])
            return Quickshell.iconPath(aliases[icon], "application-x-executable");

        if (icon.endsWith("-symbolic"))
            return Quickshell.iconPath(icon.slice(0, -9), "application-x-executable");

        return Quickshell.iconPath(icon, "application-x-executable");
    }

    anchors {
        top: true
        left: true
        right: true
    }
    margins.top: shell.barHeight - 1

    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    visible: true
    color: "transparent"
    implicitHeight: revealHeight

    Component.onCompleted: requestPopup(shell.barMenu, shell.activeTrayItem)

    Connections {
        target: shell

        function onBarMenuChanged(): void {
            root.requestPopup(shell.barMenu, shell.activeTrayItem);
        }

        function onActiveTrayItemChanged(): void {
            if (shell.barMenu === "tray")
                root.requestPopup(shell.barMenu, shell.activeTrayItem);
        }
    }

    NumberAnimation {
        id: openAnim

        target: root
        property: "revealHeight"
        duration: 155
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.38, 1.21, 0.22, 1, 1, 1]
        onStopped: root.suspendAutoClose = false
    }

    NumberAnimation {
        id: closeAnim

        target: root
        property: "revealHeight"
        to: 0
        duration: 120
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.05, 0, 0.1333, 0.06, 0.1667, 0.4, 0.2083, 0.82, 0.25, 1, 1, 1]
        onStopped: {
            if (root.pendingMenu || root.pendingTrayItem) {
                root.applyPendingPopup();
            } else {
                root.suspendAutoClose = false;
                root.displayedMenu = "";
                root.displayedTrayItem = null;
                popupLoader.active = false;
                popupLoader.sourceComponent = null;
            }
        }
    }

    Timer {
        id: autoCloseTimer

        interval: 320
        repeat: false
        onTriggered: shell.closeOverlays()
    }

    Item {
        anchors.fill: parent
        clip: true

        MouseArea {
            anchors.fill: parent
            enabled: root.revealHeight > 0
            onClicked: shell.closeOverlays()
        }

        Loader {
            id: popupLoader

            active: false
            onLoaded: root.syncPopupHeight()
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.left: root.displayedMenu === "tray" ? parent.left : undefined
            anchors.leftMargin: 0
            anchors.right: root.displayedMenu === "clock" ? parent.right : undefined
            anchors.rightMargin: 0
        }

        Connections {
            target: popupLoader.item
            ignoreUnknownSignals: true

            function onImplicitHeightChanged(): void {
                root.syncPopupHeight();
            }
        }

        HoverHandler {
            id: popupHover

            target: popupLoader.item
            enabled: root.revealHeight > 0 && popupLoader.item !== null

            onHoveredChanged: {
                if (hovered) {
                    autoCloseTimer.stop();
                } else if (root.displayedMenu !== "" && !root.suspendAutoClose) {
                    autoCloseTimer.restart();
                }
            }
        }
    }

    Component {
        id: trayMenu

        Rectangle {
            id: trayCard

            property var trayItem: null

            antialiasing: false
            color: theme.surface
            radius: theme.radius
            topLeftRadius: 0
            topRightRadius: 0
            border.color: theme.borderStrong
            border.width: 0
            implicitWidth: Math.max(260, stack.implicitWidth + 24)
            implicitHeight: stack.implicitHeight + 24

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.GeometryRenderer

                ShapePath {
                    strokeWidth: 1
                    strokeColor: theme.borderStrong
                    fillColor: "transparent"
                    capStyle: ShapePath.FlatCap
                    joinStyle: ShapePath.RoundJoin
                    startX: trayCard.width - 0.5
                    startY: 0

                    PathLine {
                        x: trayCard.width - 0.5
                        y: trayCard.height - trayCard.radius
                    }

                    PathArc {
                        x: trayCard.width - trayCard.radius
                        y: trayCard.height - 0.5
                        radiusX: trayCard.radius
                        radiusY: trayCard.radius
                    }

                    PathLine {
                        x: trayCard.radius
                        y: trayCard.height - 0.5
                    }

                    PathArc {
                        x: 0.5
                        y: trayCard.height - trayCard.radius
                        radiusX: trayCard.radius
                        radiusY: trayCard.radius
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
            }

            Component.onCompleted: {
                trayItem = root.displayedTrayItem;
                if (trayItem) {
                    stack.push(subMenuComponent.createObject(stack, {
                        handle: trayItem.menu,
                        depthIndex: 0,
                        showIcons: !(trayItem.id || "").toLowerCase().includes("blu")
                    }));
                }
            }

            StackView {
                id: stack

                anchors.fill: parent
                anchors.margins: 12
                implicitWidth: currentItem ? currentItem.implicitWidth : 0
                implicitHeight: currentItem ? currentItem.implicitHeight : 0
            }

            Component {
                id: subMenuComponent

                Item {
                    id: menuRoot

                    required property QsMenuHandle handle
                    required property int depthIndex
                    required property bool showIcons

                    implicitWidth: 236
                    implicitHeight: menuColumn.implicitHeight + (depthIndex > 0 ? backButton.implicitHeight + 8 : 0)

                    QsMenuOpener {
                        id: opener

                        menu: menuRoot.handle
                    }

                    Button {
                        id: backButton

                        visible: menuRoot.depthIndex > 0
                        text: "Back"

                        background: Rectangle {
                            radius: theme.radius
                            color: theme.surfaceRaised
                            border.color: theme.border
                            border.width: 1
                        }

                        contentItem: Text {
                            text: backButton.text
                            color: theme.text
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "GoMono Nerd Font Mono"
                            font.bold: true
                            font.pixelSize: 14
                        }

                        onClicked: stack.pop()
                    }

                    Column {
                        id: menuColumn

                        anchors.top: backButton.visible ? backButton.bottom : parent.top
                        anchors.topMargin: backButton.visible ? 8 : 0
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: opener.children

                            Rectangle {
                                id: menuItem

                                required property QsMenuEntry modelData

                                width: menuColumn.width
                                height: modelData.isSeparator ? 1 : 34
                                radius: theme.radius
                                color: modelData.isSeparator ? theme.border : (hoverArea.containsMouse ? theme.surfaceStrong : "transparent")
                                opacity: modelData.enabled ? 1 : 0.5

                                MouseArea {
                                    id: hoverArea

                                    anchors.fill: parent
                                    enabled: !menuItem.modelData.isSeparator && menuItem.modelData.enabled
                                    hoverEnabled: true

                                    onClicked: {
                                        if (menuItem.modelData.hasChildren) {
                                            stack.push(subMenuComponent.createObject(stack, {
                                                handle: menuItem.modelData,
                                                depthIndex: menuRoot.depthIndex + 1,
                                                showIcons: menuRoot.showIcons
                                            }));
                                        } else {
                                            menuItem.modelData.triggered();
                                            shell.closeOverlays();
                                        }
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8
                                    visible: !menuItem.modelData.isSeparator

                                    Loader {
                                        active: menuRoot.showIcons && !!menuItem.modelData.icon
                                        Layout.preferredWidth: active ? 16 : 0
                                        Layout.preferredHeight: active ? 16 : 0

                                        sourceComponent: IconImage {
                                            implicitSize: 16
                                            asynchronous: true
                                            source: root.menuIconSource(menuItem.modelData.icon)
                                        }
                                    }

                                    Text {
                                        text: menuItem.modelData.text
                                        color: theme.text
                                        elide: Text.ElideRight
                                        font.family: "GoMono Nerd Font Mono"
                                        font.pixelSize: 14
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        visible: menuItem.modelData.hasChildren
                                        text: ">"
                                        color: theme.textMuted
                                        font.family: "GoMono Nerd Font Mono"
                                        font.pixelSize: 14
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: clockMenu

        Rectangle {
            id: calendarCard

            property date currentDate: new Date()
            readonly property int currentMonth: currentDate.getMonth()
            readonly property int currentYear: currentDate.getFullYear()

            antialiasing: false
            width: 388
            height: 360
            implicitWidth: width
            implicitHeight: height
            color: theme.surface
            radius: theme.radius
            topLeftRadius: 0
            topRightRadius: 0
            border.color: theme.borderStrong
            border.width: 0

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.GeometryRenderer

                ShapePath {
                    strokeWidth: 1
                    strokeColor: theme.borderStrong
                    fillColor: "transparent"
                    capStyle: ShapePath.FlatCap
                    joinStyle: ShapePath.RoundJoin
                    startX: 1
                    startY: 0

                    PathLine {
                        x: 1
                        y: calendarCard.height - calendarCard.radius - 1
                    }

                    PathArc {
                        x: calendarCard.radius + 1
                        y: calendarCard.height - 1
                        radiusX: calendarCard.radius
                        radiusY: calendarCard.radius
                        direction: PathArc.Counterclockwise
                    }

                    PathLine {
                        x: calendarCard.width - calendarCard.radius - 1
                        y: calendarCard.height - 1
                    }

                    PathArc {
                        x: calendarCard.width - 1
                        y: calendarCard.height - calendarCard.radius - 1
                        radiusX: calendarCard.radius
                        radiusY: calendarCard.radius
                        direction: PathArc.Counterclockwise
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Button {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 38
                        text: "<"
                        onClicked: calendarCard.currentDate = new Date(calendarCard.currentYear, calendarCard.currentMonth - 1, 1)

                        background: Rectangle {
                            radius: theme.radius
                            color: parent.down ? theme.primaryContainer : (parent.hovered ? theme.surfaceStrong : theme.surfaceRaised)
                            border.color: parent.activeFocus ? theme.primaryStrong : theme.border
                            border.width: 1
                        }

                        contentItem: Text {
                            text: parent.text
                            color: theme.text
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "GoMono Nerd Font Mono"
                            font.bold: true
                            font.pixelSize: 16
                        }
                    }

                    Text {
                        text: Qt.locale().standaloneMonthName(calendarCard.currentMonth) + " " + calendarCard.currentYear
                        color: theme.text
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "GoMono Nerd Font Mono"
                        font.bold: true
                        font.pixelSize: 17
                        Layout.fillWidth: true
                    }

                    Button {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 38
                        text: ">"
                        onClicked: calendarCard.currentDate = new Date(calendarCard.currentYear, calendarCard.currentMonth + 1, 1)

                        background: Rectangle {
                            radius: theme.radius
                            color: parent.down ? theme.primaryContainer : (parent.hovered ? theme.surfaceStrong : theme.surfaceRaised)
                            border.color: parent.activeFocus ? theme.primaryStrong : theme.border
                            border.width: 1
                        }

                        contentItem: Text {
                            text: parent.text
                            color: theme.text
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "GoMono Nerd Font Mono"
                            font.bold: true
                            font.pixelSize: 16
                        }
                    }
                }

                DayOfWeekRow {
                    Layout.fillWidth: true
                    locale: Qt.locale()

                    delegate: Text {
                        required property var model
                        text: model.shortName
                        color: theme.textMuted
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "GoMono Nerd Font Mono"
                        font.bold: true
                        font.pixelSize: 13
                    }
                }

                MonthGrid {
                    id: monthGrid

                    month: calendarCard.currentMonth
                    year: calendarCard.currentYear
                    locale: Qt.locale()
                    spacing: 4
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    delegate: Rectangle {
                        required property var model

                        radius: width / 2
                        color: model.today ? theme.primaryStrong : "transparent"
                        border.color: model.today ? theme.primaryStrong : "transparent"
                        border.width: model.today ? 1 : 0

                        Text {
                            anchors.centerIn: parent
                            text: model.day
                            color: model.today ? theme.background : (model.month === monthGrid.month ? theme.text : theme.textFaint)
                            font.family: "GoMono Nerd Font Mono"
                            font.pixelSize: 14
                            font.bold: model.today
                        }
                    }
                }

                Text {
                    text: Qt.formatDateTime(new Date(), "dddd, MMMM d, yyyy")
                    color: theme.textMuted
                    font.family: "GoMono Nerd Font Mono"
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}

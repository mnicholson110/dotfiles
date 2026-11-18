import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components" as Components

PanelWindow {
    id: root

    Components.Theme {
        id: theme
    }

    required property QtObject shell
    screen: shell.barPopupScreen
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
        root.syncPopupHeight();
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

    anchors {
        bottom: true
        right: true
    }
    margins.bottom: shell.dockInset + shell.dockSize
    margins.right: shell.dockInset
    implicitWidth: popupLoader.item ? popupLoader.item.implicitWidth : 1

    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    visible: root.displayedMenu !== "" || root.pendingMenu !== "" || root.revealHeight > 0
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
            anchors.right: parent.right
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

            antialiasing: true
            color: theme.background
            radius: theme.radius
            border.color: theme.borderStrong
            border.width: 1
            implicitWidth: Math.max(260, stack.implicitWidth + 24)
            implicitHeight: stack.implicitHeight + 24

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
            }

            Component.onCompleted: {
                trayItem = root.displayedTrayItem;
                if (trayItem) {
                    stack.push(subMenuComponent.createObject(stack, {
                        handle: trayItem.menu,
                        depthIndex: 0
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
                            font.family: theme.fontFamily
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
                                                depthIndex: menuRoot.depthIndex + 1
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

                                    Text {
                                        text: menuItem.modelData.text
                                        color: theme.text
                                        elide: Text.ElideRight
                                        font.family: theme.fontFamily
                                        font.pixelSize: 14
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        visible: menuItem.modelData.hasChildren
                                        text: ">"
                                        color: theme.textMuted
                                        font.family: theme.fontFamily
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

            antialiasing: true
            width: 388
            height: 360
            implicitWidth: width
            implicitHeight: height
            color: theme.background
            radius: theme.radius
            border.color: theme.borderStrong
            border.width: 1

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
                            font.family: theme.fontFamily
                            font.bold: true
                            font.pixelSize: 16
                        }
                    }

                    Text {
                        text: Qt.locale().standaloneMonthName(calendarCard.currentMonth) + " " + calendarCard.currentYear
                        color: theme.text
                        horizontalAlignment: Text.AlignHCenter
                        font.family: theme.fontFamily
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
                            font.family: theme.fontFamily
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
                        font.family: theme.fontFamily
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
                            font.family: theme.fontFamily
                            font.pixelSize: 14
                            font.bold: model.today
                        }
                    }
                }

                Text {
                    text: Qt.formatDateTime(new Date(), "dddd, MMMM d, yyyy")
                    color: theme.textMuted
                    font.family: theme.fontFamily
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}

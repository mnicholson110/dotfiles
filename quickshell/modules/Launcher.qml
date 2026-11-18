import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../components" as Components

PanelWindow {
    id: root

    Components.Theme {
        id: theme
    }

    required property QtObject shell
    screen: shell.panelScreen
    property string searchText: ""
    implicitWidth: Math.min(540, screen.width - 40)
    implicitHeight: Math.min(396, screen.height - 40)
    visible: shell.launcherOpen
    color: "transparent"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    readonly property var visibleApps: {
        const apps = DesktopEntries.applications.values.filter(app => !shell.isHiddenApp(app));
        apps.sort((a, b) => {
            const weightDelta = shell.launcherHistoryWeight(b) - shell.launcherHistoryWeight(a);
            if (weightDelta !== 0)
                return weightDelta;

            return (a.name || a.id || "").localeCompare(b.name || b.id || "");
        });
        return apps;
    }
    readonly property var filteredApps: {
        const query = searchText.trim().toLowerCase();
        return query ? visibleApps.filter(app => root.matchesSearch(app, query)) : visibleApps;
    }
    readonly property bool commandMode: searchText.trim().length > 0 && filteredApps.length === 0

    function matchesSearch(app: DesktopEntry, query: string): bool {
        const haystack = [
            app.name || "",
            app.id || "",
            app.genericName || "",
            app.comment || "",
            app.execString || "",
            app.startupClass || "",
            app.categories ? app.categories.join(" ") : "",
            app.keywords ? app.keywords.join(" ") : ""
        ].join(" ").toLowerCase();

        return haystack.includes(query);
    }

    function launchCurrent(): void {
        if (appList.currentIndex >= 0 && appList.currentIndex < filteredApps.length) {
            shell.launchDesktopEntry(filteredApps[appList.currentIndex]);
            return;
        }

        const command = searchText.trim();
        if (command.length > 0) {
            shell.closeOverlays();
            shell.runShell(command);
        }
    }

    function resetSelection(): void {
        if (filteredApps.length === 0) {
            appList.currentIndex = -1;
            return;
        }

        appList.currentIndex = 0;
        appList.positionViewAtIndex(0, ListView.Beginning);
    }

    function moveSelection(delta: int): void {
        if (filteredApps.length === 0) {
            appList.currentIndex = -1;
            return;
        }

        const baseIndex = appList.currentIndex < 0 ? 0 : appList.currentIndex;
        const nextIndex = Math.max(0, Math.min(filteredApps.length - 1, baseIndex + delta));
        appList.currentIndex = nextIndex;
        appList.positionViewAtIndex(nextIndex, ListView.Contain);
    }

    onSearchTextChanged: {
        if (searchInput.text !== root.searchText)
            searchInput.text = root.searchText;
    }

    onFilteredAppsChanged: {
        if (shell.launcherOpen)
            resetSelection();
    }

    onVisibleChanged: if (visible) {
        searchInput.clear();
        resetSelection();
        searchInput.forceActiveFocus();
    }

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onCleared: shell.closeOverlays()
    }

    Rectangle {
        anchors.fill: parent
        color: theme.background
        radius: 20
        border.color: theme.borderStrong
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 12
            TextField {
                id: searchInput
                Layout.fillWidth: true
                focus: true
                placeholderText: "Search apps or type a command"
                color: theme.text
                placeholderTextColor: theme.textFaint
                selectionColor: theme.primary
                selectedTextColor: theme.background
                font.family: theme.fontFamily
                font.pixelSize: 21
                padding: 0
                selectByMouse: true
                background: Item {}
                onTextChanged: root.searchText = text
                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Escape:
                        shell.closeOverlays();
                        event.accepted = true;
                        return;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        root.launchCurrent();
                        event.accepted = true;
                        return;
                    case Qt.Key_Down:
                        root.moveSelection(1);
                        event.accepted = true;
                        return;
                    case Qt.Key_Up:
                        root.moveSelection(-1);
                        event.accepted = true;
                        return;
                    case Qt.Key_PageDown:
                        root.moveSelection(6);
                        event.accepted = true;
                        return;
                    case Qt.Key_PageUp:
                        root.moveSelection(-6);
                        event.accepted = true;
                        return;
                    default:
                        break;
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: theme.border }
            Text {
                visible: root.commandMode
                text: "Run as shell command"
                color: theme.primaryStrong
                font.family: theme.fontFamily
                font.pixelSize: 15
            }
            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.filteredApps
                boundsBehavior: Flickable.StopAtBounds
                delegate: Item {
                    id: result
                    required property DesktopEntry modelData
                    required property int index
                    readonly property bool selected: appList.currentIndex === index
                    width: ListView.view.width
                    height: 36
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: result.selected ? 18 : 0
                        color: theme.primary
                        Behavior on height { NumberAnimation { duration: 90 } }
                    }
                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        verticalAlignment: Text.AlignVCenter
                        text: result.modelData.name || result.modelData.id
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: result.selected ? theme.primaryStrong : theme.textMuted
                        font.family: theme.fontFamily
                        font.pixelSize: 15
                    }
                    TapHandler { onTapped: shell.launchDesktopEntry(result.modelData) }
                }
            }
        }
    }
}

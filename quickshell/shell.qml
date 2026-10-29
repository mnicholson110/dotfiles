//@ pragma IconTheme Papirus-Dark
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import "modules"

ShellRoot {
    id: root

    property bool launcherOpen: false
    property bool sessionOpen: false
    property bool launcherLoaded: false
    property bool sessionLoaded: false
    property string barMenu: ""
    property var activeTrayItem: null
    property int barHeight: 42
    property int barReserve: 42
    property string panelOutputName: "DP-2"
    property string secondaryPanelOutputName: "DP-1"
    readonly property var panelScreen: screenByName(panelOutputName)
    readonly property var barScreens: {
        const screens = [];

        for (const screen of Quickshell.screens) {
            if (screen.name === panelOutputName || screen.name === secondaryPanelOutputName)
                screens.push(screen);
        }

        if (screens.length > 0)
            return screens;

        return Quickshell.screens.length > 0 ? [Quickshell.screens[0]] : [];
    }
    property var barPopupScreen: panelScreen
    property string pendingOverlay: ""
    property string terminal: "kitty"
    property list<string> launcherHistoryIds: []
    property int launcherHistoryLimit: 10
    property string controllerBatteryText: ""
    property string controllerBatteryTooltip: ""
    property string deathadderBatteryText: ""
    property string deathadderBatteryTooltip: ""
    readonly property var glove80Device: {
        for (const device of Bluetooth.devices.values) {
            const name = `${device.name || ""} ${device.deviceName || ""}`.toLowerCase();
            if (name.includes("glove80"))
                return device;
        }

        return null;
    }
    readonly property string gloveBatteryText: {
        const device = glove80Device;
        if (!device || !device.connected || !device.batteryAvailable)
            return "";

        return `${Math.round(device.battery * 100)}%`;
    }
    readonly property string gloveBatteryTooltip: {
        const device = glove80Device;
        if (!device || !device.connected || !device.batteryAvailable)
            return "";

        return `${device.name || device.deviceName || "Glove80"}: ${gloveBatteryText}`;
    }
    readonly property string clockText: Qt.formatDateTime(shellClock.date, "ddd MM/dd/yyyy hh:mm AP")

    function screenByName(name: string): var {
        for (const screen of Quickshell.screens) {
            if (screen.name === name)
                return screen;
        }

        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function launcherEntryKey(entry: DesktopEntry): string {
        if (!entry)
            return "";

        return entry.id || entry.desktopFile || entry.name || "";
    }

    function applyLauncherHistory(raw: string): void {
        const entries = [];

        for (const line of raw.split(/\r?\n/)) {
            const id = line.trim();
            if (!id)
                continue;

            entries.push(id);
        }

        launcherHistoryIds = entries.slice(0, launcherHistoryLimit);
    }

    function rememberLauncherApp(entry: DesktopEntry): void {
        const id = launcherEntryKey(entry);
        if (!id)
            return;

        launcherHistoryIds = [id, ...launcherHistoryIds].slice(0, launcherHistoryLimit);
        launcherHistoryWriteProc.running = true;
    }

    function launcherHistoryWeight(entry: DesktopEntry): int {
        const id = launcherEntryKey(entry);
        if (!id)
            return 0;

        let weight = 0;
        for (let index = 0; index < launcherHistoryIds.length; index++) {
            if (launcherHistoryIds[index] === id)
                weight += launcherHistoryIds.length - index;
        }

        return weight;
    }

    function launcherHistoryRecentIndex(entry: DesktopEntry): int {
        const id = launcherEntryKey(entry);
        return id ? launcherHistoryIds.indexOf(id) : -1;
    }

    function isHiddenApp(entry: DesktopEntry): bool {
        if (!entry)
            return true;

        if (entry.noDisplay)
            return true;

        const desktopId = (entry.id || entry.desktopFile || "").toLowerCase();
        if (desktopId.startsWith("wine-extension-") || desktopId.includes("/wine-extension-"))
            return true;

        if (desktopId.startsWith("wine-protocol-") || desktopId.includes("/wine-protocol-"))
            return true;

        if (!entry.name && !entry.id)
            return true;

        return false;
    }

    function updateControllerBattery(raw: string): void {
        const trimmed = raw.trim();
        if (!trimmed) {
            controllerBatteryText = "";
            controllerBatteryTooltip = "";
            return;
        }

        try {
            const payload = JSON.parse(trimmed);
            controllerBatteryText = payload.text || "";
            controllerBatteryTooltip = payload.tooltip || "";
        } catch (_) {
            controllerBatteryText = trimmed;
            controllerBatteryTooltip = trimmed;
        }
    }

    function updateDeathadderBattery(raw: string): void {
        try {
            const payload = JSON.parse(raw);
            deathadderBatteryText = payload.text || "";
            deathadderBatteryTooltip = payload.tooltip || "";
        } catch (_) {
            deathadderBatteryText = "";
            deathadderBatteryTooltip = "";
        }
    }

    function setLauncherState(open: bool): void {
        if (open) {
            launcherUnloadTimer.stop();
            launcherLoaded = true;
        }

        launcherOpen = open;

        if (!open && launcherLoaded)
            launcherUnloadTimer.restart();
    }

    function setSessionState(open: bool): void {
        if (open) {
            sessionUnloadTimer.stop();
            sessionLoaded = true;
        }

        sessionOpen = open;

        if (!open && sessionLoaded)
            sessionUnloadTimer.restart();
    }

    function closeOverlays(): void {
        pendingOverlay = "";
        overlaySwitchTimer.stop();
        setLauncherState(false);
        setSessionState(false);
        barMenu = "";
        activeTrayItem = null;
    }

    function setMainOverlay(name: string): void {
        setLauncherState(name === "launcher");
        setSessionState(name === "session");
    }

    function switchMainOverlay(name: string, toggled: bool): void {
        barMenu = "";
        activeTrayItem = null;

        const currentName = launcherOpen ? "launcher" : (sessionOpen ? "session" : "");
        const closingOther = currentName !== "" && currentName !== name;

        if (toggled && currentName === name) {
            pendingOverlay = "";
            overlaySwitchTimer.stop();
            setMainOverlay("");
            return;
        }

        if (closingOther) {
            pendingOverlay = name;
            setMainOverlay("");
            overlaySwitchTimer.restart();
            return;
        }

        pendingOverlay = "";
        overlaySwitchTimer.stop();
        setMainOverlay(name);
    }

    function toggleLauncher(): void {
        switchMainOverlay("launcher", true);
    }

    function toggleSession(): void {
        switchMainOverlay("session", true);
    }

    function toggleClockMenu(targetScreen: var): void {
        pendingOverlay = "";
        overlaySwitchTimer.stop();
        setMainOverlay("");
        activeTrayItem = null;
        barPopupScreen = targetScreen || panelScreen;
        barMenu = barMenu === "clock" ? "" : "clock";
    }

    function toggleTrayMenu(item: var, targetScreen: var): void {
        pendingOverlay = "";
        overlaySwitchTimer.stop();
        setMainOverlay("");
        barPopupScreen = targetScreen || panelScreen;

        if (barMenu === "tray" && activeTrayItem === item) {
            barMenu = "";
            activeTrayItem = null;
            return;
        }

        activeTrayItem = item;
        barMenu = "tray";
    }

    function runShell(command: string): void {
        Quickshell.execDetached({
            command: ["uwsm", "app", "-S", "both", "--", "sh", "-c", command]
        });
    }

    function runDetached(command: var): void {
        Quickshell.execDetached({
            command: command
        });
    }

    function launchDesktopEntry(entry: DesktopEntry): void {
        if (!entry)
            return;

        rememberLauncherApp(entry);
        closeOverlays();

        if (entry.runInTerminal) {
            Quickshell.execDetached({
                command: ["uwsm", "app", "-S", "both", "--", terminal, "-e", ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        } else {
            Quickshell.execDetached({
                command: ["uwsm", "app", "-S", "both", "--", ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        }
    }

    SystemClock {
        id: shellClock

        precision: SystemClock.Minutes
    }

    Process {
        id: controllerBatteryProc

        command: ["/home/matt/.dotfiles/scripts/controller_bat"]
        stdout: StdioCollector {
            onStreamFinished: root.updateControllerBattery(this.text)
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: controllerBatteryProc.running = true
    }

    Process {
        id: deathadderBatteryProc

        command: ["timeout", "5s", "/home/matt/.dotfiles/scripts/deathadder_bat"]
        stdout: StdioCollector {
            onStreamFinished: root.updateDeathadderBattery(this.text)
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: deathadderBatteryProc.running = true
    }

    Variants {
        model: root.barScreens

        delegate: Component {
            Bar {
                required property var modelData

                shell: root
                panelScreen: modelData
            }
        }
    }

    LazyLoader {
        active: root.launcherLoaded

        component: Component {
            Launcher {
                shell: root
            }
        }
    }

    LazyLoader {
        active: root.sessionLoaded

        component: Component {
            SessionMenu {
                shell: root
            }
        }
    }

    BarPopups {
        shell: root
    }

    Notifications {
        shell: root
    }

    Timer {
        id: overlaySwitchTimer

        interval: 125
        repeat: false
        onTriggered: {
            if (root.pendingOverlay)
                root.setMainOverlay(root.pendingOverlay);
            root.pendingOverlay = "";
        }
    }

    Timer {
        id: launcherUnloadTimer

        interval: 180
        repeat: false
        onTriggered: {
            if (!root.launcherOpen)
                root.launcherLoaded = false;
        }
    }

    Timer {
        id: sessionUnloadTimer

        interval: 190
        repeat: false
        onTriggered: {
            if (!root.sessionOpen)
                root.sessionLoaded = false;
        }
    }

    Process {
        id: launcherHistoryLoadProc

        command: [
            "sh",
            "-c",
            "mkdir -p \"$HOME/.cache/quickshell\" && cat \"$HOME/.cache/quickshell/launcher-history\" 2>/dev/null || cat \"$HOME/.cache/quickshell/launcher-mru\" 2>/dev/null || true"
        ]
        stdout: StdioCollector {
            onStreamFinished: root.applyLauncherHistory(this.text)
        }
    }

    Process {
        id: launcherHistoryWriteProc

        command: [
            "sh",
            "-c",
            "mkdir -p \"$HOME/.cache/quickshell\" && printf '%s\\n' \"$@\" > \"$HOME/.cache/quickshell/launcher-history\"",
            "launcher-history",
            ...root.launcherHistoryIds
        ]
    }

    Component.onCompleted: launcherHistoryLoadProc.running = true

    Scope {
        IpcHandler {
            function batteryStatus(): string {
                return JSON.stringify({
                    ps5: root.controllerBatteryText,
                    glove80: root.gloveBatteryText,
                    deathadder: root.deathadderBatteryText
                });
            }

            function toggleLauncher(): void {
                root.toggleLauncher();
            }

            function showLauncher(): void {
                root.switchMainOverlay("launcher", false);
            }

            function hideLauncher(): void {
                root.setLauncherState(false);
            }

            function toggleSession(): void {
                root.toggleSession();
            }

            function showSession(): void {
                root.switchMainOverlay("session", false);
            }

            function hideSession(): void {
                root.setSessionState(false);
            }

            function closeAll(): void {
                root.closeOverlays();
            }

            target: "myshell"
        }
    }
}

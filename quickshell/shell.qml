//@ pragma IconTheme Papirus-Dark
import QtQuick
import Quickshell
import Quickshell.Io
import "modules"

ShellRoot {
    id: root

    property bool launcherOpen: false
    property bool sessionOpen: false
    property string barMenu: ""
    property var activeTrayItem: null
    property int barHeight: 36
    property int barReserve: 36
    property real centerPillWidthRatio: 0.28
    property string pendingOverlay: ""
    property string terminal: "kitty"
    property list<string> launcherHistoryIds: []
    property int launcherHistoryLimit: 10
    property list<string> launcherAllowedApps: [
        "com.google.Chrome.desktop",
        "google-chrome.desktop",
        "discord.desktop"
    ]

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

    function hasCategory(entry: DesktopEntry, category: string): bool {
        if (!entry || !entry.categories)
            return false;

        return entry.categories.indexOf(category) !== -1;
    }

    function isAllowedLauncherApp(entry: DesktopEntry): bool {
        if (!entry)
            return false;

        if (launcherAllowedApps.indexOf(entry.id) !== -1)
            return true;

        const name = (entry.name || "").toLowerCase();
        const startupClass = (entry.startupClass || "").toLowerCase();
        const execString = (entry.execString || "").toLowerCase();

        if (name === "discord" || startupClass === "discord" || execString.includes("discord"))
            return true;

        if (name === "google chrome" || startupClass === "google-chrome" || execString.includes("google-chrome"))
            return true;

        return false;
    }

    function isHiddenApp(entry: DesktopEntry): bool {
        if (!entry)
            return true;

        if (isAllowedLauncherApp(entry))
            return false;

        if (hasCategory(entry, "Game"))
            return false;

        if (entry.noDisplay)
            return true;

        return true;
    }

    function closeOverlays(): void {
        pendingOverlay = "";
        overlaySwitchTimer.stop();
        launcherOpen = false;
        sessionOpen = false;
        barMenu = "";
        activeTrayItem = null;
    }

    function setMainOverlay(name: string): void {
        launcherOpen = name === "launcher";
        sessionOpen = name === "session";
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

    function toggleClockMenu(): void {
        pendingOverlay = "";
        overlaySwitchTimer.stop();
        setMainOverlay("");
        activeTrayItem = null;
        barMenu = barMenu === "clock" ? "" : "clock";
    }

    function toggleTrayMenu(item: var): void {
        pendingOverlay = "";
        overlaySwitchTimer.stop();
        setMainOverlay("");

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
            command: ["sh", "-lc", command]
        });
    }

    function launchDesktopEntry(entry: DesktopEntry): void {
        if (!entry)
            return;

        rememberLauncherApp(entry);
        closeOverlays();

        if (entry.runInTerminal) {
            Quickshell.execDetached({
                command: [terminal, "-e", ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        } else {
            Quickshell.execDetached({
                command: entry.command,
                workingDirectory: entry.workingDirectory
            });
        }
    }

    Bar {
        shell: root
    }

    Launcher {
        shell: root
    }

    SessionMenu {
        shell: root
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

    Process {
        id: launcherHistoryLoadProc

        command: [
            "sh",
            "-lc",
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
            "-lc",
            "mkdir -p \"$HOME/.cache/quickshell\" && printf '%s\\n' \"$@\" > \"$HOME/.cache/quickshell/launcher-history\"",
            "launcher-history",
            ...root.launcherHistoryIds
        ]
    }

    Component.onCompleted: launcherHistoryLoadProc.running = true

    Scope {
        IpcHandler {
            function toggleLauncher(): void {
                root.toggleLauncher();
            }

            function showLauncher(): void {
                root.switchMainOverlay("launcher", false);
            }

            function hideLauncher(): void {
                root.launcherOpen = false;
            }

            function toggleSession(): void {
                root.toggleSession();
            }

            function showSession(): void {
                root.switchMainOverlay("session", false);
            }

            function hideSession(): void {
                root.sessionOpen = false;
            }

            function closeAll(): void {
                root.closeOverlays();
            }

            target: "myshell"
        }
    }
}

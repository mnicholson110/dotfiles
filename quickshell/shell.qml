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
    property list<string> launcherMruIds: []
    property int launcherMruLimit: 64
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

    function applyLauncherMru(raw: string): void {
        const seen = {};
        const entries = [];

        for (const line of raw.split(/\r?\n/)) {
            const id = line.trim();
            if (!id || seen[id])
                continue;

            seen[id] = true;
            entries.push(id);
        }

        launcherMruIds = entries.slice(0, launcherMruLimit);
    }

    function rememberLauncherApp(entry: DesktopEntry): void {
        const id = launcherEntryKey(entry);
        if (!id)
            return;

        const nextIds = launcherMruIds.filter(existingId => existingId !== id);
        nextIds.unshift(id);
        launcherMruIds = nextIds.slice(0, launcherMruLimit);
        launcherMruWriteProc.running = true;
    }

    function launcherMruRank(entry: DesktopEntry): int {
        const id = launcherEntryKey(entry);
        const index = id ? launcherMruIds.indexOf(id) : -1;
        return index >= 0 ? index : launcherMruIds.length + 1;
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
        id: launcherMruLoadProc

        command: [
            "sh",
            "-lc",
            "mkdir -p \"$HOME/.cache/quickshell\" && cat \"$HOME/.cache/quickshell/launcher-mru\" 2>/dev/null || true"
        ]
        stdout: StdioCollector {
            onStreamFinished: root.applyLauncherMru(this.text)
        }
    }

    Process {
        id: launcherMruWriteProc

        command: [
            "sh",
            "-lc",
            "mkdir -p \"$HOME/.cache/quickshell\" && printf '%s\\n' \"$@\" > \"$HOME/.cache/quickshell/launcher-mru\"",
            "launcher-mru",
            ...root.launcherMruIds
        ]
    }

    Component.onCompleted: launcherMruLoadProc.running = true

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

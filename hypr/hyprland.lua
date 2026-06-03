-- Hyprland 0.55+ Lua config.
-- Reference: https://wiki.hypr.land/Configuring/Start/

----------------
-- Monitors
----------------

hl.monitor({
  output = "DP-1",
  mode = "3840x2160@60",
  position = "0x-1440",
  scale = 1.5,
})

hl.monitor({
  output = "DP-2",
  mode = "2560x1440@144",
  position = "0x0",
  scale = 1,
})

hl.workspace_rule({ workspace = "1", monitor = "DP-2" })
hl.workspace_rule({ workspace = "2", monitor = "DP-1" })

----------------
-- Window rules
----------------

hl.window_rule({
  name = "inhibit-idle-on-fullscreen",
  match = { class = ".*" },
  idle_inhibit = "fullscreen",
})

hl.window_rule({
  match = { class = "google-chrome" },
  sync_fullscreen = false,
})

hl.window_rule({
  name = "reaper-query-dialog",
  match = {
    class = [[REAPER]],
    title = [[REAPER Query]],
    xwayland = true,
  },
  float = true,
  center = true,
  min_size = { 420, 140 },
  allows_input = true,
  focus_on_activate = true,
  no_initial_focus = false,
})

hl.window_rule({
  name = "wine-vst-float",
  match = {
    class = [[.*(wine|Wine).*]],
    xwayland = true,
  },
  float = true,
  center = true,
  allows_input = true,
  focus_on_activate = true,
  no_anim = true,
  no_blur = true,
  no_shadow = true,
  decorate = false,
  opaque = true,
  force_rgbx = true,
})

hl.window_rule({
  name = "guitar-pro-wine",
  match = {
    class = [[guitarpro\.exe]],
    xwayland = true,
  },
  float = true,
  allows_input = true,
  fullscreen_state = "0 0",
  suppress_event = "fullscreen maximize fullscreenoutput",
  focus_on_activate = true,
  no_initial_focus = false,
  no_anim = true,
  no_blur = true,
  no_shadow = true,
  decorate = false,
  opaque = true,
  force_rgbx = true,
})

hl.window_rule({
  name = "yabridge-menu-popups",
  match = {
    class = [[yabridge-host\.exe\.so]],
    xwayland = true,
  },
  float = true,
  allows_input = true,
  fullscreen_state = "0 0",
  stay_focused = true,
  suppress_event = "fullscreen maximize fullscreenoutput",
  focus_on_activate = true,
  no_initial_focus = false,
  no_anim = true,
  no_blur = true,
  no_shadow = true,
  decorate = false,
  opaque = true,
  force_rgbx = true,
})

----------------
-- Autostart
----------------

hl.on("hyprland.start", function()
  hl.exec_cmd("hypridle")
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd("steam -silent")
  hl.exec_cmd("blueman-applet")
  hl.exec_cmd("nm-applet")
  hl.exec_cmd("discord --start-minimized")
  --hl.exec_cmd(
  --  "google-chrome-stable --new-window --start-fullscreen --app=http://192.168.1.67:3337/",
  --  { workspace = "2 silent" }
  --)
end)

----------------
-- Environment
----------------

hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("XDG_SESSION_TYPE", "wayland")

----------------
-- Config
----------------

hl.config({
  input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model = "",
    kb_options = "",
    kb_rules = "",
    follow_mouse = 1,
    natural_scroll = true,
    sensitivity = 0,
    touchpad = {
      natural_scroll = true,
    },
  },

  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 0,
    layout = "dwindle",
  },

  dwindle = {
    preserve_split = true,
  },

  decoration = {
    rounding = 10,
    blur = {
      enabled = true,
      size = 3,
      passes = 1,
    },
    shadow = {
      enabled = true,
      range = 60,
      offset = { 1, 2 },
      render_power = 3,
      scale = 0.97,
      color = "rgba(1E202966)",
    },
  },

  animations = {
    enabled = true,
  },

  misc = {
    vrr = 0,
    disable_hyprland_logo = true,
  },
})

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

----------------
-- Keybindings
----------------

local mainMod = "ALT"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("qs ipc call myshell toggleSession"))
hl.bind(mainMod .. " + V", hl.dsp.window.float())
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("qs ipc call myshell toggleLauncher"))

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))

for i = 1, 9 do
  hl.bind(mainMod .. " + CTRL + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + TAB", hl.dsp.focus({ workspace = "e+1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("mouse:275", hl.dsp.no_op())
hl.bind("mouse:276", hl.dsp.no_op())

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

hl.bind(
  mainMod .. " + G",
  hl.dsp.exec_cmd([[mkdir -p ~/screenshots && grim -g "$(slurp)" ~/screenshots/screenshot_$(date +"%F-%H:%M").png]])
)

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.dotfiles/scripts/volume_control up"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.dotfiles/scripts/volume_control down"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("~/.dotfiles/scripts/volume_control mute"), { repeating = false })

local function sendKeyCombo(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
  end
end

local function remapSuperToControl(key)
  hl.bind("SUPER + " .. key, hl.dsp.no_op())
  hl.bind("SUPER + " .. key, sendKeyCombo("CONTROL", key), { release = true })
end

remapSuperToControl("C")
remapSuperToControl("V")
remapSuperToControl("X")
remapSuperToControl("A")

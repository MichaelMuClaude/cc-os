-- CC/OS: keyboard shortcuts and Hyprland tweaks.
--
-- install.sh adds one line to ~/.config/hypr/bindings.lua that loads this file, so
-- `git pull` in the cc-os repo updates the shortcuts in place and nothing is ever
-- appended to bindings.lua. It runs after Omarchy's defaults, so o.rebind replaces
-- a default and hl.unbind removes one. The README lists the resulting shortcuts.

local root = (os.getenv("HOME") or "") .. "/.local/share/cc-os"
local bin = root .. "/omarchy/bin"

-- Claude. Super+S shows / hides Claude Desktop; Super+Space only ever brings it up.
o.rebind("SUPER + S", "Claude", bin .. "/cc-os-claude-toggle")
o.rebind("SUPER + SPACE", "Claude Desktop", bin .. "/cc-os-claude-toggle --show")

-- Drop-down panels. Super+T is Omarchy's console (the scratchpad), which opens
-- Claude Code the first time; Super+Shift+T is a plain terminal on its own special
-- workspace. pcall keeps the rest of this file loading if the module ever fails.
local ok, err = pcall(dofile, root .. "/omarchy/hypr/cc-os-dropdown.lua")
if not ok then print("cc-os-dropdown: " .. tostring(err)) end
o.rebind("SUPER + T", "Claude Code console", hl.dsp.workspace.toggle_special("scratchpad"))
o.rebind("SUPER + SHIFT + T", "Terminal (drop-down)", hl.dsp.workspace.toggle_special("dropdown"))

-- Apps.
hl.unbind("SUPER + SHIFT + B")
o.rebind("SUPER + B", "Browser", bin .. "/cc-os-app-toggle browser microsoft-edge omarchy-launch-browser")
o.bind("SUPER + E", "File manager", { omarchy = "nautilus" })
hl.unbind("SUPER + SHIFT + F")
o.rebind("SUPER + O", "Apps", "omarchy-shell omarchy.dock apps")
o.rebind("SUPER + M", "Omarchy menu", { menu = "root" })
hl.unbind("SUPER + CTRL + L")
o.rebind("SUPER + L", "Lock system", "omarchy-system-lock")

-- Windows. Super+Return tiles every window (Claude included); press again to widen
-- the focused one. Super+F is full screen.
hl.unbind("SUPER + SHIFT + RETURN")
o.rebind("SUPER + RETURN", "Tile all / widen focused", bin .. "/cc-os-overview-toggle")
o.rebind("SUPER + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.unbind("SUPER + ALT + F")
hl.unbind("SUPER + ALT + T")
hl.unbind("SUPER + ALT + O")

-- Simple resize. Super+= grows the focused window as a whole, Super+- shrinks it;
-- Alt = a little, Ctrl = a lot. The per-edge Shift variants are removed.
for _, keys in ipairs({ "SUPER + SHIFT", "SUPER + SHIFT + ALT", "SUPER + CTRL + SHIFT" }) do
  hl.unbind(keys .. " + code:20")
  hl.unbind(keys .. " + code:21")
end
for mod, step in pairs({ ["SUPER"] = 100, ["SUPER + ALT"] = 25, ["SUPER + CTRL"] = 300 }) do
  o.rebind(mod .. " + code:21", "Grow window", hl.dsp.window.resize({ x = step, y = step, relative = true }))
  o.rebind(mod .. " + code:20", "Shrink window", hl.dsp.window.resize({ x = -step, y = -step, relative = true }))
end

-- Super+Tab switches windows like Alt+Tab; Alt+Tab switches workspaces. Neither has
-- a Shift+Tab variant.
o.rebind("SUPER + TAB", "Focus on next window", hl.dsp.window.cycle_next())
o.bind("SUPER + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())
o.rebind("ALT + TAB", "Next workspace", hl.dsp.focus({ workspace = "m+1" }))
hl.unbind("ALT + SHIFT + TAB")
hl.unbind("SUPER + SHIFT + TAB")

-- Input language: Ctrl+Space (Super+I is gone).
hl.unbind("SUPER + I")
hl.unbind("SUPER + SHIFT + I")
o.rebind("CTRL + SPACE", "Switch input language", "omarchy-input-method cycle")

-- Shortcuts CC/OS does without; ask Claude instead. Omarchy's preinstalled apps and
-- web apps, its widgets (notifications, reminders, clock, calendar, weather,
-- battery, activity, calculator), and the move-to-console keys.
for _, keys in ipairs({
  "SUPER + SHIFT + A", "SUPER + SHIFT + ALT + A", "SUPER + SHIFT + CTRL + A",
  "SUPER + SHIFT + E", "SUPER + SHIFT + ALT + E", "SUPER + SHIFT + C",
  "SUPER + SHIFT + G", "SUPER + SHIFT + ALT + G", "SUPER + SHIFT + CTRL + G",
  "SUPER + SHIFT + M", "SUPER + SHIFT + ALT + M", "SUPER + SHIFT + D",
  "SUPER + SHIFT + N", "SUPER + SHIFT + O", "SUPER + SHIFT + W",
  "SUPER + SHIFT + P", "SUPER + SHIFT + Y", "SUPER + SHIFT + X", "SUPER + SHIFT + ALT + X",
  "SUPER + SHIFT + ALT + S", "SUPER + SHIFT + SLASH",
  "SUPER + SHIFT + ALT + B", "SUPER + ALT + SHIFT + F",
  "SUPER + ALT + RETURN", "SUPER + CTRL + RETURN", "SUPER + ALT + K", "SUPER + CTRL + K",
  "SUPER + comma", "SUPER + SHIFT + comma", "SUPER + ALT + comma", "SUPER + SHIFT + ALT + comma",
  "SUPER + CTRL + comma",
  "SUPER + CTRL + R", "SUPER + CTRL + ALT + R", "SUPER + SHIFT + CTRL + R",
  "SUPER + CTRL + ALT + T", "SUPER + CTRL + ALT + E", "SUPER + CTRL + ALT + D",
  "SUPER + CTRL + ALT + W", "SUPER + CTRL + ALT + B",
  "SUPER + CTRL + Q", "SUPER + CTRL + T",
  "SUPER + grave", "SUPER + ALT + S", "SUPER + SHIFT + grave",
  "XF86Calculator",
}) do
  hl.unbind(keys)
end

-- Natural (inverse) touchpad scrolling.
hl.config({ input = { touchpad = { natural_scroll = true } } })

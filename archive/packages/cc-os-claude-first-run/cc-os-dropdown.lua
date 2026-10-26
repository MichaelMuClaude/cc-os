-- CC/OS: a drop-down terminal on Super+T, built the same way as Omarchy's Claude
-- Code console (default/hypr/qconsole.lua) but on its own special workspace, so
-- the two never share a panel. The terminal is started the first time it opens.
-- Dimming and the slide animation already apply to every special workspace.

local DROPDOWN = "special:dropdown"
local seed = "[workspace special:dropdown silent] xdg-terminal-exec --app-id=cc-os.dropdown"

-- Same panel as the console: the top half of the work area, centered, twice as
-- wide as it is tall while it holds a single tiled window.
local share = 0.5
local box = 2

local beside, below = nil, nil

local function cover(side, bottom)
  if beside == side and below == bottom then
    return false
  end
  beside, below = side, bottom

  hl.workspace_rule({
    workspace = DROPDOWN,
    gaps_in = 0,
    gaps_out = { top = 0, right = side, bottom = bottom, left = side },
    no_border = true,
    on_created_empty = seed,
  })

  return true
end

local function alone()
  local tiled = 0
  for _, window in ipairs(hl.get_workspace_windows(DROPDOWN)) do
    if not window.floating then
      tiled = tiled + 1
    end
  end
  return tiled <= 1
end

local function fit(monitor)
  if not monitor or not monitor.scale or monitor.scale <= 0 then
    return false
  end

  local width, height = monitor.width, monitor.height
  if monitor.transform % 2 == 1 then
    width, height = height, width
  end

  local reserved = monitor.reserved
  height = height / monitor.scale - reserved.top - reserved.bottom
  width = width / monitor.scale - reserved.left - reserved.right

  local tall = math.floor(height * share)
  local wide = width
  if alone() then
    wide = math.min(width, tall * box)
  end

  return cover(math.floor((width - wide) / 2), math.floor(height - tall))
end

local function dropdown_monitor()
  local ws = hl.get_workspace(DROPDOWN)
  local mon = ws and ws.visible and ws.monitor

  if mon and mon.scale and mon.scale > 0 then
    return mon
  end

  return hl.get_active_monitor()
end

local function refit(monitor)
  if fit(monitor or dropdown_monitor()) then
    hl.exec_scheduled_prop_refresh_immediately()
  end
end

cover(0, 0)
fit(dropdown_monitor())

hl.on("monitor.layout_changed", function()
  refit()
end)

hl.on("monitor.focused", function()
  refit()
end)

hl.on("workspace.special_active", function(ws, mon)
  if ws and ws.name == DROPDOWN then
    refit(mon)
  end
end)

hl.on("workspace.move_to_monitor", function(ws, mon)
  if ws and ws.name == DROPDOWN then
    refit(mon)
  end
end)

local function recount()
  local ws = hl.get_workspace(DROPDOWN)
  if ws and ws.visible then
    refit()
  end
end

hl.on("window.open", recount)
hl.on("window.destroy", recount)
hl.on("window.move_to_workspace", recount)
hl.on("window.update_rules", recount)

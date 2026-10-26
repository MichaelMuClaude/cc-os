// CC/OS shell helper. GNOME has no scriptable window API on Wayland, so the
// shortcuts call this extension over D-Bus (org.ccos.Shell, /org/ccos/Shell). The
// ubuntu/bin scripts are the callers; they launch an app themselves when a method
// answers "none" (no matching window), so nothing is spawned from inside the shell.
//
// Apps are matched by case-insensitive substrings of the window's class / app id.

import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const IFACE = `
<node>
  <interface name="org.ccos.Shell">
    <method name="ToggleApp">
      <arg type="s" direction="in" name="patterns"/>
      <arg type="b" direction="in" name="wide"/>
      <arg type="s" direction="out" name="result"/>
    </method>
    <method name="ShowApp">
      <arg type="s" direction="in" name="patterns"/>
      <arg type="b" direction="in" name="wide"/>
      <arg type="s" direction="out" name="result"/>
    </method>
    <method name="ToggleDropdown">
      <arg type="s" direction="in" name="patterns"/>
      <arg type="s" direction="out" name="result"/>
    </method>
    <method name="TileOrWiden">
      <arg type="s" direction="out" name="result"/>
    </method>
    <method name="Resize">
      <arg type="i" direction="in" name="step"/>
      <arg type="s" direction="out" name="result"/>
    </method>
    <method name="NextWorkspace">
      <arg type="s" direction="out" name="result"/>
    </method>
  </interface>
</node>`;

// Windows of these classes are the drop-down panels: always on top, on every
// workspace, and sized like Omarchy's: the top half of the work area, centred, twice
// as wide as it is tall.
const DROPDOWN_CLASSES = ['cc-os.console', 'cc-os.dropdown'];

// Meta.MaximizeFlags went away in GNOME 49; accept both shapes.
function maximize(win) {
    if (Meta.MaximizeFlags)
        win.maximize(Meta.MaximizeFlags.BOTH);
    else
        win.maximize();
}

function unmaximize(win) {
    if (Meta.MaximizeFlags)
        win.unmaximize(Meta.MaximizeFlags.BOTH);
    else
        win.unmaximize();
}

function isMaximized(win) {
    if (typeof win.is_maximized === 'function')
        return win.is_maximized();
    return win.maximized_horizontally && win.maximized_vertically;
}

function classesOf(win) {
    return [win.get_wm_class(), win.get_wm_class_instance(), win.get_gtk_application_id()]
        .filter(c => c).map(c => c.toLowerCase());
}

function matches(win, patterns) {
    const classes = classesOf(win);
    return patterns.some(p => classes.some(c => c.includes(p)));
}

function parsePatterns(text) {
    return text.split(',').map(p => p.trim().toLowerCase()).filter(p => p);
}

function normalWindows() {
    return global.get_window_actors()
        .map(actor => actor.meta_window)
        .filter(win => win.get_window_type() === Meta.WindowType.NORMAL);
}

function isDropdown(win) {
    return matches(win, DROPDOWN_CLASSES);
}

export default class CCOSShell extends Extension {
    enable() {
        this._dbus = Gio.DBusExportedObject.wrapJSObject(IFACE, this);
        this._dbus.export(Gio.DBus.session, '/org/ccos/Shell');
        this._nameId = Gio.bus_own_name_on_connection(
            Gio.DBus.session, 'org.ccos.Shell', Gio.BusNameOwnerFlags.NONE, null, null);

        // A drop-down terminal that has just opened is placed and shown straight away.
        this._mapId = global.window_manager.connect('map', (_wm, actor) => {
            const win = actor.meta_window;
            if (win && isDropdown(win))
                this._placeDropdown(win);
        });
    }

    disable() {
        if (this._mapId) {
            global.window_manager.disconnect(this._mapId);
            this._mapId = null;
        }
        if (this._nameId) {
            Gio.bus_unown_name(this._nameId);
            this._nameId = null;
        }
        if (this._dbus) {
            this._dbus.unexport();
            this._dbus = null;
        }
    }

    // Show / hide: any matching window in focus -> minimise them all; otherwise bring
    // them to this workspace and focus the first. "none" when no window matches.
    ToggleApp(patterns, wide) {
        const wins = this._find(patterns);
        if (wins.length === 0)
            return 'none';
        if (wins.some(w => w.has_focus() && !w.minimized)) {
            wins.forEach(w => w.minimize());
            return 'hidden';
        }
        this._bringHere(wins, wide);
        return 'shown';
    }

    ShowApp(patterns, wide) {
        const wins = this._find(patterns);
        if (wins.length === 0)
            return 'none';
        this._bringHere(wins, wide);
        return 'shown';
    }

    ToggleDropdown(patterns) {
        const wins = this._find(patterns);
        if (wins.length === 0)
            return 'none';
        const win = wins[0];
        if (win.has_focus() && !win.minimized) {
            win.minimize();
            return 'hidden';
        }
        this._placeDropdown(win);
        return 'shown';
    }

    // Omarchy's Super+Return: when the focused window is maximised or full screen, lay
    // every window out in a grid so they are all visible; otherwise maximise the
    // focused window ("widen").
    TileOrWiden() {
        const focus = global.display.get_focus_window();
        const wins = normalWindows().filter(w =>
            !w.minimized && !isDropdown(w) && w.located_on_workspace(
                global.workspace_manager.get_active_workspace()));
        if (wins.length === 0)
            return 'none';

        if (focus && (isMaximized(focus) || focus.is_fullscreen()) && wins.length > 1) {
            const area = focus.get_work_area_current_monitor();
            const cols = Math.ceil(Math.sqrt(wins.length));
            const rows = Math.ceil(wins.length / cols);
            const cellW = Math.floor(area.width / cols);
            const cellH = Math.floor(area.height / rows);
            wins.forEach((win, i) => {
                if (win.is_fullscreen())
                    win.unmake_fullscreen();
                if (isMaximized(win))
                    unmaximize(win);
                win.move_resize_frame(true, area.x + (i % cols) * cellW,
                    area.y + Math.floor(i / cols) * cellH, cellW, cellH);
            });
            return 'tiled';
        }
        if (focus) {
            maximize(focus);
            return 'widened';
        }
        return 'none';
    }

    // Grow or shrink the focused window by step pixels in both directions, keeping its
    // centre where it is.
    Resize(step) {
        const win = global.display.get_focus_window();
        if (!win || isDropdown(win))
            return 'none';
        if (win.is_fullscreen())
            win.unmake_fullscreen();
        if (isMaximized(win))
            unmaximize(win);
        const area = win.get_work_area_current_monitor();
        const rect = win.get_frame_rect();
        const width = Math.max(200, Math.min(area.width, rect.width + step));
        const height = Math.max(150, Math.min(area.height, rect.height + step));
        const x = Math.max(area.x, Math.min(area.x + area.width - width,
            rect.x - Math.round((width - rect.width) / 2)));
        const y = Math.max(area.y, Math.min(area.y + area.height - height,
            rect.y - Math.round((height - rect.height) / 2)));
        win.move_resize_frame(true, x, y, width, height);
        return 'resized';
    }

    NextWorkspace() {
        const manager = global.workspace_manager;
        const next = (manager.get_active_workspace_index() + 1) % manager.get_n_workspaces();
        manager.get_workspace_by_index(next).activate(global.get_current_time());
        return 'switched';
    }

    _find(patterns) {
        const list = parsePatterns(patterns);
        return normalWindows().filter(w => matches(w, list));
    }

    _bringHere(wins, wide) {
        const workspace = global.workspace_manager.get_active_workspace();
        wins.forEach(win => {
            if (!win.located_on_workspace(workspace))
                win.change_workspace(workspace);
            if (win.minimized)
                win.unminimize();
        });
        if (wide)
            maximize(wins[0]);
        Main.activateWindow(wins[0]);
    }

    _placeDropdown(win) {
        const area = win.get_work_area_current_monitor();
        const tall = Math.floor(area.height / 2);
        const wide = Math.min(area.width, tall * 2);
        win.stick();
        win.make_above();
        if (win.minimized)
            win.unminimize();
        if (isMaximized(win))
            unmaximize(win);
        win.move_resize_frame(true, area.x + Math.floor((area.width - wide) / 2), area.y, wide, tall);
        Main.activateWindow(win);
    }
}

// This file is part of retro-gtk. License: GPLv3

private class Retro.PositionParser : Object {
	private Gdk.Screen screen;

	private int x_last;
	private int y_last;

	/*
	 * Return wether a movement happened or not
	 */
	public bool parse_event (Gdk.EventMotion event, out int x_position, out int y_position) {
		var device = event.device;

		Gdk.Screen s;
		int x, y;
		device.get_position (out s, out x, out y);

		int x_width = s.get_width();
		int y_height = s.get_height();

		if (s != screen) {
			screen = s;
			x_position = x;
			y_position = y;
			x_last = x;
			y_last = y;

			return false;
		}

		screen = s;

		x_position = x - x_last;
		y_position = y - y_last;

		if (x_position == 0 && y_position == 0) return false;

		// Motion hapened: the pointer may be warped
		x_last = x;
		y_last = y;

		return true;
	}
}

public class Retro.Pointer : Object, InputDevice {
	public Gtk.Widget widget { get; construct; }

	private HashTable<uint?, bool?> button_state;
	private PositionParser parser;
	private int16 x_delta;
	private int16 y_delta;

	private ulong ungrab_id;

	public Pointer (Gtk.Widget widget) {
		Object (widget: widget);
	}

	construct {
		parser = new PositionParser ();

		widget.button_press_event.connect (on_button_press_event);
		widget.motion_notify_event.connect (on_motion_notify_event);

		// Ungrab on focus out event
		widget.focus_out_event.connect ((w, e) => {
			ungrab (0);
			return false;
		});

		// Ungrab on press of Escape
		widget.key_press_event.connect ((w, e) => {
			if (e.keyval == Gdk.Key.Escape && (bool) (e.state & Gdk.ModifierType.CONTROL_MASK))
				ungrab (e.time);
			return false;
		});

		widget.button_press_event.connect (on_button_press_event);

		widget.button_release_event.connect (on_button_release_event);

		button_state = new HashTable<uint?, bool?> (int_hash, int_equal);
	}

	public void poll () {}

	public int16 get_input_state (DeviceType device, uint index, uint id) {
		if (device != DeviceType.POINTER) return 0;

		switch ((PointerId) id) {
			case PointerId.X:
				int16 result = x_delta;
				x_delta = 0;
				//message("X coordinate : %d", result);
				return result;
			case PointerId.Y:
				int16 result = y_delta;
				y_delta = 0;
				//message("Y coordinate : %d", result);
				return result;
			case PointerId.PRESSED:
				//message("Returned button state from pointer: %u",get_button_state (1) ? 1: 0);
				return get_button_state (1) ? int16.MAX : 0;
			default:
				return 0;
		}
	}

	public DeviceType get_device_type () {
		return DeviceType.POINTER;
	}

	public uint64 get_device_capabilities () {
		return 1 << DeviceType.POINTER;
	}

	private bool on_button_press_event (Gtk.Widget source, Gdk.EventButton event) {
		/*if (!parse) {
			grab (event.device, event.window, event.time);
			return false;
		}*/

		message("on button press: %u",event.button);

		if (button_state.contains (event.button)) {
			//message("contains: %u",event.button);
			button_state.replace (event.button, true);
		}
		else  {
			//message("doesn't contain: %u",event.button);
			button_state.insert (event.button, true);
		}

		return false;
	}

	private bool on_button_release_event (Gtk.Widget source, Gdk.EventButton event) {
		message("on button release: %u",event.button);
		if (button_state.contains (event.button)) {
			button_state.replace (event.button, false);
		}

		return false;
	}

	/**
	 * Update the pointer's position
	 */
	private bool on_motion_notify_event (Gtk.Widget source, Gdk.EventMotion event) {
		//if (!parse) return false;


		int x, y;
		if (parser.parse_event (event, out x, out y)) {
			x_delta = (int16) x;
			y_delta = (int16) y;
			//message("X,Y coordinates : %d %d", x_delta,y_delta);
		}

		return false;
	}

	public bool get_button_state (uint button) {
		if (button_state.contains (button)) {
			return button_state.lookup (button);
		}

		return false;
	}

	/**
	 * Release the pointer
	 */
	private signal void ungrab (uint32 time);

	/**
	 * Grab the poiner
	 *//*
	private void grab (Gdk.Device device, Gdk.Window window, uint32 time) {
		// Save the pointer's position
		Gdk.Screen screen;
		int x, y;
		device.get_position (out screen, out x, out y);
		// Grab the device
		parse = true;
		var cursor = new Gdk.Cursor (Gdk.CursorType.BLANK_CURSOR);
		device.grab (window, Gdk.GrabOwnership.NONE, false, Gdk.EventMask.ALL_EVENTS_MASK, cursor, time);
		// Ungrab the device when asked
		ungrab_id = ungrab.connect ((time) => {
			if (parse) {
				parse = false;
				device.ungrab (time);
				// Restore the pointer's position
				device.warp (screen, x, y);
				disconnect (ungrab_id);
			}
		});
	}*/
}

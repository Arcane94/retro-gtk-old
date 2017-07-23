// This file is part of retro-gtk. License: GPL-3.0+.

public class Retro.Pointer : Object, InputDevice {
	public Gtk.Widget widget { get; construct; }

	private HashTable<uint?, bool?> button_state;
	private int16 pointer_x;
	private int16 pointer_y;

	public Pointer (Gtk.Widget widget) {
		Object (widget: widget);
	}

	construct {
		widget.button_press_event.connect (on_button_press_event);
		widget.button_release_event.connect (on_button_release_event);
		widget.motion_notify_event.connect (on_motion_notify_event);

		button_state = new HashTable<uint?, bool?> (int_hash, int_equal);
	}

	public void poll () {}

	public int16 get_input_state (DeviceType device, uint index, uint id) {
		if (device != DeviceType.POINTER)
			return 0;

		switch ((PointerId) id) {
			case PointerId.X:
				return pointer_x;
			case PointerId.Y:
				return pointer_y;
			case PointerId.PRESSED:
				return get_button_state (1) ? 1 : 0;
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

	private bool parse_position (Gtk.Widget source, double event_x, double event_y) {
		var w = source.get_allocated_width ();
		var h = source.get_allocated_height ();

		if (!((0 <= event_x <= w) && (0 <= event_y <= h)))
			return true;

		pointer_x = (int16) ((event_x * 2.0 - w) / w * int16.MAX);
		pointer_y = (int16) ((event_y * 2.0 - h) / h * int16.MAX);

		return false;
	}

	private bool on_button_press_event (Gtk.Widget source, Gdk.EventButton event) {
		if (parse_position (widget, event.x, event.y))
			return true;

		if (button_state.contains (event.button))
			button_state.replace (event.button, true);
		else
			button_state.insert (event.button, true);

		return false;
	}

	private bool on_button_release_event (Gtk.Widget source, Gdk.EventButton event) {
		if (button_state.contains (event.button))
			button_state.replace (event.button, false);

		return false;
	}

	private bool on_motion_notify_event (Gtk.Widget source, Gdk.EventMotion event) {
		return parse_position (widget, event.x, event.y);
	}

	public bool get_button_state (uint button) {
		if (button_state.contains (button))
			return button_state.lookup (button);

		return false;
	}
}


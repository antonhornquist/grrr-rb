require 'java'
require "#{File.expand_path(File.dirname(__FILE__))}/screen_grid_button"

#
# java.awt.Panel Extensions - add draw_hook function for behavior similar to SC Window/View classes
#
class JavaAWTPanelWithDrawHook < java.awt.Panel
	attr_accessor :draw_hook
	def paint(g); @draw_hook.call(g); end
end

class Grrr::ScreenGrid < Grrr::Controller
	DEFAULT_NUM_COLS = 8
	DEFAULT_NUM_ROWS = 8
	KEY_CONTROL_ENABLED_BY_DEFAULT = false
	BUTTON_SIZE = 25
	MARGIN = 10
	KEY_CONTROL_AREA_NUM_COLS = 8
	KEY_CONTROL_AREA_NUM_ROWS = 4
	KEY_CONTROL_AREA_BORDER_COLOR = java.awt.Color.black

	attr_reader :read_only
	attr_reader :key_control_enabled

	def initialize(num_cols=nil, num_rows=nil, view=nil, origin=nil, create_top_view_if_none_is_supplied=true, read_only=false)
		super(
			num_cols ? num_cols : DEFAULT_NUM_COLS,
			num_rows ? num_rows : (num_cols ? num_cols : DEFAULT_NUM_ROWS),
			view,
			origin,
			create_top_view_if_none_is_supplied
		)
		@current_key_control_area = 0
		@show_current_key_control_area = false
		@modifier_caps_is_on = false
		@modifier_shift_is_pressed = false
		@modifier_ctrl_is_pressed = false
		@modifier_alt_is_pressed = false

		@@keymaps = {
			:swedish => {
				:keys => [ 
					49, 50, 51, 52, 53, 54, 55, 56,
					81, 87, 69, 82, 84, 89, 85, 73,
					65, 83, 68, 70, 71, 72, 74, 75,
					90, 88, 67, 86, 66, 78, 77, 44
				],
				:arrow_key_left => 37,
				:arrow_key_right => 39,
				:arrow_key_down => 40,
				:arrow_key_up => 38,
				:backspace => 8
			}
		}
		Grrr::ScreenGrid.set_keymap(:swedish)

		@key_control_enabled = KEY_CONTROL_ENABLED_BY_DEFAULT
		@read_only = read_only

		@key_control_area_origins = Array.fill2d(
			(@num_cols.to_f / KEY_CONTROL_AREA_NUM_COLS).ceil,
			(@num_rows.to_f / KEY_CONTROL_AREA_NUM_ROWS).ceil
		) do |x, y|
			Grrr::Point.new(x * KEY_CONTROL_AREA_NUM_COLS, y * KEY_CONTROL_AREA_NUM_ROWS)
		end.flatten

		pr_create_window
		pr_configure_keyboard_actions

		front
		refresh
	end

	def self.new_detached(num_cols=nil, num_rows=nil)
		new(num_cols, num_rows, nil, nil, false)
	end

	def self.new_view(view, read_only=false)
		Grrr::ScreenGrid.new(view.num_cols, view.num_rows, view, Grrr::Point.new(0, 0), false, read_only)
	end

	def self.set_keymap(keymap_name)
		@@keymap_keys = @@keymaps[keymap_name][:keys]
		@@keymap_backspace = @@keymaps[keymap_name][:backspace]
		@@keymap_left = @@keymaps[keymap_name][:arrow_key_left]
		@@keymap_right = @@keymaps[keymap_name][:arrow_key_right]
		@@keymap_down = @@keymaps[keymap_name][:arrow_key_down]
		@@keymap_up = @@keymaps[keymap_name][:arrow_key_up]
	end

	def self.stroke_rect(g, x, y, width, height, pen_width, color)
		g.set_color(color)
		pen_width.times do |i|
			g.draw_rect(x+i, y+i, width-(i*2), height-(i*2))
		end
	end

	def cleanup
		release_all_screen_grid_buttons
		@frame.dispose if @frame.is_showing?
	end

	def info
		"ScreenGrid
==========
Press buttons with mouse, or enable key control with ctrl-backspace and use keyboard. Use shift to hold buttons. Use caps lock to hold and toggle buttons. If the grid is larger than key control area (#{KEY_CONTROL_AREA_NUM_COLS}x#{KEY_CONTROL_AREA_NUM_ROWS}) it is possible to switch between areas on the ScreenGrid using the arrow buttons. Also, as long as alt is key presses are redirected to next key control area."
	end

	def handle_view_button_state_changed_event(point, pressed)
		@buttons[point.x][point.y].pressed = pressed
	end

	def handle_view_led_refreshed_event(point, on)
		@buttons[point.x][point.y].lit = on
	end

	def front
		@frame.show
	end

	def always_on_top
		@frame.always_on_top
	end

	def always_on_top=(always_on_top)
		@frame.always_on_top=always_on_top
	end

	def toggle_key_control
		if @key_control_enabled
			disable_key_control
		else
			enable_key_control
			flash_key_control_area
		end
	end

	def enable_key_control
		@key_control_enabled = true
	end

	def disable_key_control
		hide_key_control_area
		@key_control_enabled = true
	end

	def release_all_screen_grid_buttons_within_key_control_area_bounds_unless_hold_modifier(index)
		key_control_area_origin = @key_control_area_origins[index]

		if not hold_modifier
			release_all_screen_grid_buttons_within_bounds(
				key_control_area_origin,
				[KEY_CONTROL_AREA_NUM_COLS, @num_cols - key_control_area_origin.x].min,
				[KEY_CONTROL_AREA_NUM_ROWS, @num_rows - key_control_area_origin.y].min
			)
		end
	end

	def release_all_screen_grid_buttons_within_bounds(origin, num_cols, num_rows)
		Grrr::View.bounds_to_points(origin, num_cols, num_rows).each do |point|
			release_screen_grid_button(point.x, point.y)
		end
	end

	def release_all_screen_grid_buttons_unless_hold_modifier
		release_all_screen_grid_buttons unless hold_modifier
	end

	def release_all_screen_grid_buttons
		@num_cols.times do |x|
			@num_rows.times do |y|
				release_screen_grid_button(x, y)
			end
		end
	end

	def release_screen_grid_button(x, y)
		button = @buttons[x][y]
		button.value_action=(false) if button.is_pressed?
	end

	def handle_key_control_event(keycode, pressed)
		if keymap_keys_index = @@keymap_keys.index(keycode)
			handle_key_control_keymap_event(keymap_keys_index, pressed)
		elsif is_arrow_keycode?(keycode)
			handle_key_control_arrow_event(arrow_keycode_to_direction(keycode), pressed)
		end
	end

	def handle_key_control_arrow_event(direction, pressed)
		if @key_control_area_origins.size > 1 and pressed
			current_origin = @key_control_area_origins[@current_key_control_area]
			new_origin = case direction
				when :left
					@key_control_area_origins.detect { |p|
						p.x == current_origin.x - KEY_CONTROL_AREA_NUM_COLS and p.y == current_origin.y
					}
				when :right
					@key_control_area_origins.detect { |p|
						p.x == current_origin.x + KEY_CONTROL_AREA_NUM_COLS and p.y == current_origin.y
					}
				when :down
					@key_control_area_origins.detect { |p|
						p.x == current_origin.x and p.y == current_origin.y + KEY_CONTROL_AREA_NUM_ROWS
					}
				when :up
					@key_control_area_origins.detect { |p|
						p.x == current_origin.x and p.y == current_origin.y - KEY_CONTROL_AREA_NUM_ROWS
					}
				end

			if new_origin
				release_all_screen_grid_buttons_within_key_control_area_bounds_unless_hold_modifier(@current_key_control_area)
				@current_key_control_area = @key_control_area_origins.index(new_origin)
			end

			flash_key_control_area
		end
	end

	def handle_key_control_keymap_event(keymap_keys_index, pressed)
		if !(hold_modifier and not pressed) # Ignore key released if caps on or shift pressed
			key_control_area_for_this_key_event = @modifier_alt_is_pressed ? next_key_control_area : @current_key_control_area
			if button = lookup_screen_grid_button(key_control_area_for_this_key_event, keymap_keys_index)
				if @modifier_caps_is_on
					button.toggle_action
				else
					button.value_action=(pressed)
				end
			end
		end
	end

	def is_arrow_keycode?(keycode)
		[37, 38, 39, 40].include? keycode
	end

	def arrow_keycode_to_direction(keycode)
		case keycode
		when @@keymap_left then :left
		when @@keymap_right then :right
		when @@keymap_down then :down
		when @@keymap_up then :up
		end
	end

	def next_key_control_area
		(@current_key_control_area + 1) % @key_control_area_origins.size
	end

	def lookup_screen_grid_button(area_index, keymap_keys_index)
		point = @key_control_area_origins[area_index]+Grrr::Point.new(keymap_keys_index % KEY_CONTROL_AREA_NUM_COLS, keymap_keys_index / KEY_CONTROL_AREA_NUM_COLS)
		if contains_point?(point) then @buttons[point.x][point.y] end
	end

	def pr_create_window
		panel_width = @num_cols*BUTTON_SIZE + (@num_cols-1)*(BUTTON_SIZE*0.2) + 2*MARGIN
		panel_height = @num_rows*BUTTON_SIZE + (@num_rows-1)*(BUTTON_SIZE*0.2) + 2*MARGIN

		@frame = java.awt.Frame.new("#{@num_cols}x#{@num_rows} #{self.class}")

		@panel = JavaAWTPanelWithDrawHook.new
		@panel.set_layout(nil)
		@panel.set_size(panel_width, panel_height)
		@frame.add(@panel)
		@frame.set_resizable(false)

		@frame.add_window_listener java.awt.event.WindowListener.impl { |name, event|
			case name
			when :windowClosing
				remove unless is_removed?
				@frame.dispose
			end
		}
		@frame.pack

		frame_size = @frame.get_size
		screen_size = java.awt.Toolkit.get_default_toolkit.get_screen_size
		@frame.set_location( screen_size.width - frame_size.width - 100, screen_size.height - frame_size.height - 100 )

		@panel.draw_hook = lambda do |g|
			if @show_current_key_control_area
				current_origin = @key_control_area_origins[@current_key_control_area]

				origin_button = Grrr::Point.new(
					[current_origin.x, 0].max,
					[current_origin.y, 0].max
				)
				corner_button = Grrr::Point.new(
					[current_origin.x+KEY_CONTROL_AREA_NUM_COLS, @num_cols].min - 1,
					[current_origin.y+KEY_CONTROL_AREA_NUM_ROWS, @num_rows].min - 1
				)

				origin_button_bounds = @buttons[origin_button.x][origin_button.y].bounds
				corner_button_bounds = @buttons[corner_button.x][corner_button.y].bounds

				x = origin_button_bounds.x
				y = origin_button_bounds.y

				rect = java.awt.Rectangle.new(
					x,
					y,
					corner_button_bounds.x - x + BUTTON_SIZE - 1,
					corner_button_bounds.y - y + BUTTON_SIZE - 1
				)
				rect.grow(3, 3)

				Grrr::ScreenGrid.stroke_rect(g, rect.x, rect.y, rect.width, rect.height, 2, KEY_CONTROL_AREA_BORDER_COLOR)
			end
		end

		@buttons = Array.fill2d(@num_cols, @num_rows) { |x, y|
			button = Grrr::ScreenGridButton.new
			button.set_location(MARGIN+x*BUTTON_SIZE*1.2, MARGIN+y*BUTTON_SIZE*1.2)
			button.set_size(BUTTON_SIZE, BUTTON_SIZE)

			button.add_mouse_listener java.awt.event.MouseListener.impl { |name, event|
				case name
				when :mousePressed
					if @modifier_caps_is_on
						button.toggle_action
					else
						button.value_action=(true)
					end
				when :mouseReleased
					button.value_action=(false) unless hold_modifier
				end
			}
			if not @read_only
				button.action = lambda do |view|
					emit_button_event(Grrr::Point.new(x, y), button.value)
				end
			end
			@panel.add(button)
			button
		}
	end

	def pr_configure_keyboard_actions
		modifier_shift_keycode = 16
		modifier_ctrl_keycode = 17
		modifier_alt_keycode = 18
		modifier_caps_keycode = 20

		key_listener = java.awt.event.KeyListener.impl do |name, event|
			keycode = event.get_key_code
			case name
			when :keyPressed
				case keycode
				when modifier_caps_keycode
					if not @modifier_caps_is_on
						@modifier_caps_is_on = true
					end
				when modifier_shift_keycode
					if not @modifier_shift_is_pressed
						@modifier_shift_is_pressed = true
					end
				when modifier_ctrl_keycode
					if not @modifier_ctrl_is_pressed
						@modifier_ctrl_is_pressed = true
						show_key_control_area if @key_control_enabled
					end
				when modifier_alt_keycode
					if not @modifier_alt_is_pressed
						@modifier_alt_is_pressed = true
						release_all_screen_grid_buttons_within_key_control_area_bounds_unless_hold_modifier(@current_key_control_area)
					end
				when @@keymap_backspace
					toggle_key_control if @modifier_ctrl_is_pressed
				else
					handle_key_control_event(keycode, true) if @key_control_enabled
				end
			when :keyReleased
				case keycode
				when modifier_caps_keycode
					if @modifier_caps_is_on
						@modifier_caps_is_on = false
						release_all_screen_grid_buttons_unless_hold_modifier
					end
				when modifier_shift_keycode
					if @modifier_shift_is_pressed
						@modifier_shift_is_pressed = false
						release_all_screen_grid_buttons_unless_hold_modifier
					end
				when modifier_ctrl_keycode
					if @modifier_ctrl_is_pressed
						@modifier_ctrl_is_pressed = false
						hide_key_control_area if @key_control_enabled
					end
				when modifier_alt_keycode
					if @modifier_alt_is_pressed
						@modifier_alt_is_pressed = false
						release_all_screen_grid_buttons_within_key_control_area_bounds_unless_hold_modifier(next_key_control_area)
					end
				else
					handle_key_control_event(keycode, false) if @key_control_enabled
				end
			end
		end

		@panel.add_key_listener(key_listener)
		@frame.add_key_listener(key_listener)
		@buttons.flatten.each { |b| b.add_key_listener(key_listener) }
	end

	def hold_modifier
		@modifier_caps_is_on or @modifier_shift_is_pressed
	end

	def flash_key_control_area
		show_key_control_area
		if not @modifier_ctrl_is_pressed 
			Thread.new do
				sleep(0.1)
				hide_key_control_area unless @modifier_ctrl_is_pressed
			end
		end
	end

	def show_key_control_area
		@show_current_key_control_area = true
		@panel.repaint
	end

	def hide_key_control_area
		@show_current_key_control_area = false
		@panel.repaint
	end
end

class Grrr::TopView
	def spawn_gui
		Grrr::ScreenGrid.new_view(self)
		self
	end
end

class Grrr::View
	def spawn_gui
		Grrr::ScreenGrid.new_view(self, true)
		self
	end
end

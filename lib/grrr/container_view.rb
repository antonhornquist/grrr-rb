class Grrr::ContainerView < Grrr::View
	attr_reader :press_through

	def initialize(parent=nil, origin=nil, num_cols=nil, num_rows=nil, enabled=true, press_through=false)
		super(nil, nil, num_cols, num_rows, enabled)

		@press_through = press_through
		@children = Array.new

		# view has to be added to parent after class-specific properties
		# have been initialized, otherwise it is not properly refreshed
		validate_parent_origin_and_add_to_parent(parent, origin)
	end

	def self.new_detached(num_cols=nil, num_rows=nil, enabled=true, press_through=false)
		new(nil, nil, num_cols, num_rows, enabled, press_through)
	end

	def self.new_disabled(parent=nil, origin=nil, num_cols=nil, num_rows=nil, press_through=false)
		new(parent, origin, num_cols, num_rows, false, press_through)
	end

	# Parent - Child

	def validate_ok_to_add_child(view, arg_origin)
		raise "[#{view}] is parent of [#{self}]" if get_parents.include?(view)
		raise "origin is required" unless arg_origin
		raise "[#{view}] already has a parent" if view.has_parent?
		origin = arg_origin.to_point
		raise "child view origin may not be negative" if origin.x < 0 or origin.y < 0
		validate_within_bounds(view, origin)
	end

	def add_child(view, origin)
		pr_add_child(view, origin, false)
	end

	def pr_add_child_no_flash(view, origin)
		pr_add_child(view, origin, true)
	end

	def pr_add_child(view, arg_origin, prevent_flash)
		validate_ok_to_add_child(view, arg_origin)

		origin = arg_origin.to_point

		release_all_within_bounds(origin, view.num_cols, view.num_rows)

		@children << view

		view.set_parent_reference(self, origin)

		if (not prevent_flash) and Grrr::Common.indicate_added_removed_attached_detached
			indicate_bounds(view.origin, view.num_cols, view.num_rows)
		elsif view.is_enabled?
			view.refresh
		end
	end

	def remove_all_children
		pr_remove_all_children(false)
	end

	def pr_remove_all_children(prevent_flash)
		@children.dup.each { |child| pr_remove_child(child, prevent_flash) }
	end

	def remove_child(view)
		pr_remove_child(view, false)
	end

	def pr_remove_child(view, prevent_flash)
		validate_parent_of(view)

		@children.delete view

		if (not prevent_flash) and Grrr::Common.indicate_added_removed_attached_detached
			indicate_bounds(view.origin, view.num_cols, view.num_rows)
		elsif view.is_enabled?
			refresh_bounds(view.origin, view.num_cols, view.num_rows)
		end

		view.remove_parent_reference
	end

	def is_parent_of?(view)
		@children.include?(view)
	end

	def enabled_children
		@children.select { |view| view.is_enabled? }
	end

	def has_child_at?(point)
		@children.any? { |view| view.contains_point?(point-view.origin) }
	end

	def get_children_at(point)
		@children.select { |view| view.contains_point?(point-view.origin) }
	end

	def has_any_enabled_child_at?(point)
		enabled_children.any? { |view| view.contains_point?(point-view.origin)}
	end

	def get_topmost_enabled_child_at(point)
		enabled_children.select { |view| view.contains_point?(point-view.origin) }.last
	end

	def is_empty?
		@children.empty?
	end

	def bring_child_to_front(view)
		@children.delete(view)
		@children.push(view)
		refresh_bounds(view.origin, view.num_cols, view.num_rows)
	end

	def send_child_to_back(view)
		@children.delete(view)
		@children.unshift(view)
		refresh_bounds(view.origin, view.num_cols, view.num_rows)
	end

	# Validations

	def validate_within_bounds(view, origin)
		raise "[#{view}] at #{origin} not within bounds of [#{self}]" if not is_within_bounds?(view, origin)
	end

	def is_within_bounds?(view, origin)
		contains_bounds? origin, view.num_cols, view.num_rows
	end

	def validate_parent_of(child)
		raise "[#{self}] is not parent of [#{child}]" unless is_parent_of?(child)
	end

	# Button events and state

	def release_all
		super
		enabled_children.each { |child| child.release_all }
	end

	def handle_view_button_event(source, point, pressed)
		if @enabled
			if has_any_enabled_child_at?(point)
				view = get_topmost_enabled_child_at(point)

				if Grrr::Common.trace_button_events
					puts(
						"in % - button %s at %s (source: [%s]) forwarded to [%s] at %s" %
						[
							"Method " + self.class.to_s + "#handle_view_button_event",
							pressed ? 'press' : 'release',
							point.to_s,
							source.to_s,
							view.to_s,
							view.origin.to_s
						]
					)
				end

				responding_views = view.handle_view_button_event(source, point-view.origin, pressed)
				if @press_through
					responding_views | super(source, point, pressed)
				else
					responding_views
				end
			else
				super(source, point, pressed)
			end
		end
	end

	# Leds and refresh

	def refresh_point(point, refresh_children=true)
		if @enabled
			has_enabled_child_at_point = has_any_enabled_child_at?(point)
			if has_enabled_child_at_point and refresh_children
				view = get_topmost_enabled_child_at(point)

				if Grrr::Common.trace_led_events
					puts(
						"refresh at %s forwarded to [%s] at %s" %
						[
							point.to_s,
							view.to_s,
							view.origin.to_s
						]
					)
				end

				view.refresh_point(point-view.origin)
			elsif not has_enabled_child_at_point
				super(point)
			end
		else
			raise "view is disabled"
		end
	end

	def is_lit_at?(point)
		if has_any_enabled_child_at?(point)
			view = get_topmost_enabled_child_at(point)

			if Grrr::Common.trace_led_events
				puts(
					"is_lit_at? at %s forwarded to [%s] at %s" %
					[
						point.to_s,
						view.to_s,
						view.origin.to_s
					]
				)
			end

			view.is_lit_at?(point-view.origin)
		else
			super(point)
		end
	end

	# String representation

	def to_plot(indent_level=0)
		delimiter = "    "
		plot_pressed_lines = Array.fill(@num_rows) { Array.new }
		plot_led_lines = Array.fill(@num_rows) { Array.new }
		to_points.each { |point|
			wrap = has_any_enabled_child_at?(point) ? ['[', ']'] : [' ', ' ']
			plot_pressed_lines[point.y] << wrap.join(is_pressed_at?(point) ? 'P' : '-')
			plot_led_lines[point.y] << wrap.join(is_lit_at?(point) ? 'L' : '-')
		}
		plot_pressed_lines = plot_pressed_lines.enum_for(:each_with_index).collect { |row, i| i.to_s + ' ' + row.join(' ') }
		plot_led_lines = plot_led_lines.enum_for(:each_with_index).collect { |row, i| i.to_s + ' ' + row.join(' ') }
		plot = '  ' + (0...@num_cols).to_a.collect { |num| " #{num} " }.join(' ')
		plot = "\t"*indent_level + plot + delimiter + plot + "\n"
		@num_rows.times { |i|
			plot << "\t"*indent_level + plot_pressed_lines[i] + delimiter + plot_led_lines[i] + "\n"
		}
		plot
	end

	def to_tree(include_details=false, indent_level=0)
		super(include_details, indent_level) +
		@children.collect { |child|
			child.to_tree(include_details, indent_level+1)
		}.join
	end
end

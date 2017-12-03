class Grrr::Controller
	class << self
		attr_accessor :default
		attr_accessor :init_action
		attr_accessor :all
	end

	@all = []

	attr_reader :num_cols
	attr_reader :num_rows
	attr_reader :view
	attr_reader :origin
	attr_accessor :on_remove

	def initialize(num_cols=nil, num_rows=nil, view=nil, origin=nil, create_top_view_if_none_is_supplied=true)
		@view = nil

		if num_cols == nil or num_rows == nil
			raise "num_cols and num_rows are mandatory"
		end
		@num_cols = num_cols
		@num_rows = num_rows
		@on_remove = nil

		if view and origin
			pr_attach(view, origin.to_point)
		else
			if view
				raise "if a view is supplied an origin must also be supplied"
			end
			if origin
				raise "if an origin is supplied a view must also be supplied"
			end
			if create_top_view_if_none_is_supplied
				pr_attach(Grrr::TopView.new(num_cols, num_rows), Grrr::Point.new(0, 0))
			end
		end
		@is_removed = false
		Grrr::Controller.all << self
		Grrr::Controller.init_action.call(self) if Grrr::Controller.init_action
	end

	def self.new_detached(num_cols=nil, num_rows=nil)
		new(num_cols, num_rows, nil, nil, false)
	end

	def remove
		cleanup
		detach if is_attached?
		Grrr::Controller.all.delete(self)
		@on_remove.call if @on_remove
	end

	def cleanup
		# subclass responsibility
	end

	# Validations

	def validate_contains_point(point)
		raise "point #{point} not within bounds of [#{self}]" if not contains_point? point
	end

	def contains_point?(point)
		(0...@num_cols).include? point.x and (0...@num_rows).include? point.y
	end

	def is_removed?
		@is_removed
	end

	# Bounds

	def num_buttons
		@num_cols * @num_rows
	end

	def to_points
		Grrr::View.bounds_to_points(Grrr::Point.new(0, 0), @num_cols, @num_rows)
	end

	# Attaching and detaching

	def is_attached?
		@view != nil
	end

	def is_detached?
		@view.nil?
	end

	def attach(view, origin)
		pr_attach(view, origin)
		refresh
		if Grrr::Common.indicate_added_removed_attached_detached
			indicate_controller
		end
	end

	def pr_attach(view, origin)
		raise("[%s] is already attached to a view" % [self]) if is_attached?

		if not view.contains_bounds?(origin, @num_cols, @num_rows)
			raise("[%s] at origin %s not within bounds of view [%s]" % [self, origin, view])
		end

		@view = view
		@origin = origin

		if @origin == Grrr::Point.new(0, 0) and @num_cols == view.num_cols and @num_rows == view.num_rows
			@view_led_refreshed_listener = lambda { |source, point, on|
				handle_view_led_refreshed_event(point, on)
			}
			@view_button_state_changed_listener = lambda { |point, pressed|
				handle_view_button_state_changed_event(point, pressed)
			}
		else
			@bottom_right = @origin + Grrr::Point.new(@num_cols-1, @num_rows-1)
			@view_led_refreshed_listener = lambda { |source, point, on|
				if (@origin.x..@bottom_right.x).include?(point.x) and (@origin.y..@bottom_right.y).include?(point.y)
					handle_view_led_refreshed_event(point-@origin, on)
				end
			}
			@view_button_state_changed_listener = lambda { |point, pressed|
				if (@origin.x..@bottom_right.x).include?(point.x) and (@origin.y..@bottom_right.y).include?(point.y)
					handle_view_button_state_changed_event(point-@origin, pressed)
				end
			}
		end
		add_led_refreshed_action(@view_led_refreshed_listener)
		add_button_state_changed_action(@view_button_state_changed_listener)
	end

	def detach
		raise("[%s] is already detached" % [self]) if is_detached?
		remove_button_state_changed_action(@view_button_state_changed_listener)
		remove_led_refreshed_action(@view_led_refreshed_listener)

		view_saved = @view
		origin_saved = @origin
		@view = nil
		@origin = nil

		refresh

		if Grrr::Common.indicate_added_removed_attached_detached
			view_saved.indicate_bounds(origin_saved, @num_cols, @num_rows)
		end
	end

	def emit_press(point)
		emit_button_event(point, true)
	end

	def emit_release(point)
		emit_button_event(point, false)
	end

	def emit_button_event(point, pressed)
		validate_contains_point(point)
		if is_attached?
			@view.handle_view_button_event(self, @origin+point.to_point, pressed)
		end
	end

	def is_pressed_by_this_controller_at?(point)
		validate_contains_point(point)
		if is_attached?
			@view.is_pressed_by_source_at?(self, @origin+point)
		else
			false
		end
	end

	def is_released_by_this_controller_at?(point)
		not is_pressed_by_this_controller_at?(point)
	end

	def is_pressed_at?(point)
		validate_contains_point(point)
		if is_attached?
			@view.is_pressed_at?(@origin+point)
		else
			false
		end
	end

	def is_released_at?(point)
		not is_pressed_at?(point)
	end

	def is_lit_at?(point)
		validate_contains_point(point)
		if is_attached?
			@view.is_lit_at?(@origin+point)
		else
			false
		end
	end

	def handle_view_button_state_changed_event(point, pressed)
		# subclass responsibility
	end

	def handle_view_led_refreshed_event(point, on)
		# subclass responsibility
	end

	def refresh
		to_points.each { |point|
			handle_view_button_state_changed_event(point, is_pressed_at?(point))
			handle_view_led_refreshed_event(point, is_lit_at?(point))
		}
	end

=begin
	DOC:
	Indicates on a view that a Controller is attached. Flashes the Controller's bounds.
=end

	def indicate_controller(repeat=nil, interval=nil)
		validate_controller_is_attached
		@view.indicate_bounds(@origin, @num_cols, @num_rows, repeat, interval)
	end

	def validate_controller_is_attached
		if is_detached?
			raise "controller [#{self}] is not attached to a view"
		end
	end

	# Convenience methods

	def add_button_state_changed_action(function)
		@view.add_action(function, :view_button_state_changed_action)
	end

	def remove_button_state_changed_action(function)
		@view.remove_action(function, :view_button_state_changed_action)
	end

	def add_led_refreshed_action(function)
		@view.add_action(function, :view_led_refreshed_action)
	end

	def remove_led_refreshed_action(function)
		@view.remove_action(function, :view_led_refreshed_action)
	end

	# Delegate to view

	def add_child(view, origin)
		@view.add_child(view, origin)
	end

	def remove_child(view)
		@view.remove_child(view)
	end

	def plot
		@view.plot
	end

	def plot_tree
		post_tree(true)
	end

	def post_tree(include_details=false)
		@view.post_tree(include_details)
	end
end

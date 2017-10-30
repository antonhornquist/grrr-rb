class MockActionListener
	attr_reader :view, :listener, :notifications

	def initialize(view)
		@view = view
		@listener = create_listener
		@view.add_action(@listener, selector)
		@notifications = Array.new
	end

	def remove_listener
		@view.remove_action(@listener, selector)
	end

	def has_been_notified_of?(array); @notifications == array; end
	def has_not_been_notified_of_anything?; @notifications.empty?; end

	private
		def create_listener
			lambda { |*args| @notifications << args }
		end
		def selector; :action; end
end

class MockViewLedRefreshedListener < MockActionListener
	private
		def create_listener
			lambda { |source, point, on|
				@notifications << { :source => source.id, :point => point, :on => on }
			}
		end
		def selector; :view_led_refreshed_action; end
end

class MockViewButtonStateChangedListener < MockActionListener
	private
		def create_listener
			lambda { |point, pressed|
				@notifications << { :point => point, :pressed => pressed }
			}
		end
		def selector; :view_button_state_changed_action; end
end

class MockViewWasEnabledListener < MockActionListener
	private
		def selector; :view_was_enabled_action; end
end

class MockViewWasDisabledListener < MockActionListener
	private
		def selector; :view_was_disabled_action; end
end

class MockButtonPressedListener < MockActionListener
	private
		def selector; :button_pressed_action; end
end

class MockButtonReleasedListener < MockActionListener
	private
		def selector; :button_released_action; end
end

class MockTogglePressedListener < MockActionListener
	private
		def selector; :toggle_pressed_action; end
end

class MockToggleReleasedListener < MockActionListener
	private
		def selector; :toggle_released_action; end
end

class MockToggleValuePressedListener < MockActionListener
	private
		def selector; :toggle_value_pressed_action; end
end

class MockToggleRangePressedListener < MockActionListener
	private
		def selector; :toggle_range_pressed_action; end
end

class MockLitView < Grrr::View
	def initialize(parent, origin, num_cols=nil, num_rows=nil, enabled=true)
		super
		@is_lit_at_func = lambda { |point| true }
	end
end

class MockUnlitView < Grrr::View
	def initialize(parent, origin, num_cols=nil, num_rows=nil, enabled=true)
		super
		@is_lit_at_func = lambda { |point| false }
	end
end

class MockOddColsLitView < Grrr::View
	def initialize(parent, origin, num_cols=nil, num_rows=nil, enabled=true)
		super
		@is_lit_at_func = lambda { |point| point.x % 2 == 1 }
	end
end

class MockLitContainerView < Grrr::ContainerView
	def initialize(parent, origin, num_cols=nil, num_rows=nil, enabled=true, press_through=false)
		super
		@is_lit_at_func = lambda { |point| true }
	end
end

class MockOddColsLitContainerView < Grrr::ContainerView
	def initialize(parent, origin, num_cols=nil, num_rows=nil, enabled=true, press_through=false)
		super
		@is_lit_at_func = lambda { |point| point.x % 2 == 1 }
	end
end

class MockContainerViewSubclassThatActsAsAView < Grrr::ContainerView
	def initialize(parent, origin, num_cols=nil, num_rows=nil)
		super(parent, origin, num_cols, num_rows, true, true)
		@acts_as_view = true
		button1 = Grrr::Button.new_detached(1, 1)
		button2 = Grrr::Button.new_detached(1, 1)
		pr_add_child(button1, Grrr::Point.new(3, 0), true)
		pr_add_child(button2, Grrr::Point.new(2, 1), true)
	end

	def self.new_detached(num_cols, num_rows)
		new(nil, nil, num_cols, num_rows)
	end
end

class MockController < Grrr::Controller
	attr_reader :view_button_state_changed_notifications, :view_led_refreshed_notifications

	def initialize(num_cols=nil, num_rows=nil, view=nil, origin=nil, create_top_view_if_none_is_supplied=true)
		super
		@view_button_state_changed_notifications = []
		@view_led_refreshed_notifications = []
		@register_notifications = false
		refresh
		@register_notifications = true
	end

	def handle_view_button_state_changed_event(point, pressed)
		@view_button_state_changed_notifications << { :point => point, :pressed => pressed } if @register_notifications
	end

	def handle_view_led_refreshed_event(point, on)
		@view_led_refreshed_notifications << { :point => point, :on => on } if @register_notifications
	end
end

class MockNotePressedListener < MockActionListener
	private
		def selector; :note_pressed_action; end
end

class MockNoteReleasedListener < MockActionListener
	private
		def selector; :note_released_action; end
end

class MockButtonValueChangedListener < MockActionListener
	private
		def create_listener
			lambda { |view, x, y, value|
				@notifications << { :view => view, :x => x, :y => y, :val => value }
			}
		end
		def selector; :button_value_changed_action; end
end

class MockToggleValueChangedListener < MockActionListener
	private
		def create_listener
			lambda { |view, i, value|
				@notifications << { :view => view, :i => i, :val => value }
			}
		end
		def selector; :toggle_value_changed_action; end
end

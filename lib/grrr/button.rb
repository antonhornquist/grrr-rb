class Grrr::Button < Grrr::View
	DEFAULT_NUM_COLS = 1
	DEFAULT_NUM_ROWS = 1
	DEFAULT_FLASH_DELAY_WHEN_LIT = 25
	DEFAULT_FLASH_DELAY_WHEN_UNLIT = 50

	attr_accessor :button_pressed_action
	attr_accessor :button_released_action
	attr_accessor :behavior
	attr_writer :coupled

	def initialize(parent, origin, num_cols=nil, num_rows=nil, enabled=true, coupled=true, behavior=:toggle)
		super(parent, origin, num_cols ? num_cols : DEFAULT_NUM_COLS, num_rows ? num_rows : (num_cols ? num_cols : DEFAULT_NUM_ROWS), enabled)
		@coupled = coupled
		@behavior = behavior
		@value = false
		@is_lit_at_func = lambda { |point| @value }
		@view_button_state_changed_action = lambda { |point, pressed|
			button_is_pressed = is_pressed?
			if @button_was_pressed != button_is_pressed
				if is_coupled?
					case @behavior
						when :toggle
							if button_is_pressed
								toggle_value
							end
						when :momentary
							toggle_value
					end
				end
				if button_is_pressed
					@button_pressed_action.call(self) if @button_pressed_action
				else
					@button_released_action.call(self) if @button_released_action
				end
				@button_was_pressed = button_is_pressed
			end
		}
	end

	def self.new_decoupled(parent, origin, num_cols=nil, num_rows=nil)
		new(parent, origin, num_cols, num_rows, true, false)
	end

	def self.new_momentary(parent, origin, num_cols=nil, num_rows=nil)
		new(parent, origin, num_cols, num_rows, true, true, :momentary)
	end

	def is_coupled?
		@coupled
	end

	def is_pressed?
		any_pressed?
	end

	def is_released?
		all_released?
	end

	def flash(delay=nil)
		flash_view(
			if delay
				delay
			else
				if @value
					DEFAULT_FLASH_DELAY_WHEN_LIT
				else
					DEFAULT_FLASH_DELAY_WHEN_UNLIT
				end
			end
		)
	end

	def toggle_value
		self.value_action=(not @value)
	end
end

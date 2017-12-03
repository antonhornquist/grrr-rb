class Grrr::AbstractToggle < Grrr::View
	attr_writer :coupled
	attr_reader :orientation
	attr_reader :thumb_width
	attr_reader :thumb_height

	def initialize(num_cols=nil, num_rows=nil, enabled=true, coupled=true, nillable=false, orientation=:vertical)
		super(nil, nil, num_cols, num_rows, enabled)

		@coupled = coupled
		@nillable = nillable
		@orientation = orientation
		@values_are_inverted = false

		case @orientation
			when :vertical
				@thumb_width = @num_cols
				@thumb_height = 1
			when :horizontal
				@thumb_width = 1
				@thumb_height = @num_rows
		end

		@values_pressed = Array.new
	end

	def is_coupled?
		@coupled
	end

	def is_nillable?
		@nillable
	end

	def values_are_inverted?
		@values_are_inverted
	end

	def values_are_inverted=(values_are_inverted)
		release_all
		@values_are_inverted = values_are_inverted
		refresh if @enabled
	end

	def thumb_size
		[@thumb_width, @thumb_height]
	end

	def thumb_width=(thumb_width)
		self.thumb_size=([thumb_width, @thumb_height])
	end

	def thumb_height=(thumb_height)
		self.thumb_size=([@thumb_width, thumb_height])
	end

	def thumb_size=(thumb_size)
		validate_thumb_size(thumb_size)

		release_all
		@thumb_width = thumb_size[0]
		@thumb_height = thumb_size[1]
		if @value > maximum_value
			@value = 0
		end
		refresh if @enabled
	end

	def is_pressed?
		any_value_pressed?
	end

	def is_released?
		no_value_pressed?
	end

	def value_is_pressed?(value)
		@values_pressed.include?(value)
	end

	def value_is_released?(value)
		not value_is_pressed?(value)
	end

	def no_value_pressed?
		@values_pressed.empty?
	end

	def any_value_pressed?
		not no_value_pressed?
	end

	def first_value_pressed
		@values_pressed.first
	end

	def last_value_pressed
		@values_pressed.last
	end

	def min_value_pressed
		@values_pressed.min
	end

	def max_value_pressed
		@values_pressed.max
	end

	def num_values_pressed
		@values_pressed.size
	end

	def maximum_value
		num_values-1
	end

	def num_values
		num_values_x * num_values_y
	end

	def num_values_x
		@num_cols / @thumb_width
	end

	def num_values_y
		@num_rows / @thumb_height
	end

	def value_at(point)
		non_inverted_value = case @orientation
			when :vertical
				point.y / @thumb_height + point.x / @thumb_width * num_values_y
			when :horizontal
				point.x / @thumb_width + point.y / @thumb_height * num_values_x
			end

		if @values_are_inverted
			maximum_value - non_inverted_value
		else
			non_inverted_value
		end
	end

	# Thumb size

	def validate_thumb_size(thumb_size)
		if thumb_size.size != 2
			raise "thumb size must be an array of two integers: [num_cols, num_rows]."
		end
		validate_thumb_width(thumb_size[0])
		validate_thumb_height(thumb_size[1])
	end

	def validate_thumb_width(thumb_width)
		if not is_valid_thumb_width?(thumb_width)
			raise(
				"%s width (%s) must be divisable by thumb width (%s)" %
				[
					self.class,
					@num_cols,
					thumb_width
				]
			)
		end
	end

	def validate_thumb_height(thumb_height)
		if not is_valid_thumb_height?(thumb_height)
			raise(
				"%s height (%s) must be divisable by thumb height (%s)" %
				[
					self.class,
					@num_rows,
					thumb_height
				]
			)
		end
	end

	def is_valid_thumb_size?(thumb_size)
		is_valid_thumb_width?(thumb_size[0]) and is_valid_thumb_height?(thumb_size[1])
	end

	def is_valid_thumb_width?(thumb_width)
		@num_cols % thumb_width == 0
	end

	def is_valid_thumb_height?(thumb_height)
		@num_rows % thumb_height == 0
	end
end

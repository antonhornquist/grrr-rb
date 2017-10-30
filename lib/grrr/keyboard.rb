class Grrr::Keyboard < Grrr::View
	MIN_MIDI_NOTE_NUMBER = 0
	MAX_MIDI_NOTE_NUMBER = 127

	attr_accessor :note_pressed_on_view_action
	attr_accessor :note_released_on_view_action
	attr_accessor :note_pressed_action
	attr_accessor :note_released_action
	attr_accessor :not_shown_note_state_changed_action
	attr_accessor :behavior
	attr_reader :basenote
	attr_reader :indicate_keys

	def initialize(parent, origin, num_cols=7, num_rows=2, enabled=true, basenote=60, coupled=true, behavior=:momentary)
		super(nil, nil, num_cols, num_rows, enabled)

		validate_midi_note(basenote)
		@basenote=basenote
		pr_recalculate_midi_note_lookup

		@coupled = coupled
		@behavior = behavior
		@indicate_keys=:black_and_white
		@notes_pressed_on_view = Array.new

		@value = Hash.new
		midi_notes_interval.each do |note|
			@value[note] = false
		end

		@view_button_state_changed_action = lambda { |point, pressed|
			note = get_note_at(point)
			if note
				if pressed
					if note_is_released_on_view?(note)
						@note_pressed_on_view_action.call(self, note) if @note_pressed_on_view_action
						@notes_pressed_on_view << note
						if @coupled
							case @behavior
								when :momentary
									set_note_pressed_action(note)
								when :toggle
									toggle_note_action(note)
							end
						end
					end
				else
 					if note_is_pressed_on_view?(note)
						@note_released_on_view_action.call(self, note) if @note_released_on_view_action
						@notes_pressed_on_view.delete(note)
						if @coupled and @behavior == :momentary
							set_note_released_action(note)
						end
					end
				end
			end
		}

		@is_lit_at_func = lambda { |point|
			note = get_note_at(point)
			if note
				lit = case @indicate_keys
					when :black_and_white
						true
					when :black
						is_black_key?(note)
					when :white
						not is_black_key?(note)
					when :none
						false
					end
				if note_is_pressed?(note)
					!lit
				else
					lit
				end
			else
				false
			end
		}

		# view has to be added to parent after class-specific properties
		# have been initialized, otherwise it is not properly refreshed
		validate_parent_origin_and_add_to_parent(parent, origin)
	end

	def self.new_detached(num_cols=7, num_rows=2, enabled=true, basenote=60, coupled=true, behavior=:momentary)
		new(nil, nil, num_cols, num_rows, enabled, basenote, coupled, behavior)
	end

	def self.new_disabled(parent, origin, num_cols=7, num_rows=2, basenote=60, coupled=true, behavior=:momentary)
		new(parent, origin, num_cols, num_rows, false, basenote, coupled, behavior)
	end

	def self.new_decoupled(parent, origin, num_cols=7, num_rows=2, enabled=true, basenote=60, behavior=:momentary)
		new(parent, origin, num_cols, num_rows, enabled, basenote, false, behavior)
	end

	def is_coupled?
		@coupled
	end

	def coupled=(coupled)
		release_all
		@coupled=coupled
	end

	def basenote=(basenote)
		validate_midi_note(basenote)
		release_all
		@basenote = basenote
		pr_recalculate_midi_note_lookup
		refresh
	end

	def indicate_keys=(indicate_keys)
		@indicate_keys = indicate_keys
		refresh
	end

	def get_note_at(point)
		@midi_note_lookup[point.x][point.y]
	end

	def get_point_of_note(note)
		to_points.detect { |point| get_note_at(point) == note }
	end

	def note_is_pressed_on_view?(note)
		@notes_pressed_on_view.include?(note)
	end

	def note_is_released_on_view?(note)
		not note_is_pressed_on_view?(note)
	end

	def note_is_pressed?(note)
		@value[note]
	end

	def note_is_released?(note)
		not note_is_pressed?(note)
	end

	def note_is?(note, pressed)
		@value[note] == pressed
	end

	def keyrange
		(min_note_shown..max_note_shown)
	end

	def min_note_shown
		notes_shown.min
	end

	def max_note_shown
		notes_shown.max
	end

	def note_is_shown?(note)
		notes_shown.include?(note)
	end

	def notes_shown
		@midi_note_lookup.flatten.select { |note| note }
	end

	def is_black_key?(note)
		[1, 3, 6, 8, 10].include?(note%12)
	end

	def flash_note(note, delay=nil)
		if note_is_shown?(note)
			flash_point(get_point_of_note(note), delay)
		end
	end

	def flash_notes(notes, delay=nil)
		shown = notes.select { |note| note_is_shown?(note) }.collect { |note| get_point_of_note(note) }
		flash_points(shown, delay) unless shown.empty?
	end

	def flash_left_edge(delay=nil)
		flash_points(get_left_edge_points, delay)
	end

	def flash_right_edge(delay=nil)
		flash_points(get_right_edge_points, delay)
	end

	def get_left_edge_points
		min_note_shown_point = get_point_of_note(min_note_shown)
		other_point = if is_black_key?(min_note_shown)
			min_note_shown_point + Grrr::Point.new(0, 1)
		else
			min_note_shown_point + Grrr::Point.new(0, -1)
		end
		if contains_point?(other_point)
			[min_note_shown_point, other_point]
		else
			[min_note_shown_point]
		end
	end

	def get_right_edge_points
		max_note_shown_point = get_point_of_note(max_note_shown)
		point_above = max_note_shown_point + Grrr::Point.new(0, -1)
		if contains_point?(point_above)
			[max_note_shown_point, point_above]
		else
			[max_note_shown_point]
		end
	end

	def pr_recalculate_midi_note_lookup
		@midi_note_lookup = Array.fill2d(@num_cols, @num_rows)
		current_note = is_black_key?(basenote) ? basenote+1 : basenote

		current_row = @num_rows-1
		while current_row >= 0
			@num_cols.times do |current_col|
				if is_allowed_midi_note_number?(current_note)
					@midi_note_lookup[current_col][current_row] = current_note
				end

				current_note_flat = current_note-1

				if contains_point?(Grrr::Point.new(current_col, current_row-1)) and is_black_key?(current_note_flat) and is_allowed_midi_note_number?(current_note_flat)
					@midi_note_lookup[current_col][current_row-1] = current_note_flat
				end

				current_note = current_note + (is_black_key?(current_note+1) ? 2 : 1)
			end
			current_row = current_row - 2
		end
	end

	def toggle_note_action(note)
		pr_set_note(note, !note_is_pressed?(note), true)
	end

	def toggle_note(note)
		pr_set_note(note, !note_is_pressed?(note), false)
	end

	def set_note_pressed_action(note)
		pr_set_note(note, true, true) if note_is_released?(note)
	end

	def set_note_pressed(note)
		pr_set_note(note, true, false) if note_is_released?(note)
	end

	def set_note_released_action(note)
		pr_set_note(note, false, true) if note_is_pressed?(note)
	end

	def set_note_released(note)
		pr_set_note(note, false, false) if note_is_pressed?(note)
	end

	def set_note_action(note, pressed)
		pr_set_note(note, pressed, true) if note_is?(note, pressed.not)
	end

	def set_note(note, pressed)
		pr_set_note(note, pressed, false) if note_is?(note, pressed.not)
	end

	def pr_set_note(note, pressed, trigger_actions)
		value[note] = pressed

		if note_is_shown?(note)
			refresh_point(get_point_of_note(note))
		else
			handle_not_shown_note_state_change(note, pressed)
		end

		if trigger_actions
			if pressed
				@note_pressed_action.call(self, note) if @note_pressed_action
			else
				@note_released_action.call(self, note) if @note_released_action
			end
			do_action
		end
	end

	def handle_not_shown_note_state_change(note, pressed)
		if @not_shown_note_state_changed_action.respond_to? :call
			@not_shown_note_state_changed_action.call(self, note, pressed)
		elsif (@not_shown_note_state_changed_action == :flash_edge_on_press and pressed) or (@not_shown_note_state_changed_action == :flash_edge_on_press_and_release)
			if note < min_note_shown
				flash_left_edge
			elsif note > max_note_shown
				flash_right_edge
			end
		end
	end

	def value_action=(value)
		old_value = @value
		if @value != value
			self.value=(value)
			midi_notes_interval.each do |note|
				if old_value[note] != @value[note]
					if value[note] == true
						@note_pressed_action.call(self, note) if @note_pressed_action
					else
						@note_released_action.call(self, note) if @note_released_action
					end
				end
			end
			do_action
		end
	end

	def validate_value(value)
		if value.size != 128 or (not value.keys.to_a.sort == midi_notes_interval.to_a)
			raise "value must contain information for all 128 MIDI notes"
		end
	end

	def validate_midi_note(note)
		raise "invalid MIDI note: #{note}" unless is_allowed_midi_note_number?(note)
	end

	def is_allowed_midi_note_number?(note)
		midi_notes_interval.include?(note)
	end

	def midi_notes_interval
		(MIN_MIDI_NOTE_NUMBER..MAX_MIDI_NOTE_NUMBER)
	end
end

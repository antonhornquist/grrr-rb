class Grrr::HToggle < Grrr::Toggle
	DEFAULT_NUM_COLS = 4
	DEFAULT_NUM_ROWS = 1

	def initialize(parent, origin, num_cols=nil, num_rows=nil, enabled=true, coupled=true, nillable=false)
		super(
			parent,
			origin,
			num_cols ? num_cols : DEFAULT_NUM_COLS,
			num_rows ? num_rows : DEFAULT_NUM_ROWS,
			enabled,
			coupled,
			nillable,
			:horizontal
		)
	end

	def self.new_decoupled(parent, origin, num_cols=nil, num_rows=nil, enabled=true, nillable=false)
		new(
			parent,
			origin,
			num_cols,
			num_rows,
			enabled,
			false,
			nillable
		)
	end

	def self.new_detached(num_cols=nil, num_rows=nil, enabled=true, coupled=true, nillable=false)
		new(
			nil,
			nil,
			num_cols,
			num_rows,
			enabled,
			coupled,
			nillable
		)
	end

	def self.new_nillable(parent, origin, num_cols=nil, num_rows=nil, enabled=true, coupled=true)
		new(
			parent,
			origin,
			num_cols,
			num_rows,
			enabled,
			coupled,
			true
		)
	end
end

class Grrr::HRangeToggle < Grrr::AbstractRangeToggle
	def value_at(point)
		value_at_horizontal(point)
	end
end

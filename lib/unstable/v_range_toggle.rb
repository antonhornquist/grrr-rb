class Grrr::VRangeToggle < Grrr::AbstractRangeToggle
	def value_at(point)
		value_at_horizontal(point)
	end
end

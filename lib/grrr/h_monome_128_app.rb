class Grrr::HMonome128App < Grrr::MonomeApp
	def initialize(name, view=nil, origin=nil, create_top_view_if_none_is_supplied=true)
		super(16, 8, name, view, origin, create_top_view_if_none_is_supplied)
	end
end


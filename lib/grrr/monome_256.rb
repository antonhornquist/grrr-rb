class Grrr::Monome256 < Grrr::Monome
	def initialize(name=nil, view=nil, origin=nil, create_top_view_if_none_is_supplied=true)
		super(16, 16, name, view, origin, create_top_view_if_none_is_supplied)
	end
end

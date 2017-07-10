class Grrr::Monome256App < Grrr::AbstractMonome
	def initialize(name, view=nil, origin=nil, create_top_view_if_none_is_supplied=true)
		super(16, 16, view, origin, create_top_view_if_none_is_supplied)
	end
end

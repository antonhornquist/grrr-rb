module CoreExtensions
	module String
		module ToPoint
			def to_point
				Grrr::Point.new( *self.split('@').collect { |s| s.to_i } )
			end
		end
	end
end


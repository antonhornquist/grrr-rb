#
# Point:
# Based on SuperCollider's Point Class
#
class Grrr::Point
	attr_accessor :x, :y

	def initialize(x, y)
		@x = x
		@y = y
	end

	def ==(point)
		@x == point.x and @y == point.y
	end

	def -(point)
		Grrr::Point.new(@x-point.x, @y-point.y)
	end

	def +(point)
		Grrr::Point.new(@x+point.x, @y+point.y)
	end

	def dist(point)
		Math::sqrt( (@x-point.x)**2 + (@y-point.y)**2 )
	end

	def to_s
		"#@x@#@y"
	end

	def to_point; self; end
end

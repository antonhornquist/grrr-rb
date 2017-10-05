class Array
	def self.fill2d(cols, rows) # SuperCollider style 2d array creation
		if block_given?
			Array.new(cols) { |x| Array.new(rows) { |y| yield(x, y) } }
		else
			Array.new(cols) { Array.new(rows) }
		end
	end
	class << self
		alias :fill :new # Array.new alias to match SuperCollider's Array.fill
	end
end

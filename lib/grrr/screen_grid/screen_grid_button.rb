require 'java'

class Grrr::ScreenGridButton < java.awt.Canvas
	attr_reader :value
	attr_accessor :pressed_color
	attr_accessor :lit_color
	attr_accessor :unlit_color
	attr_accessor :action

	def initialize
		super
		@value = false
		@lit = false
		@pressed = false
		@pressed_color = java.awt.Color.black
		@lit_color = java.awt.Color.new(255, 140, 0)
		@unlit_color = java.awt.Color.gray
	end

	def self.fill_stroke(g, x, y, width, height, pen_width, color)
		g.fill_rect(x+pen_width, y+pen_width, width-pen_width*2, height-pen_width*2)
		Grrr::ScreenGrid.stroke_rect(g, x, y, width-1, height-1, pen_width, color)
	end

	def paint(g)
		size = get_size
		fill_color = @lit ? @lit_color : @unlit_color
		stroke_color = @pressed_color
		g.set_color(fill_color)
		pen_width = (size.width/8).to_i
		if @pressed
			Grrr::ScreenGridButton.fill_stroke(g, 0, 0, size.width, size.height, pen_width, stroke_color)
		else
			g.fill_rect(0, 0, size.width, size.height)
		end
	end

	def is_lit?
		@lit
	end

	def lit=(bool)
		@lit=bool
		repaint
	end

	def is_pressed?
		@pressed
	end

	def pressed=(bool)
		@pressed=bool
		repaint
	end

	def value_action=(bool)
		if (@value != bool)
			self.value=(bool)
			do_action
		end
	end

	def value=(bool)
		@value=bool
	end

	def toggle_action
		self.value_action=(not @value)
	end

	def do_action
		@action.call(self) if @action
	end
end

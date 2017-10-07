# TODO: fix load path hack by making serialoscclient a gem
serialoscclient_rb_path = File.expand_path(File.dirname(__FILE__) + "/../../../serialoscclient-rb/lib")

unless $LOAD_PATH.include?(serialoscclient_rb_path)
	$LOAD_PATH.unshift(serialoscclient_rb_path)
end

require 'serialoscclient'

class Grrr::Monome < Grrr::Controller
	class << self
		attr_reader :all
	end

	@@all = []

	def initialize(num_cols, num_rows, name, view=nil, origin=nil, create_top_view_if_none_is_supplied=true)
		super(num_cols, num_rows, view, origin, create_top_view_if_none_is_supplied)

		@name = name
		grid_spec = {:num_cols => @num_cols, :num_rows => @num_rows}
		@client = SerialOSCClient.new(name, grid_spec, :none)
		@client.grid_refresh_action = lambda { |client| refresh }
		@client.grid_key_action = lambda do |client, x, y, state|
			if (contains_point?(Point.new(x, y)))
				emit_button_event(Point.new(x, y), state == 1)
			else
				puts "%dx%d is outside of current bounds: %dx%d".format(x, y, @num_cols, @num_rows).warn
			end
		end
		@client.will_free = lambda { |client| remove }
		@client.refresh_grid

		@on_remove = lambda { @client.free }

		@@all < self
	end

	def self.new_detached(num_cols, num_rows, name)
		new(num_cols, num_rows, name, nil, nil, false)
	end

	def handle_view_led_refreshed_event(point, on)
		@client.led_set(
			point.x,
			point.y,
			on ? 1 : 0
		)
	end

	def spawn_gui
		ScreenGrid.new(@num_cols, @num_rows, @view, @origin)
	end

	def permanent
		@client.permanent
	end

	def permanent=(permanent)
		@client.permanent=permanent
	end

	def grab_devices
		@client.grab_devices
	end

	def grab_grid
		@client.grab_grid
	end

	def to_serial_osc_client
		@client
	end

	# TODO: propagate to subclasses
	def to_s
		"Monome 64 (Prefix: \"#@prefix\", Host Address: #@host_address, Host Port: #@host_port, Listen Port: #@listen_port)" 
	end
end

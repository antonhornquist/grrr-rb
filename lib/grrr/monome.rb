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

	def initialize(num_cols=16, num_rows=8, name=nil, view=nil, origin=nil, create_top_view_if_none_is_supplied=true)
		super(num_cols, num_rows, view, origin, create_top_view_if_none_is_supplied)

		@name = name
		@on_grid_routed = nil
		@on_grid_unrouted = nil
		grid_spec = {:num_cols => @num_cols, :num_rows => @num_rows}
		@client = SerialOSCClient.new(name, grid_spec, :none, lambda { |serialoscclient|
			serialoscclient.grid_refresh_action = lambda { |client| refresh }
			serialoscclient.grid_key_action = lambda do |client, x, y, state|
				if (contains_point?(Point.new(x, y)))
					emit_button_event(Point.new(x, y), state == 1)
				else
					puts "%dx%d is outside of current bounds: %dx%d".format(x, y, @num_cols, @num_rows).warn
				end
			end
			serialoscclient.on_free = lambda { |client| remove }
			serialoscclient.on_grid_routed = lambda { |client, grid| @on_grid_routed.call(self, grid) if @on_grid_routed }
			serialoscclient.on_grid_unrouted = lambda { |client, grid| @on_grid_unrouted.call(self, grid) if @on_grid_unrouted }
			Thread.new do
				sleep 0.5
				@client = serialoscclient
				@client.refresh_grid
			end
		})

		@on_remove = lambda { @client.free }

		@@all << self
	end

	def self.new_detached(num_cols, num_rows, name)
		new(num_cols, num_rows, name, nil, nil, false)
	end

	def handle_view_led_refreshed_event(point, on)
		if @client
			@client.led_set(
				point.x,
				point.y,
				on ? 1 : 0
			)
		end
	end

	def cleanup
		if @client
			if @client.active
				@client.free
			end
		end
	end

	def spawn_gui
		ScreenGrid.new(@num_cols, @num_rows, @view, @origin)
	end

	def grab_devices
		if @client
			@client.grab_devices
		end
	end

	def grab_grid
		if @client
			@client.grab_grid
		end
	end

	def to_serialoscclient
		if @client
			@client
		else
			raise "No client instantiated"
		end
	end
end

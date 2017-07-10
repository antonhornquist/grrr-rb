require 'osc-ruby'
require 'osc-ruby/em_server' if defined?(EventMachine)

class Grrr::AbstractMonome < Grrr::Controller
	DEFAULT_HOST_ADDRESS = "127.0.0.1"
	DEFAULT_HOST_PORT = 8000
	DEFAULT_LISTEN_PORT = 8080
	DEFAULT_PREFIX = "/64"

	attr_reader :prefix, :host_address, :host_port, :listen_port

=begin
	class << self
		attr_reader :all
	end

	@@all = [] # TODO
=end

	def initialize(num_cols, num_rows, view=nil, origin=nil, create_top_view_if_none_is_supplied=true)
		super(num_cols, num_rows, view, origin, create_top_view_if_none_is_supplied)

		@host_address = host_address ? host_address : DEFAULT_HOST_ADDRESS
		@host_port = host_port ? host_port : DEFAULT_HOST_PORT
		@listen_port = listen_port ? listen_port : DEFAULT_LISTEN_PORT
		@prefix = prefix ? prefix : DEFAULT_PREFIX

		@server = (defined?(EventMachine) ? OSC::EMServer : OSC::Server).new(@host_port)
		@client = OSC::Client.new(@host_address, @listen_port)

  	@server.add_method "#@prefix/press" do |message|
			x, y, pressed = message.to_a
			emit_button_event(Point.new(x, y), (pressed==1) ? true : false)
  	end

		@server_thread = Thread.new do
			@server.run
		end

		refresh
	end

	def self.new_detached(num_cols=nil, num_rows=nil)
		new(prefix, host_address, host_port, listen_port, nil, nil, false)
	end

	# TODO: works, or should this be handled as a callback?
	def cleanup
		@server_thread.exit
	end

	def handle_view_led_refreshed_event(point, on)
		@client.send( 
			OSC::Message.new(
				"#{prefix}/led", 
				point.x,
				point.y,
				on ? 1 : 0
			)
		)
	end

	def spawn_gui
		ScreenGrid.new(@num_cols, @num_rows, @view, @origin)
	end

=begin
	def permanent
	end

	def permanent=(permanent)
	end

	def grab_devices
	end

	def grab_grid
	end

	def as_serial_osc_client
	end
=end

	def to_s
		"Monome 64 (Prefix: \"#@prefix\", Host Address: #@host_address, Host Port: #@host_port, Listen Port: #@listen_port)" 
	end
end

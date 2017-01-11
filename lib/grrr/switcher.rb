class Grrr::Switcher < Grrr::ContainerView
	attr_reader :current_view

	def initialize(parent, origin, num_cols=nil, num_rows=nil, enabled=true, press_through=false)
		super(parent, origin, num_cols, num_rows, enabled, press_through)
		@current_view = nil
	end

	def add_child(view, origin)
		# TODO: below check added in conjunction with resolving monome repaint issues due to disabling and enabling views quickly. fix for when setting new value below could only be guaranteed to work when child view bounds are the same as GRSwitcher bounds which is why this guard clause was included for now. can be removed if *all* affected points are refreshed in one go after reenabling view led refreshed action
		raise "View added to GRSwitcher must be of same size as the GRSwitcher view: #{@num_cols}x#{@num_rows}" unless (view.num_cols == @num_cols) and (view.num_rows == @num_rows)
		if @current_view
			if view.is_enabled?
				view.disable
			end
		else
			if view.is_disabled?
				view.enable
			end
			@current_view = view
		end
		super(view, origin)
	end

	def remove_child(view)
		if view == @current_view
			if @children.size == 1
				@current_view = nil
			else
				current_value = value
				if current_value == 0
					self.value=(1)
				else
					self.value=(current_value-1)
				end
			end
		end
		super(view)
	end

	def validate_ok_to_enable_child(child)
		validate_ok_to_enable_or_disable_children
	end

	def validate_ok_to_disable_child(child)
		validate_ok_to_enable_or_disable_children
	end

	def validate_ok_to_enable_or_disable_children
		if @current_view != nil
			raise "it is not allowed to enable or disable children of a #{self.class}. change value to switch between views."
		end
	end

	def switch_to_view(view)
		validate_parent_of(view)
		self.value=(@children.index(view))
	end

	def switch_to(id)
		if @children.collect { |child| child.id }.uniq.size != @children.size
			raise "children in switcher do not have unique ids. it is not allowed to switch by id."
		end

		child = @children.detect { |c| c.id == id }
		if child
			self.value=(@children.index(child))
		else
			raise "no child with id #{id} in switcher."
		end
	end

	def value
		@children.index(@current_view)
	end

	def value=(index)
		if index == nil
			raise "it is not allowed to set switcher value to nil" # TODO: why? perhaps we should allow?
		end
		if (index < 0 or index >= @children.size)
			raise "bad child index #{index}. view has #{@children.size} children."
		end
		if value != index
			new_current_view = @children[index]
			if @current_view != nil
				prev_current_view = @current_view
				@current_view = nil
				remove_action(@parent_view_led_refreshed_listener, :view_led_refreshed_action); # TODO added to resolve monome repaint issues due to disabling and enabling views quickly. differing led repaint messages sent too quickly would not be handled sequentially and thus not yield the expected result. still a bug if child view bounds are not the same as GRSwitcher bounds why guard clause is included above
				prev_current_view.disable
				add_action(@parent_view_led_refreshed_listener, :view_led_refreshed_action); # TODO: added to resolve monome repaint issues
			end
			new_current_view.enable
			@current_view = new_current_view
		end
	end
end

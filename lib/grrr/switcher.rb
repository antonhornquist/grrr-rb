class Grrr::Switcher < Grrr::ContainerView
	attr_reader :current_view

	def add_child(view, origin)
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

		child = @children.detect { |child| child.id == id }
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
				prev_current_view.disable
			end
			new_current_view.enable
			@current_view = new_current_view
		end
	end
end

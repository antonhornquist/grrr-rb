require 'set'

#
# Dependancy support
#
class Object
	# dependancy support
	@@dependants_dictionary = Hash.new

	def dependants
		@@dependants_dictionary[self] or Set.new
	end

	def changed(what, *more_args)
		if @@dependants_dictionary[self]
			@@dependants_dictionary[self].dup.each do |item|
				item.update(self, what, *more_args)
			end
		end
	end

	def add_dependant(dependant)
		the_dependants = @@dependants_dictionary[self]
		if the_dependants
			the_dependants.add(dependant)
		else
			the_dependants = Set.new
			the_dependants.add(dependant)
			@@dependants_dictionary[self] = the_dependants
		end
	end

	def remove_dependant(dependant)
		the_dependants = @@dependants_dictionary[self]
		if the_dependants
			the_dependants.delete(dependant)
			if the_dependants.size == 0
				@@dependants_dictionary.delete(self)
			end
		end
	end

	def release
		release_dependants
	end

	def release_dependants
		@@dependants_dictionary.delete(self)
	end

	def update(the_changed, the_changer, *more_args)
	end
end

class SimpleController
	# responds to updates of a model
	def initialize(model)
		@model = model
		@model.add_dependant(self)
	end

	def put(what, action)
		@actions = Hash.new unless @actions
		@actions[what] = action
	end

	def update(the_changer, what, *more_args)
		if action = @actions[what]
			action.call(the_changer, what, *more_args)
		end
	end

	def remove
		model.remove_dependant(self)
	end
end

class TestDependant
	def update(thing)
		puts "#{thing} was changed."
	end
end

#
# Symbol extensions
# is_setter? - Answer whether the symbol has a trailing equals sign (equivalent to Symbol:isSetter in SC).
# to_setter - Return a symbol with a trailing equals sign added (equivalent to Symbol:asSetter in SC).
# to_getter - Return a symbol with a trailing equals sign removed (equivalent to Symbol:asGetter in SC).
#
class Symbol
	def is_setter?
		self.to_s[-1] == ?=
	end
	def to_setter
		(to_getter.to_s+"=").to_sym
	end
	def to_getter
		is_setter? ? self.to_s[0...-1].to_sym : self
	end
end

#
# Array extensions
# fill2d - simplified 2d array creation
# fill - Array.new aliased to match SuperCollider's Array.fill
#
class Array
	def self.fill2d(cols, rows)
		if block_given?
			Array.new(cols) { |x| Array.new(rows) { |y| yield(x, y) } }
		else
			Array.new(cols) { Array.new(rows) }
		end
	end
	class << self
		alias :fill :new
	end
end

#
# ProcList:
# Based on SuperCollider's FunctionList Class
#
class ProcList
	attr_accessor :array

	def initialize(*procs)
		@array = procs
	end

	def add_proc(*procs, &block)
		@array = @array + procs
		@array << block if block_given?
		self
	end

	def remove_proc(a_proc)
		@array.delete a_proc
		array.size < 2 ? array[0] : self
	end

	def call(*args)
		@array.collect do |a_proc|
			a_proc.call(*args)
		end
	end
	
	alias :add_func :add_proc
	alias :remove_func :remove_proc
	alias :update :call
end

#
# NilClass extension
# ProcList support
#
class NilClass
	def add_proc(*procs, &block)
		procs = procs + [block] if block_given?
		if procs.size <= 1
			procs[0]
		else
			ProcList.new(*procs)
		end
	end

	def remove_proc(a_proc)
		self
	end

	alias :add_func :add_proc
	alias :remove_func :remove_proc
end

#
# Proc extension
# ProcList support
#
class Proc
	def add_proc(*procs, &block)
		arr = [self] + procs
		arr << block if block_given?
		ProcList.new(*arr)
	end

	def remove_proc(a_proc)
		nil
	end

	alias :add_func :add_proc
	alias :remove_func :remove_proc
	alias :update :call
end

#
# Point:
# Based on SuperCollider's Point Class
#
class Point
	attr_accessor :x, :y

	def initialize(x, y)
		@x = x
		@y = y
	end

	def ==(point)
		@x == point.x and @y == point.y
	end

	def -(point)
		Point.new(@x-point.x, @y-point.y)
	end

	def +(point)
		Point.new(@x+point.x, @y+point.y)
	end

	def dist(point)
		Math::sqrt( (@x-point.x)**2 + (@y-point.y)**2 )
	end

	def to_s
		"#@x@#@y"
	end

	def to_point; self; end
end

#
# NilClass extension
# support for to_point
#
class NilClass
	def to_point
		self
	end
end

#
# String extension
# to_point - simple point creation
#
class String
	def to_point
		Point.new( *self.split('@').collect { |s| s.to_i } )
	end
end

#
# Array extension
# Returns a new Array whose elements contain all possible combinations of the receiver's subcollections.
#
# Based on SuperCollider's Array.allTuples method
#
class Array
	def all_tuples
		num_subcollections = size
		subcollection_sizes = map { |e| e.size }
		num_combinations = subcollection_sizes.inject { |a,b| a*b } 

		result = Array.new(num_combinations) { Array.new(num_subcollections) }
		arr_copy = dup

		num_subcollections.times do |i|
			subcollection_size = subcollection_sizes.shift
			subcollection = arr_copy.shift
			num_repeats = subcollection_sizes.inject { |a,b| a*b }
			num_repeats = 1 unless num_repeats

			(num_combinations/num_repeats).times do |j|
				num_repeats.times do |k|
					index = j%subcollection_size

					value = subcollection[index]

					result[j*num_repeats+k][i] = value
				end
			end
		end
		result
	end
end

#
# NotificationCenter
#
class NotificationRegistration
	attr_accessor :object, :message, :listener

	def initialize(o, m, l)
		@object = o
		@message = m
		@listener = l
	end

	def remove
		NotificationCenter.unregister(@object, @message, @listener)
	end
end

class NotificationCenter
	@@registrations = Hash.new

	def self.notify(object, message, args=nil)
		@@registrations.select do |key, value|
			key[0] == object and key[1] == message
		end.each do |key, value|
			value.call(*args)
		end
	end

	def self.register(object, message, listener, action)
		nr = NotificationRegistration.new(object, message, listener)
		@@registrations.store([object, message, listener], action)
		nr
	end

	def self.unregister(object, message, listener)
		@@registrations.delete([object, message, listener])
	end

	def self.register_one_shot(object, message, listener, action)
		@@registrations.store([object, message, listener], lambda { |*args|
			action.call(*args)
			unregister(object, message, listener)
		})
	end

	def self.clear
		@@registrations.clear
	end

	def self.registration_exists?(object, message, listener)
		@@registrations[[object, message, listener]] != nil
	end
end

if (defined? RUBY_ENGINE != nil) and RUBY_ENGINE == 'jruby'
	require 'java'

	#
	# java.awt.Panel Extensions - add draw_hook function for behavior similar to SC Window/View classes
	#
	class JavaAWTPanelWithDrawHook < java.awt.Panel
		attr_accessor :draw_hook
		def paint(g); @draw_hook.call(g); end
	end
end

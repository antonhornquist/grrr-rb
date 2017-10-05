module CoreExtensions
	module Symbol
		module SetterGetter
			# is_setter? - Answer whether the symbol has a trailing equals sign (equivalent to Symbol:isSetter in SC).
			def is_setter?
				self.to_s[-1] == ?=
			end

			# to_setter - Return a symbol with a trailing equals sign added (equivalent to Symbol:asSetter in SC).
			def to_setter
				(to_getter.to_s+"=").to_sym
			end

			# to_getter - Return a symbol with a trailing equals sign removed (equivalent to Symbol:asGetter in SC).
			def to_getter
				is_setter? ? self.to_s[0...-1].to_sym : self
			end
		end
	end
end

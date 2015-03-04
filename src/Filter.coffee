class Filter extends Miwo.Object

	name: null
	type: "string"
	operation: "="
	value: null
	params: null


	constructor: (config) ->
		super(config)
		if @operation is "in" or @operation is "!in"
			@value = @value.split(",")
		return


	match: (record) ->
		if @type is "callback"
			return @operation(record, @value)
		else if @type is "string"
			val = record.get(@name)
			switch @operation
				when "="
					return val is @value
				when "!="
					return val isnt @value
				when "in"
					return @value.indexOf(val) >= 0
				when "!in"
					return @value.indexOf(val) < 0
				when "!empty"
					return !!val
				when "empty"
					return !val
			return false
		return null


	toData: ->
		name: @name
		value: @value
		type: @type
		operation: @operation
		params: JSON.encode(@params)


module.exports = Filter
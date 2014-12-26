class BaseManager

	types: null
	items: null


	constructor: ->
		@types = {}
		@items = {}


	define: (name, klass) ->
		if !Type.isFunction(klass)
			throw new Error("Bad defined type '#{name}' in '#{this}'. Class is not function")
		@types[name] = klass
		return this


	register: (name, object) ->
		@items[name] = object
		return this


	unregister: (name) ->
		delete @items[name]
		return this


	has: (name) ->
		return @items[name] isnt undefined


	get: (name) ->
		if !@items[name]
			@register(name, @create(name))
		return @items[name]


	create: (name, config) ->
		if !@types[name]
			throw new Error("Undefined type '#{name}' in #{this}")
		return new @types[name](config)


	toString: ->
		return @constructor.name


module.exports = BaseManager
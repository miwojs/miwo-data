Record = require './Record'
Store = require './Store'
EntityManager = require './EntityManager'


class Entity extends Record

	collections: null
	entities: null


	@collection: (name, config) ->
		if @prototype[name]
			throw new Error("Property #{name} is already defined. Please use other collection name")

		# set collection metadata
		if !@prototype._collections
			@prototype._collections = {}
		@prototype._collections[name] = config
		# create related property getter
		Object.defineProperty @prototype, name,
							  get: -> return @getCollection(name)

		ownerName = @prototype.constructor.name
		relatedPrototype = config.type.prototype
		# set entities metadata
		if !relatedPrototype._entities
			relatedPrototype._entities = {}
		relatedPrototype._entities[ownerName] = {type: @prototype.constructor}
		# create reverse entity getter
		relatedPrototype['get'+ownerName.capitalize()] = (callback)->
			@getEntity(ownerName, callback)
			return
		return


	setup: (data) ->
		super(data)
		if @_collections
			# configure collections
			@collections = {}
			for name,config of @_collections
				@collections[name] = new Store
					entity: config.type

			# load collections data
			for name, collection of @collections
				values = data[name] || []
				collection.loadData(values)
		return


	copy: (source) ->
		super(source)
		# todo: copy collections + entitites ??
		return


	getCollection: (name) ->
		return @collections[name]


	getEntity: (name, callback) ->
		if !@entities
			@entities = {}
		if !@entities[name]
			@entities[name] = new @_entities[name].type()
		@entities[name].load(@get(name+'Id'), callback)
		return


	save: (callback) ->
		EntityManager.save(this, callback)
		return


module.exports = Entity
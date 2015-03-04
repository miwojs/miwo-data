BaseManager = require './BaseManager'


class EntityManager extends BaseManager

	proxyKlass: null


	setProxy: (@proxyKlass) ->
		return this


	get: (name) ->
		return @items[name]


	load: (entity, id, callback) ->

		return


	save: (entity, callback) ->

		return


	create: (name, config) ->
		if Type.isString(name)
			entity = super(name, config)
		else if Type.isFunction(name)
			entity = new name(config)
		else
			throw new Error("Cant create entity, parameter name must by string or function, you put: "+ (typeof name))

		# init entity proxy

		return entity


	createEntityClass: (config) ->
		Entity = require './Entity'

		class GeneratedEntity extends Entity
			idProperty: config.idProperty

		for field,obj of config.fields
			GeneratedEntity.field(field, obj)

		return GeneratedEntity


module.exports = EntityManager
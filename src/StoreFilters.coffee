Filter = require './Filter'


class StoreFilters

	filters: null
	store: null


	constructor: (@store) ->
		@filters = []


	getAll: () ->
		return @filters


	clear: ->
		@filters.empty()
		return


	append: (filter) ->
		@filters.push(filter)
		return


	has: () ->
		return @filters.length > 0


	add: (name, value, type, operation, params) ->
		if Type.isArray(name)
			for filter in name
				@add(filter)
		else
			if Type.isInstance(name)
				@append(name)
			else if Type.isObject(name)
				@append(new Filter(name))
			else
				@append(new Filter({name: name, value: value, type: type, operation: operation, params: params}))
		return this


	filter: (name, value, type, operation, params) ->
		@clear()
		@add(name, value, type, operation, params) if name
		@apply()
		return this


	apply: (silent) ->
		if @store.remoteFilter
			@store.load()
		else
			@store.filtered = @filters.length > 0
			@store.filteredData = []
			for rec in @store.data
				if @match(rec)
					@store.filteredData.push(rec)
			if !silent
				@store.emit("refresh", @store)

		@store.emit("filter", @store, @filters)
		return this


	match: (record) ->
		for filter in @filters
			if filter.match(record) is false
				return false
		return true


module.exports = StoreFilters
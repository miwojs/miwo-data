Sorter = require './Sorter'


class StoreSorters

	sorters: null
	store: null


	constructor: (@store) ->
		@sorters = []
		@comparator = @createComparator(this)
		return


	clear: ->
		@sorters.empty()
		return this


	has: ->
		return @sorters.length > 0


	getAll: ->
		return @sorters


	set: (name, dir) ->
		if Type.isObject(name)
			for n,d of name then @set(n, d)
		else
			@sorters.push(new Sorter({name:name, dir:dir}))
		return this


	sort: (name, dir) ->
		@clear()
		@set(name, dir) if name
		@apply()
		return this


	apply: (silent) ->
		store = @store
		sorters = @sorters
		comparator = @comparator

		if store.remoteSort
			store.load()
		else
			store.sorted = sorters.length > 0
			store.data.sort(comparator)
			store.filteredData.sort(comparator)  if store.filteredData
			store.emit("refresh", store)  if !silent
		store.emit("sort", store, sorters)
		return this


	getInsertionIndex: (record, compare) ->
		index = 0
		for rec,index in @store.data
			if compare(rec, record) > 0
				return index
		return index


	getIndex: (rec) ->
		return @getInsertionIndex(rec, @comparator)


	createComparator: (me)->
		return (a, b) ->
			if !me.sorters
				return
			for sorter in me.sorters
				ret = sorter.compare(a, b)
				if ret is -1 or ret is 1
					return ret
			return


module.exports = StoreSorters
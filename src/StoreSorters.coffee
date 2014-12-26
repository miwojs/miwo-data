Sorter = require './Sorter'


class StoreSorters

	sorters: null
	store: null


	constructor: (@store) ->
		@sorters = []


	clear: () ->
		@sorters.empty()
		return this


	has: () ->
		return @sorters.length > 0


	set: (name, dir) ->
		if Type.isObject(name)
			for n,d of name
				@sorters.push(new Sorter({name:n, dir:d}))
		else
			@sorters.push(new Sorter({name:name, dir:dir}))
		return this


	sort: (name, dir) ->
		@clear()
		@set(name, dir) if name
		@apply()
		return this


	apply: (silent) ->
		if @store.remoteSort
			@store.load()
		else
			comparator = @createSortComparator()
			@store.sorted = @sorters.length > 0
			@store.data.sort(comparator)
			@store.filteredData.sort(comparator)  if @store.filteredData
			@store.emit("refresh", @store)  if !silent

		@store.emit("sort", @store, @sorters)
		return this


	createSortComparator: () ->
		return (a, b) =>
			if !@sorters
				return
			for sorter in @sorters
				ret = sorter.compare(a, b)
				if ret is -1 or ret is 1
					return ret
			return


	getInsertionIndex: (record, compare) ->
		index = 0
		for rec,index in @data
			if compare(rec, record) > 0
				return index
		return index


	getIndex: (rec) ->
		return @getInsertionIndex(rec, @createSortComparator())



module.exports = StoreSorters
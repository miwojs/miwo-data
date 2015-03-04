StoreFilters = require './StoreFilters'
StoreSorters = require './StoreSorters'



class Store extends Miwo.Object

	# @event refresh(store) emited by sorters or filters
	# @event add(store,records,index)
	# @event datachanged(store)
	# @event beforeload(store, operation)
	# @event load(store, records, success)
	# @event reeload(store)
	# @event remove(store, record, index)
	# @event removeall(store)
	# @event update(store, record, operation, modifiedFieldNames)
	# @event write(store, operation)

	isStore: true
	name: null
	entity: null
	fields: null
	idProperty: 'id'

	data: null
	newRecords: null
	removedRecords: null
	updatedRecords: null

	autoLoad: false
	autoSync: false
	autoSyncReload: false
	autoSyncSuspended: false
	remoteFilter: false
	remoteSort: false
	proxy: null

	storeFilters: null
	filteredData: null
	filterOnLoad: true
	filterOnEdit: true
	filtered: false
	filter: null
	@getter 'filters', () -> return @getFilters()

	storeSorters: null
	sortOnLoad: true
	sortOnEdit: true
	sort: null
	@getter 'sorters', () -> return @getSorters()

	pageSize: null
	loading: false
	loaded: false
	totalCount: 0
	page: 1
	params: null


	constructor: (config = {}) ->
		super(config)

		@newRecords = []
		@removedRecords = []
		@updatedRecords = []

		if config.entity
			@entity = config.entity

		if !@entity and @fields
			@entity = miwo.entityMgr.createEntityClass({fields: @fields, idProperty: @idProperty})
			delete @fields
			delete @idProperty

		if !@entity
			throw new Error("Unspecified entity or fields for store #{this}")

		if !@proxy && @api
			@proxy = {api: @api}
			delete @api

		if @proxy || @api
			proxyMgr = miwo.proxyMgr
			if Type.isString(@proxy)
				@proxy = proxyMgr.get(@proxy)
			else if Type.isObject(@proxy)
				@proxy = proxyMgr.createProxy(@proxy)
		else if @entity.proxy
			proxyMgr = miwo.proxyMgr
			if Type.isString(@entity.proxy)
				@proxy = proxyMgr.get(@entity.proxy)
			else if Type.isObject(@entity.proxy)
				@proxy = proxyMgr.createProxy(@entity.proxy)

		# register named store, if not registered
		if @name
			if !miwo.storeMgr.has(@name)
				miwo.storeMgr.register(@name, this)

		if @sort
			@getSorters().set(@sort)

		if @filter
			@getFilters().set(@filter)

		@data = []
		@init()

		if @autoLoad
			@load()


	init: ->
		return

	getAll: () ->
		return @data


	getLast: () ->
		return this.data.getLast()


	getFirst: () ->
		return this.data[0]


	getCount: () ->
		return this.data.length


	getAt: (index) ->
		return if index < @data.length then @data[index] else null


	getById: (id) ->
		for rec in @data
			if `rec.id == id`
				return rec
		return null


	attachRecord: (rec) ->
		rec.joinStore(this)
		return


	detachRecord: (rec) ->
		rec.unjoinStore(this)
		return


	isLoading: ->
		return @loading


	isFiltered: ->
		return @filtered


	getTotalCount: () ->
		return @totalCount


	getModifiedRecords: () ->
		return [].concat(@getNewRecords(), @getUpdatedRecords())


	getNewRecords: () ->
		return @newRecords


	getRemovedRecords: () ->
		return @removedRecords


	getUpdatedRecords: () ->
		return @updatedRecords


	getRecords: () ->
		return if @filtered then @filteredData else @data


	each: (callback) ->
		@data.each(callback)
		return


	loadRecords: (recs, clear = false) ->
		if clear
			@clear()

		for rec in recs
			@data.push(rec)
			@attachRecord(rec)

		if @sortOnLoad && !@remoteSort && @storeSorters && @storeSorters.has()
			@storeSorters.apply(true)

		if @filterOnLoad && !@remoteFilter && @storeFilters && @storeFilters.has()
			@storeFilters.apply(true)

		@emit('datachanged', this)
		return


	setData: (data, clear) ->
		records = []
		for values in data
			records.push(@createRecord(values))
		@loadRecords(records, clear)
		@emit("load", this, records)
		return


	# Creates record
	# @param {Object} values
	# @returns {Miwo.data.Record}
	createRecord: (values) ->
		return miwo.entityMgr.create(@entity, values)



	setProxy: (proxy) ->
		@proxy = proxy
		return


	getProxy: ->
		return @proxy


	#//////////////////////////////////////////////////////////////////////////////////////////////
	# Data finding


	indexOf: (find, findInFiltered) ->
		source = if !findInFiltered || findInFiltered && !@filtered then @data else @filteredData
		for rec,index in source
			if rec is find
				return index
		return null


	indexOfId: (id) ->
		for rec,index in @data
			if rec.getId() is id
				return index
		return null


	findAtBy: (callback) ->
		for rec,index in @data
			if callback(rec,index)
				return index
		return null


	findAtRecord: (fieldName, value, op, startIndex) ->
		return @findAtBy(@createFinderCallback(fieldName, value, op, startIndex))


	findAtExact: (fieldName, value, startIndex) ->
		return @findAtRecord(fieldName, value, "===", startIndex)


	findBy: (callback) ->
		for rec in @data
			if callback(rec)
				return rec
		return null


	findRecord: (fieldName, value, op, startIndex) ->
		return @findBy(@createFinderCallback(fieldName, value, op, startIndex))


	findExact: (fieldName, value, startIndex) ->
		return @findRecord(fieldName, value, "===", startIndex)


	findAllBy: (callback) ->
		find = []
		for rec in @data
			if callback(rec)
				find.push(rec)
		return find


	findAllAt: (index, count = 1) ->
		indexTo = index + count
		find = []
		for rec,i in @data
			if i >= index && i < indexTo
				find.push(rec)
		return find


	findRecords: (fieldName, value, op, startIndex) ->
		return @findAllBy(@createFinderCallback(fieldName, value, op, startIndex))


	createFinderCallback: (fieldName, value, op = "?", startIndex = null) ->
		return (rec, index) =>
			if startIndex is null || index >= startIndex
				recval = rec.get(fieldName)
				switch op
					when "==="
						return true  if recval is value
					when "=="
						return true  if recval is value
					when "="
						return true  if recval.toString().test(value)
					when "?"
						return true  if recval.toString().test(value, "i")
					else
						throw new Error("Unknown operator " + op)
			return false


	#//////////////////////////////////////////////////////////////////////////////////////////////
	# Data inserting


	add: (recs) ->
		recs = Array.from(recs)
		added = false
		if recs.length is 0
			return
		for rec in recs
			added = true
			@data.push(rec)
			@newRecords.push(rec)
			@removedRecords.erase(rec)
			if @filtered and @getFilters().match(rec) then @filteredData.push(rec)
			@attachRecord(rec)
			@emit('add', this, rec)
		if added
			@emit('datachanged', this)
		return


	insert: (index, recs, reversed) ->
		recs = Array.from(recs)
		if recs.length is 0
			return
		for rec,i in recs
			pos = (if reversed then 0 else index + i)
			@data.insert(pos, rec)
			@newRecords.push(rec)
			@removedRecords.erase(rec)
			if @filtered and @getFilters().match(rec) then @filteredData.push(rec)
			@attachRecord(rec)
			@emit('add', this, rec, pos)
		@emit("datachanged", this)
		return


	###*
	  (Local sort only) Inserts the passed Record into the Store at the index where it
	  should go based on the current sort information.
	  @param {Miwo.data.Record} record
	  ###
	addSorted: (record) ->
		index = if @storeSorters then @storeSorters.getIndex(record) else @data.length
		@insert(index, record)
		return record


	addData: (values) ->
		if Type.isArray(values)
			records = []
			for data in values then records.push(@createRecord(data))
			@add(records)
		else
			@add(@createRecord(values))
		return this


	#//////////////////////////////////////////////////////////////////////////////////////////////
	# Data removing


	removeBy: (callback) ->
		@remove(@findAllBy(callback))
		return


	removeRecord: (field, value) ->
		@removeBy (rec) ->
			return rec.get(field) is value
		return

	removeById: (id) ->
		@remove(@getById(id))
		return


	removeAt: (index, count) ->
		@remove(@findAllAt(index, count))
		return


	removeAll: (silent) ->
		if @data.length > 0
			@clear()
			@emit("datachanged", this)
			@emit("removeall", this) unless silent
		return


	remove: (recs) ->
		changed = false

		for rec in Array.from(recs)
			rec.unjoinStore(this)
			index = @indexOf(rec)
			@data.erase(rec)
			@newRecords.erase(rec)
			@updatedRecords.erase(rec)
			@removedRecords.include(rec)
			@emit('remove', this, rec, index)
			if @filtered and @getFilters().match(rec) then @filteredData.erase(rec)
			changed = true

		if changed
			@emit("datachanged", this)
		return


	clear: ->
		for rec in @data
			rec.unjoinStore(this)
		if @filtered
			@filteredData.empty()
		@data.empty()
		return


	#//////////////////////////////////////////////////////////////////////////////////////////////
	# Data loading from proxy


	load: (options = {}, done = null) ->
		if !@proxy
			throw new Error("Cant load data, proxy is missing in store")

		if options.once && @loaded
			miwo.async => done(this, @data, true) if done
			return

		if @loading
			return

		options.params = Object.merge({}, @params, options.params)
		options.offset = (if (options.offset isnt `undefined`) then options.offset else ((if options.page then options.page - 1 else 0)) * @pageSize)
		options.limit = options.limit or @pageSize
		options.filters = if @storeFilters then @storeFilters.getAll() else null
		options.sorters = if @storeSorters then @storeSorters.getAll() else null
		options.addRecords = options.addRecords or false
		options.recordFactory = @bound("createRecord")

		@emit("beforeload", this, options)
		@loading = true
		@page = (if @pageSize then Math.max(1, Math.ceil(options.offset / @pageSize) + 1) else 1)

		@proxy.read options, (operation) =>
			response = operation.getResponse()
			records = operation.getRecords()
			successful = operation.wasSuccessful()
			@loadRecords(records, true) if successful
			@totalCount = response.total if response
			@loading = false
			@loaded = true
			@emit("load", this, records, successful)
			done(this, records, successful) if done
		return


	reload: (done)->
		@load({page: @page}, done)
		return


	loadPage: (page, done) ->
		return  unless @pageSize
		@page = Math.max(1, Math.min(page, Math.ceil(@totalCount / @pageSize)))
		@load({page: @page}, done)
		return


	loadPrevPage: (done) ->
		return  unless @pageSize
		@page = Math.max(1, @page - 1)
		@load({page: @page}, done)
		return


	loadNextPage: (done) ->
		return  unless @pageSize
		@page = Math.min(@page + 1, Math.ceil(@totalCount / @pageSize))
		@load({page: @page}, done)
		return


	loadNestedPage: (type, done)->
		if type is 'prev'
			@loadPrevPage(done)
		else if type is 'next'
			@loadNextPage(done)
		return


	#//////////////////////////////////////////////////////////////////////////////////////////////
	# Synchronize


	resumeAutoSync: ->
		@autoSyncSuspended = true
		return


	suspendAutoSync: ->
		@autoSyncSuspended = false
		return


	# Synchronizuje data so serverom
	# @option success {Function(this, op)} Success callback
	# @option error {Function(this, op)} Error callback
	# @param @param {Object} [options]
	sync: (options = {}) ->
		if !@proxy
			return

		toCreate = @getNewRecords()
		toUpdate = @getUpdatedRecords()
		toDestroy = @getRemovedRecords()
		operations = {}
		needsSync = false

		if toCreate.length > 0
			operations.create =
				records: toCreate
				callback: @createProxyCallback("onProxyCreateCallback", options)
			needsSync = true

		if toUpdate.length > 0
			operations.update =
				records: toUpdate
				callback: @createProxyCallback("onProxyUpdateCallback", options)
			needsSync = true

		if toDestroy.length > 0
			operations.destroy =
				records: toDestroy
				callback: @createProxyCallback("onProxyDestroyCallback", options)
			needsSync = true

		if needsSync
			operations.preventSync = false
			@emit("beforesync", operations)
			@proxy.execute(operations, {recordFactory: @bound("createRecord")})  if !operations.preventSync
		return


	createProxyCallback: (name, options) ->
		return (op) =>
			@emit("sync", this, op)
			if op.wasSuccessful()
				@emit("success", this, op)
				this[name]()
				if Type.isObject(options)
					if options.success then options.success(this, op)
				else
					options(this, op)
			else
				@emit("failure", this, op)
				if Type.isObject(options)
					if options.failure then options.failure(this, op)
				else
					options(this, op)


	onProxyCreateCallback: ->
		@newRecords.empty()
		@onProxyCallback()
		@emit("created", this)
		return


	onProxyUpdateCallback: ->
		@updatedRecords.empty()
		@onProxyCallback()
		@emit("updated", this)
		return


	onProxyDestroyCallback: ->
		@removedRecords.empty()
		@onProxyCallback()
		@emit("destroyed", this)
		return


	onProxyCallback: ->
		@emit("synced", this)
		@reload()  if @autoSyncReload
		return


	#//////////////////////////////////////////////////////////////////////////////////////////////
	# Sorting


	getSorters: () ->
		if !@storeSorters
			@storeSorters = new StoreSorters(this)
		return @storeSorters


	#//////////////////////////////////////////////////////////////////////////////////////////////
	# Filtering


	getFilters: () ->
		if !@storeFilters
			@storeFilters = new StoreFilters(this)
		return @storeFilters



	#//////////////////////////////////////////////////////////////////////////////////////////////
	# Records handling


	afterEdit: (record, modifiedFieldNames) ->
		@updatedRecords.include(record)

		if @proxy and @autoSync and !@autoSyncSuspended
			for name in modifiedFieldNames
				# only sync if persistent fields were modified
				if record.fields[name].persist
					shouldSync = true
					break
			if shouldSync
				@sync()

		if @sortOnEdit && !@remoteSort && @storeSorters && @storeSorters.has()
			@storeSorters.apply(true) # silent

		if @filterOnEdit && !@remoteFilter && @storeFilters && @storeFilters.has()
			@storeFilters.apply(true) # silent

		@emit("update", this, record, "edit", modifiedFieldNames)
		return


	afterReject: (record) ->
		@emit("update", this, record, "reject", null)
		return


	afterCommit: (record) ->
		@emit("update", this, record, "commit", null)
		return


module.exports = Store
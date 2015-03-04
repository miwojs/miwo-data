Types = require './Types'


class Record extends Miwo.Events

	isRecord: true
	idProperty: "id"
	_phantom: false
	_editing: false
	_dirty: false
	_data: null
	_modified: null
	_stores: null
	_store: null
	_raw: null
	fields: null

	# This object is used whenever the set() method is called and given a string as the
	# first argument. This approach saves memory (and GC costs) since we could be called
	# a lot.
	_singleProp: {}

	@getter 'phantom', -> @_phantom


	@field: (name, config) ->
		if @prototype[name]
			throw new Error("Property #{name} is already used. Please use other field name")

		if !@prototype._fields
			@prototype._fields = {}
		@prototype._fields[name] = config

		Object.defineProperty @prototype, name,
			get: -> return @get(name)
			set: (value) -> @set(name, value)
		return


	constructor: (data = {}, source = null) ->
		@_data = {}
		@_stores = []
		@_raw = data
		@fields = {}

		if !source
			@setup(data)
		else
			@copy(source)

		# initialize
		@_modified = {}
		@_dirty = false
		@_phantom = !(@getId() or @getId() is 0)
		@init()
		return


	init: () ->
		return


	setup: (data) ->
		# configure fields
		for name,field of @_fields
			type = field.type or "string"
			if !Types[type]
				throw new Error("Record::initialize(): undefined type " + type)
			@fields[name] = Object.merge {}, Types[type],
				name: name
				def: (if field.def isnt undefined then field.def else null)
				nullable: (if field.nullable isnt undefined then field.nullable else null)
				persist: (if field.persist isnt undefined then field.persist else true)

		# load fields data
		for name,field of @fields
			value = data[name]
			value = field.def  if value is undefined
			value = field.convert(value, this)  if field.convert
			# On instance construction, do not create data properties based on undefined input properties
			if value isnt undefined
				@_data[name] = value
				@onValueChanged(name, value, null)
		return


	copy: (source) ->
		@fields = source.fields
		@_data = source.data
		return


	###*
	  Creates a copy (clone) of this Record instance.
	  @return {Miwo.data.Record}
	  ###
	clone: (newId) ->
		source = Object.merge({}, {fields: @fields, data: @_data})
		source.data[@idProperty] = newId
		new @constructor(@_raw, source) # todo test


	###*
	  Get value from record
	  @param name
	  @returns {mixed}
	  ###
	get: (name) ->
		getter = "get" + name.capitalize()
		return if this[getter] then this[getter]() else @_data[name]


	###*
	  Sets the given field to the given value, marks the instance as dirty
	  @param {String/Object} fieldName The field to set, or an object containing key/value pairs
	  @param {Object} newValue The value to set
	  @return {String[]} The array of modified field names or null if nothing was modified.
	  ###
	set: (fieldName, newValue) ->
		single = Type.isString(fieldName)

		if single
			values = @_singleProp
			values[fieldName] = newValue
		else
			values = fieldName

		for name,value of values
			if !@fields[name]
				continue

			field = @fields[name]
			value = field.convert(value, this)  if field.convert
			currentValue = @_data[name]

			if @isEqual(currentValue, value) # new value is the same, so no change...
				continue

			@_data[name] = value
			@onValueChanged(name, value, currentValue)
			(modifiedFieldNames or (modifiedFieldNames = [])).push(name)

			if field.persist
				if @_modified[name]
					if @isEqual(@_modified[name], value)
						# The original value in me.modified equals the new value, so
						# the field is no longer modified:
						delete @_modified[name]
						# We might have removed the last modified field, so check to
						# see if there are any modified fields remaining and correct dirty
						@_dirty = Object.getLength(@_modified) > 0
				else
					@_dirty = true
					@_modified[name] = currentValue

			if name is @idProperty
				idChanged = true
				oldId = currentValue
				newId = value

		if single
			# cleanup our reused object for next time... important to do this before
			# we fire any events or call anyone else (like afterEdit)!
			delete values[fieldName]

		@emit("idchanged", this, oldId, newId)  if idChanged
		@afterEdit(modifiedFieldNames)  if !@_editing and modifiedFieldNames
		return modifiedFieldNames or null


	getId: ->
		return @_data[@idProperty]


	setId: (id) ->
		@set(@idProperty, id)
		@_phantom = !(id or id is 0)
		return


	updating: (callback) ->
		editing = @_editing
		@beginEdit() if !editing
		callback(@_data)
		@endEdit() if !editing
		return


	###*
	  Gets all values for each field in this model and returns an object containing the current data.
	  @return {Object} An object hash containing all the values in this model
	  ###
	getValues: ->
		values = {}
		for name,field of @fields then values[name] = @get(name)
		return values


	# Begins an edit. While in edit mode, no events (e.g.. the `update` event) are relayed to the containing store.
	# When an edit has begun, it must be followed by either {@link #endEdit} or {@link #cancelEdit}.
	beginEdit: ->
		if !@_editing
			@_editing = true
			@_dirtySaved = @_dirty
			@_dataSaved = {}
			@_modifiedSaved = {}
			@_dataSaved[key] = value  for key, value of @_data
			@_modifiedSaved[key] = value  for key,value of @_modified
		return


	# Cancels all changes made in the current edit operation.
	cancelEdit: ->
		if @_editing
			@_editing = false
			@_dirty = @_dirtySaved
			@_data = @_dataSaved
			@_modified = @_modifiedSaved
			delete @_dirtySaved
			delete @_dataSaved
			delete @_modifiedSaved
		return


	# Ends an edit. If any data was modified, the containing store is notified (ie, the store's `update` event will fire).
	# @param {Boolean} silent True to not notify the store of the change
	# @param {String[]} modifiedFieldNames Array of field names changed during edit.
	endEdit: (silent, modifiedFieldNames) ->
		if @_editing
			@_editing = false
			data = @_dataSaved
			delete @_modifiedSaved
			delete @_dataSaved
			delete @_dirtySaved
			if !silent
				modifiedFieldNames = @getModifiedFieldNames(data) if !modifiedFieldNames
				changed = @_dirty or modifiedFieldNames.length > 0
				if changed then @afterEdit(modifiedFieldNames)
		return


	# Gets the names of all the fields that were modified during an edit
	# @private
	# @param {Object} [values] The currently saved data. Defaults to the dataSave property on the object.
	# @return {String[]} An array of modified field names
	getModifiedFieldNames: (values) ->
		modified = []
		for key,value of @_data
			if !@isEqual(value, values[key])
				modified.push(key)
		return modified


	# Gets a hash of only the fields that have been modified since this Model was created or commited.
	# @return {Object}
	getChanges: ->
		changes = {}
		changes[name] = @get(name)  for name,value of @_modified
		return changes


	# Returns true if the passed field name has been `{@link #modified}` since the load or last commit.
	# @param {String} fieldName
	# @return {Boolean}
	isModified: (fieldName) ->
		return @_modified.hasOwnProperty(fieldName)


	# Checks if two values are equal, taking into account certain special factors, for example dates.
	# @private
	# @param {Object} a The first value
	# @param {Object} b The second value
	# @return {Boolean} True if the values are equal
	isEqual: (a, b) ->
		if Type.isObject(a) and Type.isObject(b)
			if Object.getLength(a) isnt Object.getLength(b)
				return false
			else
				for x of a then if b[x] isnt a[x] then return false
				return true
		else if Type.isDate(a) and Type.isDate(b)
			return a.getTime() is b.getTime()
		else
			return a is b


	# Marks this **Record** as `{@link #dirty}`. This method is used interally when adding `{@link #phantom}` records
	# to a {@link Ext.data.proxy.Server#writer writer enabled store}.
	# Marking a record `{@link #dirty}` causes the phantom to be returned by {@link Ext.data.Store#getUpdatedRecords}
	# where it will have a create action composed for it during {@link Ext.data.Model#save model save} operations.
	setDirty: ->
		@_dirty = true
		for name,field of @fields
			if field.persist
				@_modified[name] = @get(name)
		return


	# Usually called by the {@link Ext.data.Store} to which this model instance has been {@link #join joined}. Rejects
	# all changes made to the model instance since either creation, or the last commit operation. Modified fields are
	# reverted to their original values.
	#
	# Developers should subscribe to the {@link Ext.data.Store#event-update} event to have their code notified of reject operations.
	#
	# @param {Boolean} silent (optional) True to skip notification of the owning store of the change.
	reject: (silent = false) ->
		for name,value of @_modified
			@_data[name] = value
		@_dirty = false
		@_editing = false
		@_modified = {}
		if !silent then @afterReject()
		return


	# Usually called by the {@link Miwo.data.Store} which owns the model instance. Commits all changes made to the
	# instance since either creation or the last commit operation.
	# @param {Boolean} silent (optional) True to skip notification of the owning store of the change.
	commit: (silent = false) ->
		@_phantom = @_dirty = @_editing = false
		@_modified = {}
		if !silent then @afterCommit()
		return


	###*
	  Tells this model instance that it has been added to a store.
	  @param {Ext.data.Store} store The store to which this model has been added.
	  ###
	joinStore: (store) ->
		@_stores.include(store)
		@_store = @_stores[0] # compat w/all releases ever
		return


	###*
	  Tells this model instance that it has been removed from the store.
	  @param {Ext.data.Store} store The store from which this model has been removed.
	  ###
	unjoinStore: (store) ->
		@_stores.erase(store)
		@_store = @_stores[0] or null # compat w/all releases ever
		return


	isStored: ->
		return @_store isnt null


	isPhantom: ->
		return @_phantom


	###*
	  @private
	  If this Model instance has been {@link #join joined} to a {@link Ext.data.Store store}, the store's
	  afterEdit method is called
	  @param {String[]} modifiedFieldNames Array of field names changed during edit.
	  ###
	afterEdit: (modifiedFieldNames) ->
		@emit("edit", this, modifiedFieldNames)
		@callStore("afterEdit", this, modifiedFieldNames)
		return


	# @private
	# If this Model instance has been {@link #join joined} to a {@link Ext.data.Store store}, the store's
	# afterReject method is called
	afterReject: ->
		@callStore("afterReject", this)
		return


	# @private
	# If this Model instance has been {@link #join joined} to a {@link Ext.data.Store store}, the store's
	# afterCommit method is called
	afterCommit: ->
		@callStore("afterCommit", this)
		return


	# @private
	# Helper function used by afterEdit, afterReject and afterCommit. Calls the given method on the
	# {@link Miwo.data.Store store} that this instance has {@link #join joined}, if any. The store function
	# will always be called with the model instance as its single argument.
	# @param {String} fn The function to call on the store
	callStore: (fn, args...) ->
		for store in @_stores
			if store[fn]
				store[fn].apply(store, args)
		return


	# override
	onValueChanged: (name, value, oldvalue) ->
		return



module.exports = Record

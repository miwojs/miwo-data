Operation = require './Operation'


class Proxy extends Miwo.Object

	isProxy: true
	name: undefined
	headers: null
	secure: true
	defaults: null
	api: null


	constructor: (config) ->
		@defaults =
			timeout: 0
			async: true
		@api =
			create: undefined
			read: undefined
			update: undefined
			destroy: undefined

		if config.url
			@api.read = @url
			delete config.url

		super(config)
		return


	setAsync: (async) ->
		@defaults.async = async
		return


	execute: (operations, config) ->
		if operations.destroy
			@executeOperations('destroy', operations.destroy, config)
		if operations.create
			@executeOperations('create', operations.create, config)
		if operations.update
			@executeOperations('update', operations.update, config)
		return


	executeOperations: (action, operations, config) ->
		opc = Object.append({}, config)
		Object.append(opc, {records: operations.records})
		@[action](opc, operations.callback)
		return


	read: (config, callback) ->
		@doRequest(@createOperation('read', config), callback)
		return


	create: (config, callback) ->
		@doRequest(@createOperation('create', config), callback)
		return


	update: (config, callback) ->
		@doRequest(@createOperation('update', config), callback)
		return


	destroy: (config, callback) ->
		@doRequest(@createOperation('destroy', config), callback)
		return


	createOperation: (action, config) ->
		op = new Operation(config)
		op.action = action
		return op


	# @param {Miwo.data.Operation} operation
	# @param {function} callback
	doRequest: (operation, callback) ->
		request = miwo.http.createRequest()

		options = Object.merge({}, @defaults)
		options.method = "POST"
		options.headers = @headers
		options.url = @api[operation.action]
		options.data = @createRequestData(operation)
		options.onComplete = ->
			operation.setCompleted()
			return
		options.onRequest = ->
			operation.running = true
			return
		options.onSuccess = (response) =>
			@processResponse(true, operation, request, response, callback)
			return
		options.onFailure = =>
			@processResponse(false, operation, request, null, callback)
			return
		if operation.async isnt undefined
			options.async = operation.async

		operation.started = true
		request.setOptions(options)
		request.send()
		return


	createRequestData: (operation) ->
		data = {}
		data.action = operation.action
		switch operation.action
			when "create"
				data.data = @createOperationData(operation, 'create')
			when "destroy"
				data.data = @createOperationData(operation, 'destroy')
			when "update"
				data.data = @createOperationData(operation, 'update')
			when "read"
				data.filters = @createItemsData(operation.filters)  if operation.filters
				data.sorters = @createItemsData(operation.sorters)  if operation.sorters
				data.offset = operation.offset  if operation.offset
				data.limit = operation.limit  if operation.limit
				Object.expand(data, operation.params)  if operation.params
		return data


	createItemsData: (items) ->
		data = []
		for item in items
			data.push(item.toData())
		return data


	createOperationData: (operation, mode) ->
		if !operation.getRecords()
			throw new Error("operation has no records")

		data = []
		for record in operation.getRecords()
			if mode is 'create'
				data.push(record.getValues())
			else if mode is 'update'
				changes = record.getChanges()
				changes[record.idProperty] = record.getId()
				data.push(changes)
			else if mode is 'destroy'
				data.push(record.getId())

		return JSON.encode(data)


	processResponse: (success, operation, request, response, callback) ->
		if !success
			xhr = request.xhr
			operation.setException(xhr.responseText, xhr.status)
		else
			if !response.success
				operation.setException(response.error, response.code)
			else
				operation.setSuccessful()
				operation.response = response
				@commitOperation(operation, response.records)
		callback(operation)
		return


	commitOperation: (operation, records) ->
		switch operation.action
			when "create"
				for data,index in records
					record = operation.records[index]
					record.set(data)
					record.commit()

			when "update"
				for data in records
					for record in operation.records
						if record.getId() is data.id
							record.set(data)
							record.commit()
							break

			when "read"
				operation.records = []
				for data in records
					record = operation.createRecord(data)
					operation.records.push(record)
		return



module.exports = Proxy
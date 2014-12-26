Record = require './Record'


class Operation extends Miwo.Object

	###*
	  @cfg {String} async
	  Execute this operation asynchronously. Defaults by proxy settings
	  ###
	async: `undefined`

	###*
	  @cfg {String} action
	  The action being performed by this Operation. Should be one of 'create', 'read', 'update' or 'destroy'.
	  ###
	action: `undefined`

	###*
	  @cfg {Miwo.data.Filter[]} filters
	  Optional array of filter objects. Only applies to 'read' actions.
	  ###
	filters: `undefined`

	###*
	  @cfg {Miwo.data.Sorter[]} sorters
	  Optional array of sorter objects. Only applies to 'read' actions.
	  ###
	sorters: `undefined`

	###*
	  @cfg {Number} start
	  The start index (offset), used in paging when running a 'read' action.
	  ###
	offset: `undefined`

	###*
	  @cfg {Number} limit
	  The number of records to load. Used on 'read' actions when paging is being used.
	  ###
	limit: `undefined`

	###*
	  @cfg {Object} params
	  Parameters to pass along with the request when performing the operation.
	  ###
	params: `undefined`

	###*
	  @cfg {Function} callback
	  Function to execute when operation completed.
	  @cfg {Ext.data.Model[]} callback.records Array of records.
	  @cfg {Ext.data.Operation} callback.operation The Operation itself.
	  @cfg {Boolean} callback.success True when operation completed successfully.
	  ###
	callback: `undefined`

	###*
	  @property {Boolean} started
	  The start status of this Operation. Use {@link #isStarted}.
	  @readonly
	  @private
	  ###
	started: false

	###*
	  @property {Boolean} running
	  The run status of this Operation. Use {@link #isRunning}.
	  @readonly
	  @private
	  ###
	running: false

	###*
	  @property {Boolean} complete
	  The completion status of this Operation. Use {@link #isComplete}.
	  @readonly
	  @private
	  ###
	complete: false

	###*
	  @property {Boolean} success
	  Whether the Operation was successful or not. This starts as undefined and is set to true
	  or false by the Proxy that is executing the Operation. It is also set to false by {@link #setException}. Use
	  {@link #wasSuccessful} to query success status.
	  @readonly
	  @private
	  ###
	success: `undefined`

	###*
	  @property {Boolean} exception
	  The exception status of this Operation. Use {@link #hasException} and see {@link #getError}.
	  @readonly
	  @private
	  ###
	exception: false

	###*
	  @property {String/Object} error
	  The error object passed when {@link #setException} was called. This could be any object or primitive.
	  @private
	  ###
	error: `undefined`

	###*
	  @property {String/Object} error
	  Error code
	  @private
	  ###
	code: `undefined`

	###*
	  @cfg {Miwo.data.Record[]} records
	  ###
	records: `undefined`

	###*
	  @property {Object} response
	  ###
	response: `undefined`

	###*
	  @cfg {function} recordFactory
	  ###
	createRecord: `undefined`


	constructor: (config) ->
		super(config)
		if config.recordFactory
			@createRecord = config.recordFactory
		else
			@createRecord = (values) -> new Record(values)
		return


	###*
	  Set records facotry callback
	  @param {Function} callback
	  ###
	setRecordFactory: (callback) ->
		@createRecord = callback
		return


	###*
	  Returns response from server (JSON object)
	  @return {Object}
	  ###
	getResponse: ->
		return @response


	###*
	  Returns operations records
	  @return {Miwo.data.Record[]}
	  ###
	getRecords: ->
		return @records


	###*
	  Returns first record in record set
	  @return {Miwo.data.Record}
	  ###
	getRecord: ->
		return (if @records and @records.length > 0 then @records[0] else null)


	###*
	  Marks the Operation as completed.
	  ###
	setCompleted: ->
		@complete = true
		@running = false
		return


	###*
	  Marks the Operation as successful.
	  ###
	setSuccessful: ->
		@success = true
		return


	###*
	  Marks the Operation as having experienced an exception. Can be supplied with an option error message/object.
	  @param {String/Object} error (optional) error string/object
	  ###
	setException: (error, code) ->
		@exception = true
		@success = false
		@running = false
		@error = error
		@code = code
		return


	###*
	  Returns true if this Operation encountered an exception (see also {@link #getError})
	  @return {Boolean} True if there was an exception
	  ###
	hasException: ->
		return @exception is true


	###*
	  Returns the error string or object that was set using {@link #setException}
	  @return {String/Object} The error object
	  ###
	getError: ->
		return @error


	###*
	  Returns code
	  @return {String/Object} The response code
	  ###
	getCode: ->
		return @code


	###*
	  Returns true if the Operation has been started. Note that the Operation may have started AND completed, see
	  {@link #isRunning} to test if the Operation is currently running.
	  @return {Boolean} True if the Operation has started
	  ###
	isStarted: ->
		return @started is true


	###*
	  Returns true if the Operation has been started but has not yet completed.
	  @return {Boolean} True if the Operation is currently running
	  ###
	isRunning: ->
		return @running is true


	###*
	  Returns true if the Operation has been completed
	  @return {Boolean} True if the Operation is complete
	  ###
	isComplete: ->
		return @complete is true


	###*
	  Returns true if the Operation has completed and was successful
	  @return {Boolean} True if successful
	  ###
	wasSuccessful: ->
		return @isComplete() and @success is true



module.exports = Operation
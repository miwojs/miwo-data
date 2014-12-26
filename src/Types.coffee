Types =

	stripRe: /[\$,%]/g

	# @property {Object} STRING
	# This data type means that the raw data is converted into a String before it is placed into a Record.
	string:
		type: "string"
		convert: (v) ->
			defaultValue = (if @nullable then null else "")
			return (if (v is `undefined` or v is null) then defaultValue else String(v))


	# @property {Object} INT
	# This data type means that the raw data is converted into an integer before it is placed into a Record.
	int:
		type: "int"
		convert: (v) ->
			return (if v isnt `undefined` and v isnt null and v isnt "" then parseInt(String(v).replace(Types.stripRe, ""), 10) else ((if @nullable then null else 0)))


	# @property {Object} FLOAT
	# This data type means that the raw data is converted into a number before it is placed into a Record.
	float:
		type: "float"
		convert: (v) ->
			return (if v isnt `undefined` and v isnt null and v isnt "" then parseFloat(String(v).replace(Types.stripRe, ""), 10) else ((if @nullable then null else 0)))


	# @property {Object} BOOLEAN
	# <p>This data type means that the raw data is converted into a boolean before it is placed into
	# a Record. The string "true" and the number 1 are converted to boolean <code>true</code>.</p>
	boolean:
		type: "boolean"
		convert: (v) ->
			if @nullable and (v is `undefined` or v is null or v is "")
				return null
			return v is true or v is "true" or v is 1


	# @property {Object} DATE
	# This data type means that the raw data is converted into a Date before it is placed into a Record.
	date:
		type: "date"
		convert: (v) ->
			parsed = undefined
			return null  if !v
			return v  if Type.isDate(v)
			parsed = Date.parse(v)
			return (if parsed then new Date(parsed) else null)


	json:
		type: "json"
		convert: (v) ->
			if !v
				return {}
			else if Type.isString(v)
				return  JSON.decode(v)
			else
				return v

	array:
		type: "array"
		convert: (v) ->
			if !v
				return null
			else if Type.isArray(v)
				return v
			else if Type.isString(v)
				return v.split ";"
			else
				return Array.from(v)


module.exports = Types
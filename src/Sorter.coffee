class Sorter extends Miwo.Object

	name: null
	dir: null


	compare: (a, b) ->
		if Type.isFunction(@dir)
			return @dir(a, b)
		else
			aVal = a.get(@name)
			bVal = b.get(@name)
			sign = (if @dir is "desc" then -1 else 1)
			if Type.isDate(aVal) and Type.isDate(bVal)
				if aVal - bVal > 0 then return sign
				if aVal - bVal < 0 then return -sign
			else
				if aVal > bVal then return sign
				if aVal < bVal then return -sign
			return null


	toData: ->
		name: @name
		dir: @dir


module.exports = Sorter
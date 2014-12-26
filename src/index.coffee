Miwo.data =
	Record: require './Record'
	Entity: require './Entity'
	Proxy: require './Proxy'
	Store: require './Store'
	Types: require './Types'
	Filter: require './Filter'
	Sorter: require './Sorter'


Miwo.Store = Miwo.data.Store
Miwo.Record = Miwo.data.Record
Miwo.Entity = Miwo.data.Entity
Miwo.Proxy = Miwo.data.Proxy


miwo.registerExtension('miwo-data', require './DiExtension')
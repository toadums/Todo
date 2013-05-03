class todoItem 

	@num: 0

	constructor: (descr, id, status) ->

		switch arguments.length
			when 1
				@description = descr
				@ID = todoItem.num++
				@isFinished = false
			when 3
				@description = descr
				@ID = id
				if status == 'true' || status == 1
					@isFinished = true
				@isFinished = status 
				todoItem.num = (Math.max todoItem.num, id) + 1
	
	next: null

	#print the task in a human readable format
	info: ->
		return @ID + ": " + @description + ": " + if @isFinished then "Finished" else "Not Finished"

	#print the data in an array
	data: ->
		return [@ID, @description, @isFinished]

module.exports = todoItem
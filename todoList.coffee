# Todolist.coffee
#
# What I am doing is keeping a pointer to the complete items, and a pointer to the incomplete items.
# I am also making the complete items be pointed to by the @incompleteTail variable, so that you can start at the
# incomplete head, and iterate over all items (complete and incomplete)
#
# this line shows up a lot: 	temp = if @incomplete then @incomplete else @complete
# what it is doing is choosing the head to start iterating over (always @incomplete if it is not null)

node = require './todoItem'
fs = require 'fs'
_ = require 'underscore'

#Holds the heads /tail of the todolist. Also has the methods to manipulate the list
class todoList
	
	#head to incomplete items
	@incomplete: null
	#basically just points to the head of the complete items, so we only need one while loop when iterating over the list
	@incompleteTail: null
	#head pointer to the complete items
	@complete: null

	#constructor just loads an existing list
	constructor: ()->
		this.load()

	#add a new item to the list. This method is overloaded so you can add a new item (just the description)
	#or an existing item (descr, id, finished/not finished). It is called by Add, load, and switch
	add: (descr, id, finished) ->
		newItem = null

		switch arguments.length
			when 1
				newItem = new node descr
			when 3
				newItem = new node descr, id, finished		

		if(!newItem?)
			return


		#adding new item
		if(!newItem.isFinished)
			#if no head yet, create a new head
			if(!@incomplete?)
				@incomplete = newItem
				@incompleteTail = newItem
				#update pointer to the complete items
				if @complete then @incompleteTail.next = @complete
			else
				#if there is a head, just add a new head, and point it to the old one
				newItem.next = @incomplete
				@incomplete = newItem
		else
			#same as above, but for complete items
			if(!@complete?)
				@complete = newItem
			else
				newItem.next = @complete
				@complete = newItem
			#update the tail pointer to point to the new head
			if(@incompleteTail?)
				@incompleteTail.next = @complete

		this.save()

		return newItem

	generateJSON: () ->
		#pick head
		temp = if @incomplete then @incomplete else @complete
		i = 0
		arr = []
		#foreach node, just print its info
		while(temp?)
			arr[i++] = temp.data()
			temp = temp.next

		return arr

	#print formatted string
	print: () ->
		#pick head
		temp = if @incomplete then @incomplete else @complete

		#foreach node, just print its info
		while(temp?)
			console.log temp.info()
			temp = temp.next

	#return the node with ID = ID
	getByID: (ID) ->
		#pick head
		temp = if @incomplete then @incomplete else @complete

		#iterate over list and return the node if it is found
		while(temp?)
			if(temp.ID == ID)
				return temp
			temp = temp.next

		return null

	#removes the node with ID = ID. This is called by switch
	remove: (temp) ->

		if(!temp?)
			return null

		#depending on where the node is in the list, we need to do different things
		if(temp == @incomplete && temp == @incompleteTail)
			@incomplete = null
			@incompleteTail = null
		else if(temp == @incomplete)
			@incomplete = temp.next
		else if(temp == @complete)
			@complete = temp.next
			if(@incompleteTail?)
				@incompleteTail.next = @complete
		else
			#this is the only confusing one, so I will explain it:
			# o we know the node isn't at the front, so there is a node before it. The while loop finds it
			# o set its next to the one after temp
			# o change incomplete tail if necessary
			iter = if @incomplete then @incomplete else @complete
			while(iter?)

				if(iter.next == temp)
					break
				iter = iter.next

			if(iter != null)
				iter.next = temp.next

			if(temp == @incompleteTail)
				@incompleteTail = iter
				@incompleteTail.next = @complete

		this.save()
	#toggles a node complete/uncomplete
	switch: (ID, complete) ->
		#get the node
		temp = this.getByID(ID)

		if(!temp?)
			return

		#we don't want to uncomplete an incomplete node, return.
		if(temp.isFinished == complete)
			return

		this.remove(temp)

		temp.isFinished = !temp.isFinished
		#readd the removed node, this will insert it into the correct position
		this.add(temp.description, temp.ID, temp.isFinished)

	#save the tree to the file "log"
	save: () -> 

		data = ""
		#there is nothing in the list. Wipe the log file
		if(!@incompleteTail? && !@incomplete? && !@complete?)
			fs.unlink 'log', ()->
			return

		temp = if @incomplete then @incomplete else @complete

		while(temp?)
			data += JSON.stringify(temp.data()) + '\n'
			temp = temp.next
		fs.writeFile 'log', data, ()->
		
	#load the log file
	load: () ->
		fs.readFile 'log', 'utf-8', (err, data) =>

			if err
				if err.code == 'ENOENT'
					return
				else 
					throw err

			lines = data.trim().split('\n')
			#iterate over each line, add a new task for each
			_.each(lines.reverse(), (line)=>
				if line.trim() != ""
					elements = JSON.parse(line)
					if(elements.length == 3)
						this.add elements[1], elements[0], elements[2]
			)

module.exports = todoList





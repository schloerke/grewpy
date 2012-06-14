
type_of = null
do ->
  array_ctor = (new Array).constructor
  date_ctor  = (new Date).constructor
  regex_ctor = (new RegExp).constructor
  type_of = (v) ->
    if typeof(v) is 'object'
      return 'null'  if v == null
      return 'array' if v.constructor == array_ctor
      return 'date'  if v.constructor == date_ctor
      return 'object'
    else
      return 'regex' if v?.constructor == regex_ctor
      return typeof(v)


EventEmitter = require('events').EventEmitter
worker_args_to_status = (args) ->
  wrong_format = ->
    throw "'worker()' must be called with the following format: grewpy.worker([workerCount], [arrayOfFns], [callback])"

  cb          = null
  fns         = []
  isClosed    = false
  workerCount = -1
  events = new EventEmitter()

  set_arg_to_value = (arg) ->
    switch type_of(arg)
      when "array"
        fns = arg
      when "function"
        cb = arg
      when "number"
        workerCount = arg
      else
        wrong_format()
    return


  switch args.length
    when 0
      # carry on
      isClosed = false

    when 1
      isClosed  = false
      firstItem = args[0]

      set_arg_to_value(firstItem)

    when 2
      firstItem = args[0]
      secItem   = args[1]

      if type_of(firstItem) is type_of(secItem)
        throw "arguments 0 and 1 have the same type: #{ type_of(firstItem) }"

      set_arg_to_value(firstItem)
      set_arg_to_value(secItem)

    when 3
      firstItem = args[0]
      secItem   = args[1]
      thirdItem = args[2]

      if type_of(firstItem) is type_of(secItem)
        throw "arguments 0 and 1 have the same type: #{ type_of(firstItem) }"
      if type_of(firstItem) is type_of(thirdItem)
        throw "arguments 1 and 2 have the same type: #{ type_of(secItem) }"
      if type_of(secItem) is type_of(thirdItem)
        throw "arguments 2 and 3 have the same type: #{ type_of(secItem) }"

      set_arg_to_value(firstItem)
      set_arg_to_value(secItem)
      set_arg_to_value(thirdItem)

    else
      wrong_format()

  isClosed = (cb?) and (fns.length > 0)

  results = []
  return {
    cb
    fns
    results
    events
    workerCount
    foundError: null
    isClosed
    startedCount: 0
    storedCount: 0

    can_add_worker: ->
      # dont add if there are no more to add
      if this.startedCount is this.fns.length
        return false

      # parallel
      if workerCount < 0
        return true

      # worker chain
      return (this.startedCount - this.storedCount) < this.workerCount

    store: (item, pos) ->
      this.storedCount++
      this.results[pos] = item
      return

    has_more: ->
      return this.storedCount < this.fns.length

    is_finished: ->
      return (this.storedCount is this.fns.length) and this.isClosed

    call_cb: ->
      this.cb?(this.foundError, this.results)
      return

    call_or_set_error: (e) ->
      if this.cb
        this.foundError ?= e
        this.cb(e, this.results)
      else
        this.foundError = e
      return

  }







exports.worker = (args...) ->

  status = worker_args_to_status(args)
  events = status.events

  # if there is nothing to do, return early
  if status.isClosed and status.fns.length is 0
    status.call_cb()
    return {
      status
      events
    }


  call_fn = (fnPos, fn) ->
    if status.foundError
      return

    events.emit("worker_started", fnPos)

    done = (err, result) ->
      events.emit("worker_finished", fnPos, err, result)
      return

    try
      fn(done)
    catch err
      events.emit("worker_finished", fnPos, err, null)
    return


  events.on "worker_started", (pos) ->
    status.startedCount++
    return

  events.on "worker_finished", (pos, err, result) ->
    if status.foundError
      return

    if err?
      status.call_or_set_error(err)
      return

    # increments storedCount
    status.store(result, pos)

    if status.is_finished()
      status.call_cb()
    else if status.can_add_worker()
      call_fn(status.startedCount, status.fns[status.startedCount])
    return

  # this is run before group.add may be executed
  for fn, fnPos in status.fns
    if status.can_add_worker()
      # call function right away
      events.emit("fn_added", fnPos)
      call_fn(fnPos, fn)
    else
      break

  return {
    status
    events
    add: (fn) ->
      return if status.isClosed

      fnsLen = status.fns.push(fn)
      fnPos = fnsLen - 1

      if status.can_add_worker()
        events.emit("fn_added", fnPos)
        # call fn right away
        call_fn(fnPos, fn)
      else
        events.emit("fn_queued", fnPos)
      return

    finalize: (cb) ->
      status.isClosed = true


      if cb
        unless type_of(cb) is "function"
          throw "callback supplied is not a function"

        status.cb = cb
        if status.foundError
          status.call_cb()
          return

      unless type_of(status.cb) is "function"
        throw "no callback fuction to execute"

      # if not more functions need to return, call cb
      if status.is_finished()
        status.call_cb()
        return

      return
  }



exports.group_worker = (args...) ->
  args.push(-1)
  return exports.worker.apply(null, args)


exports.chain_worker = (args...) ->
  args.push(1)
  return exports.worker.apply(null, args)














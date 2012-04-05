



wrong_format_for = (fnTitle) ->
  return ->
    throw "#{ fnTitle } must be called with the following format: grewpie.#{ fnTitle }([arrayOfFns], [callback])"

args_to_status = (title, args) ->
  wrong_format = wrong_format_for(title)

  cb       = null
  fns      = []
  isClosed = false

  switch args.length
    when 0
      # carry on
      isClosed = false

    when 1
      isClosed  = false
      firstItem = args[0]

      if Array.isArray(firstItem)
        fns = firstItem
      else if typeof firstItem is "function"
        cb = firstItem
      else
        wrong_format()

    when 2
      isClosed  = true
      firstItem = args[0]
      secItem   = args[1]

      if Array.isArray(firstItem)
        fns = firstItem
      else
        wrong_format()

      if typeof secItem is "function"
        cb = secItem
      else
        wrong_format()


    else
      wrong_format()


  results = []
  return {
    cb
    fns
    results
    isThinking: false
    foundError: null
    isClosed

    storedCount: 0
    store: (item, pos) ->
      this.storedCount++
      if pos?
        this.results[pos] = item
      else
        this.results.push(item)
      return


    has_more: ->
      return this.storedCount < this.fns.length

    is_finished: ->
      return (this.storedCount is this.fns.length) and this.cb and this.isClosed

    call_cb: ->
      this.cb(this.foundError, this.results)

    call_or_set_error: (e) ->
      if this.cb
        this.foundError ?= e
        this.cb(e, this.results)
      else
        this.foundError = e
      return

  }


#
#   Executes all functions in order, and a callback when all have completed
# or when an error has been detected.
#
#   The callback takes two arguments: an error (or null if no error occurred),
# and the results of the chain operation, in order.
#
exports.chain = (args...) ->

  status = args_to_status("chain", args)


  maybe_call_next = ->
    if status.isThinking or status.foundError
      return

    unless status.has_more()
      return

    done = (err, result) ->
      status.isThinking = false
      if err
        status.call_or_set_error(err)
        return

      status.store(result)

      if status.is_finished()
        status.call_cb()
        return

      maybe_call_next()
      return

    try
      status.isThinking = true;
      status.fns[status.results.length](done);
    catch e
      status.call_or_set_error(e)
      return
    return

  # get the party started
  if status.fns.length > 0
    maybe_call_next()

  if status.isClosed
    if status.fns.length is 0
      status.call_cb()

    return {
      status
    }

  else
    return {
      status
      add: (fn) ->
        return if status.isClosed

        status.fns.push(fn)
        maybe_call_next()
        return

      finalize: (cb) ->
        status.isClosed = true

        if cb
          status.cb = cb
          if status.foundError
            status.call_cb()
            return

        unless typeof status.cb is "function"
          throw "no callback supplied to a finalized grewp"

        if status.has_more()
          maybe_call_next()
        else if status.is_finished()
          status.call_cb()
        return
    }






#   Executes a group of functions concurrently, invoking a callback when all have completed
# or when an error occurs. Errors occur when an executed function throws an unhandled
# Error or when an error is passed to the callback.
#
#   Results are returned to the callback in the order that they are declared. The results
# of functions that complete after an error have occurred are discarded.
#
# group([function(done){ done(null, 1); }, function(done){ done(null, 2); }], function(err, results){});
#   or
# var g = group(function(err, results) {});
# g.add(function(done) { done(null, 1); });
# g.add(function(done) { done(null, 2); });
# g.finalize();
#   or
# var g = group();
# g.add(function(done) { done(null, 1); });
# g.add(function(done) { done(null, 2); });
# g.finalize(function(err, results) {});
#/
exports.group = (args...) ->
  status = args_to_status("group", args)

  call_fn = (fnPos, fn) ->
    if status.foundError
      return

    done = (err, result) ->
      if status.foundError
        return

      if err
        status.call_or_set_error(err)
        return

      status.store(result, fnPos)

      if status.is_finished()
        status.call_cb()
      return

    try
      fn(done)
    catch e
      status.call_or_set_error(e)
    return

  # this is run before group.add may be executed
  for fn, fnPos in status.fns
    # call all functions right away
    call_fn(fnPos, fn)


  if status.isClosed and status.fns.length is 0
    status.call_cb()

    return {
      status
    }
  else
    return {
      status
      add: (fn) ->
        return if status.isClosed

        fnsLen = status.fns.push(fn)

        # call fn right away
        call_fn(fnsLen - 1, fn)
        return

      finalize: (cb) ->
        status.isClosed = true

        if cb
          status.cb = cb
          if status.foundError
            status.call_cb()
            return

        unless typeof status.cb is "function"
          throw "no callback supplied to a finalized grewp"

        # if not more functions need to return, call cb
        if status.is_finished()
          status.call_cb()
          return

        return
    }


















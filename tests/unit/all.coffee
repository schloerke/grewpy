
grewpy = require('../../')


add_test = ({method, values, expectedTime, valuesTitle, timeout, formationState}) ->
  formationState or= 0

  unless grewpy[method]?
    throw "method not supported!"

  timeout ?= null

  methodTitle = [method, valuesTitle, timeout ? "null", "(" + formationState + ")"].join("_")

  fn = null
  calls = 0
  fn = (value) ->
    return (done) ->
      inner_fn = ->
        calls++
        done(null, value)
        return

      if timeout?
        setTimeout(inner_fn, timeout)
      else
        inner_fn()
      return

  fnArr = []
  for value in values
    fnArr.push(fn(value))



  exports[methodTitle] = (test) ->

    test.expect(5 + values.length)
    startTime = new Date()

    cb = (err, results) ->
      endTime = new Date()

      timeDiff = endTime.valueOf() - startTime.valueOf()
      timeIsOk = false
      if timeout
        if ((expectedTime * timeout) - (timeout / 2)) < timeDiff
          if ((expectedTime * timeout) + (timeout + 0 / 2)) > timeDiff
            timeIsOk = true
      else
        # make sure it executed under 5 millis
        timeIsOk = (timeDiff < 5)

      test.ok(timeIsOk, "finished in the proper amount of time")

      test.equals(err, null, "error isnt null")

      test.equals(calls, values.length, "finished the same amount of values")

      test.ok(Array.isArray(results), "results are an array")
      test.equals(results.length, values.length, "results are same length as values")
      for result, resultPos in results
        test.equals(result, values[resultPos], "result is same result at pos: #{ resultPos }")

      test.done();
      return


    switch formationState
      when "cb_start,fn_start"
        # one shot
        grewpy[method](fnArr, cb)

      when "cb_end,fn_start"
        # call after fns inited
        info = grewpy[method](fnArr)
        info.finalize(cb)

      when "cb_start,fn_add"
        # call after fns added
        info = grewpy[method](cb)
        for fn in fnArr
          info.add(fn)

        info.finalize()

      when "cb_end,fn_add"
        # call after fns added and cb added
        info = grewpy[method]()
        if info.events and false
          console.log("info: ", info)
          info.events.on "fn_added", (pos) ->
            console.log("fn_added at pos: ", pos)
            return

          info.events.on "worker_started", (pos) ->
            console.log("worker_started at pos: ", pos)
            return

          info.events.on "worker_finished", (pos, err, result) ->
            console.log("worker_finished at pos: ", pos, " err: ", err, " result: ", result)
            return

          info.events.on "fn_queued", (pos) ->
            console.log("fn_queued at pos: ", pos)
            return


        for fn in fnArr
          info.add(fn)

        info.finalize(cb)




      when "cb_end,fn_split"
        # call after fns inited and fns added and cb added
        splitPos  = Math.floor(fnArr.length / 2)
        beforeArr = fnArr.slice(0,splitPos)
        afterArr  = fnArr.slice(splitPos)

        info = grewpy[method](beforeArr)
        for fn in afterArr
          info.add(fn)

        info.finalize(cb)

      else
        throw "formationState #{ formationState } not valid"


  return

valueArr = [
  [[undefined, undefined, undefined, undefined] , "undefined"]
  [[null, null, null, null]                     , "null"]
  [["red", "green", "blue", "yellow"]           , "colors"]
  [["red", undefined, null, "yellow"]           , "mixedColors"]
]


grewpy.two_worker = (args...) ->
  args.push(2)
  return grewpy.worker.apply(null, args)


for timeout in [null, 50]
  for [values, valuesTitle] in valueArr
    for [method, expectedTime] in [
      ["chain", values.length]
      ["group", 1]
      ["two_worker", values.length / 2]
    ]
      for formationState in [
        "cb_start,fn_start"
        "cb_start,fn_add"
        "cb_end,fn_start"
        "cb_end,fn_add"
        "cb_end,fn_split"
      ]
        add_test {
          method
          values
          valuesTitle
          expectedTime
          timeout
          formationState
        }





grewpy = require('../../')


add_test = ({method, values, expectedTime, valuesTitle, timeout, formationState, workerCount}) ->
  formationState or= 0

  unless grewpy[method]?
    throw "method not supported!"

  timeout ?= null

  methodTitle = [method, valuesTitle, timeout ? "null", workerCount ? "null", "(" + formationState + ")"].join("_")

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


      when "cb_start,fn_start,workerA"
        # one shot
        grewpy[method](workerCount, fnArr, cb)
      when "cb_start,fn_start,workerB"
        # one shot
        grewpy[method](workerCount, cb, fnArr)
      when "cb_start,fn_start,workerC"
        # one shot
        grewpy[method](fnArr, workerCount, cb)
      when "cb_start,fn_start,workerD"
        # one shot
        grewpy[method](fnArr, cb, workerCount)
      when "cb_start,fn_start,workerE"
        # one shot
        grewpy[method](cb, fnArr, workerCount)
      when "cb_start,fn_start,workerF"
        # one shot
        grewpy[method](cb, workerCount, fnArr)

      when "cb_end,fn_start,workerA"
        # call after fns inited
        info = grewpy[method](workerCount, fnArr)
        info.finalize(cb)
      when "cb_end,fn_start,workerB"
        # call after fns inited
        info = grewpy[method](fnArr, workerCount)
        info.finalize(cb)

      when "cb_start,fn_add,workerA"
        # call after fns added
        info = grewpy[method](workerCount, cb)
        for fn in fnArr
          info.add(fn)

        info.finalize()
      when "cb_start,fn_add,workerB"
        # call after fns added
        info = grewpy[method](cb, workerCount)
        for fn in fnArr
          info.add(fn)

        info.finalize()

      when "cb_end,fn_add,workerA"
        # call after fns added and cb added
        info = grewpy[method](workerCount)
        for fn in fnArr
          info.add(fn)

        info.finalize(cb)


      when "cb_end,fn_split,workerA"
        # call after fns inited and fns added and cb added
        splitPos  = Math.floor(fnArr.length / 2)
        beforeArr = fnArr.slice(0,splitPos)
        afterArr  = fnArr.slice(splitPos)

        info = grewpy[method](workerCount, beforeArr)
        for fn in afterArr
          info.add(fn)

        info.finalize(cb)
      when "cb_end,fn_split,workerB"
        # call after fns inited and fns added and cb added
        splitPos  = Math.floor(fnArr.length / 2)
        beforeArr = fnArr.slice(0,splitPos)
        afterArr  = fnArr.slice(splitPos)

        info = grewpy[method](beforeArr, workerCount)
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




for timeout in [null, 50]
  for [values, valuesTitle] in valueArr
    for [method, expectedTime, workerCount] in [
      ["chain", values.length, 1]
      ["group", 1, values.length]
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
          workerCount
        }
      #end formationState
    # end methods

    for [method, expectedTime, workerCount] in [
      ["worker", values.length / 1, 1]
      ["worker", values.length / 2, 2]
      ["worker", values.length / 4, 4]
    ]
      for formationState in [
        "cb_start,fn_start,workerA"
        "cb_start,fn_start,workerB"
        "cb_start,fn_start,workerC"
        "cb_start,fn_start,workerD"
        "cb_start,fn_start,workerE"
        "cb_start,fn_start,workerF"
        "cb_end,fn_start,workerA"
        "cb_end,fn_start,workerB"
        "cb_start,fn_add,workerA"
        "cb_start,fn_add,workerB"
        "cb_end,fn_add,workerA"
        "cb_end,fn_split,workerA"
        "cb_end,fn_split,workerB"
      ]
        add_test {
          method
          values
          valuesTitle
          expectedTime
          timeout
          formationState
          workerCount
        }





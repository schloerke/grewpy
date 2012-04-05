
groupie = require('../../')


add_test = ({method, values, valuesTitle, timeout, formationState}) ->
  formationState or= 0

  unless groupie[method]?
    throw "method not supported!"

  timeout ?= null

  methodTitle = [method, valuesTitle, timeout, "(" + formationState + ")"].join("_")

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

    test.expect(4 + values.length)

    cb = (err, results) ->


      test.equals(err, null)

      test.equals(calls, values.length)

      test.ok(Array.isArray(results))
      test.equals(results.length, values.length)
      for result, resultPos in results
        test.equals(result, values[resultPos])

      test.done();
      return


    switch formationState
      when "cb_start,fn_start"
        # one shot
        groupie[method](fnArr, cb)

      when "cb_end,fn_start"
        # call after fns inited
        info = groupie[method](fnArr)
        info.finalize(cb)

      when "cb_start,fn_add"
        # call after fns added
        info = groupie[method](cb)
        for fn in fnArr
          info.add(fn)

        info.finalize()

      when "cb_end,fn_add"
        # call after fns added and cb added
        info = groupie[method]()
        for fn in fnArr
          info.add(fn)

        info.finalize(cb)


      when "cb_end,fn_split"
        # call after fns inited and fns added and cb added
        splitPos  = Math.floor(fnArr.length / 2)
        beforeArr = fnArr.slice(0,splitPos)
        afterArr  = fnArr.slice(splitPos)

        info = groupie[method](beforeArr)
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

for timeout in [null, 10]
  for method in ["chain", "group"]
    for [values, valuesTitle] in valueArr
      for formationState in ["cb_start,fn_start", "cb_start,fn_add", "cb_end,fn_start", "cb_end,fn_add", "cb_end,fn_split"]
        add_test {
          method
          values
          valuesTitle
          timeout
          formationState
        }




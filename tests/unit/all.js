var add_test, formationState, groupie, method, timeout, valueArr, values, valuesTitle, _i, _j, _k, _l, _len, _len2, _len3, _len4, _ref, _ref2, _ref3, _ref4;
groupie = require('../../');
add_test = function(_arg) {
  var calls, fn, fnArr, formationState, method, methodTitle, timeout, value, values, valuesTitle, _i, _len;
  method = _arg.method, values = _arg.values, valuesTitle = _arg.valuesTitle, timeout = _arg.timeout, formationState = _arg.formationState;
  formationState || (formationState = 0);
  if (groupie[method] == null) {
    throw "method not supported!";
  }
    if (timeout != null) {
    timeout;
  } else {
    timeout = null;
  };
  methodTitle = [method, valuesTitle, timeout, "(" + formationState + ")"].join("_");
  fn = null;
  calls = 0;
  fn = function(value) {
    return function(done) {
      var inner_fn;
      inner_fn = function() {
        calls++;
        done(null, value);
      };
      if (timeout != null) {
        setTimeout(inner_fn, timeout);
      } else {
        inner_fn();
      }
    };
  };
  fnArr = [];
  for (_i = 0, _len = values.length; _i < _len; _i++) {
    value = values[_i];
    fnArr.push(fn(value));
  }
  exports[methodTitle] = function(test) {
    var afterArr, beforeArr, cb, fn, info, splitPos, _j, _k, _l, _len2, _len3, _len4;
    test.expect(4 + values.length);
    cb = function(err, results) {
      var result, resultPos, _len2;
      test.equals(err, null);
      test.equals(calls, values.length);
      test.ok(Array.isArray(results));
      test.equals(results.length, values.length);
      for (resultPos = 0, _len2 = results.length; resultPos < _len2; resultPos++) {
        result = results[resultPos];
        test.equals(result, values[resultPos]);
      }
      test.done();
    };
    switch (formationState) {
      case "cb_start,fn_start":
        return groupie[method](fnArr, cb);
      case "cb_end,fn_start":
        info = groupie[method](fnArr);
        return info.finalize(cb);
      case "cb_start,fn_add":
        info = groupie[method](cb);
        for (_j = 0, _len2 = fnArr.length; _j < _len2; _j++) {
          fn = fnArr[_j];
          info.add(fn);
        }
        return info.finalize();
      case "cb_end,fn_add":
        info = groupie[method]();
        for (_k = 0, _len3 = fnArr.length; _k < _len3; _k++) {
          fn = fnArr[_k];
          info.add(fn);
        }
        return info.finalize(cb);
      case "cb_end,fn_split":
        splitPos = Math.floor(fnArr.length / 2);
        beforeArr = fnArr.slice(0, splitPos);
        afterArr = fnArr.slice(splitPos);
        info = groupie[method](beforeArr);
        for (_l = 0, _len4 = afterArr.length; _l < _len4; _l++) {
          fn = afterArr[_l];
          info.add(fn);
        }
        return info.finalize(cb);
      default:
        throw "formationState " + formationState + " not valid";
    }
  };
};
valueArr = [[[void 0, void 0, void 0, void 0], "undefined"], [[null, null, null, null], "null"], [["red", "green", "blue", "yellow"], "colors"], [["red", void 0, null, "yellow"], "mixedColors"]];
_ref = [null, 10];
for (_i = 0, _len = _ref.length; _i < _len; _i++) {
  timeout = _ref[_i];
  _ref2 = ["chain", "group"];
  for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
    method = _ref2[_j];
    for (_k = 0, _len3 = valueArr.length; _k < _len3; _k++) {
      _ref3 = valueArr[_k], values = _ref3[0], valuesTitle = _ref3[1];
      _ref4 = ["cb_start,fn_start", "cb_start,fn_add", "cb_end,fn_start", "cb_end,fn_add", "cb_end,fn_split"];
      for (_l = 0, _len4 = _ref4.length; _l < _len4; _l++) {
        formationState = _ref4[_l];
        add_test({
          method: method,
          values: values,
          valuesTitle: valuesTitle,
          timeout: timeout,
          formationState: formationState
        });
      }
    }
  }
}
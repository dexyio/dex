defmodule Dex.JSTest do

  use ExUnit.Case
  alias Dex.JS

  test "eval!" do
    js = JS.take_handle
    1 = JS.eval! js, "1"
    0.1 = JS.eval! js, ".1"
    6 = JS.eval! js, "2*3"
    true = JS.eval! js, "true"
    false = JS.eval! js, "false"
    3.141592653589793 = JS.eval! js, "Math.PI"
    "hello world" = JS.eval! js, "\"hello world\""
    [1, 2, 3, 3.141592653589793] = JS.eval! js, "[1, 2, 3, Math.PI]"
    %{"a" => [1, 2, 3]} = JS.eval_script! js, ~S"""
      return {a: [1, 2, 3]};
    """
    JS.return_handle js
  end

  test "jStat" do
    js = JS.take_handle
    6 = JS.eval! js, "require('jStat').jStat.sum([1, 2, 3])"
    [2,4,6,8,10] = JS.eval! js, "require('jStat').jStat.seq(2, 10, 5)"
    %{"0" => [0, 0.5, 1, 1.5, 2], "length" => 1} = JS.eval! js, ~S"""
      require('jStat').jStat(0, 1, 5, function( x ) {
        return x * 2;
      })
    """
    JS.return_handle js
  end

  test "numeral" do
    js = JS.take_handle
    "1,000" = JS.eval! js, "require('numeral')(1000).format('0,0')"
    JS.return_handle js
  end

  test "mathjs" do
    js = JS.take_handle
    2.718 = JS.eval_script! js, """
    var math = require('mathjs');
    return math.round(math.e, 3);
    """
    JS.return_handle js
  end

  test "moment" do
    js = JS.take_handle
    "en" = JS.eval! js, "require('moment').locale()"
    JS.return_handle js
  end

end


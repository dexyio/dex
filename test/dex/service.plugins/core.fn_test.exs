defmodule Dex.Service.Plugins.Core.FnTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "foo" do
    ~S"""
      <data>
        <fn get=''>
          | set "get"
        </fn>

        | set "hello"
      </data>
    """ |> assert!("hello")
  end

  test "represent html" do
    ~S"""
      <data>
        @cdata
        <fn show_html='name, age'>
          <html> Hello! My name is #{name} and #{age} years old </html>
        </fn>

        | show_html "Foo", 10
        | trim
      </data>
    """ |> match!("<html> Hello! My name is Foo and 10 years old </html>")
    ~S"""
    <data>
      // x is local variable
      | set x: 10
      @cdata <do> #{x} </do>
    </data>
    """ |> assert!("")
    ~S"""
    <data>
      | set 10
      @cdata <do> #{data} </do>
    </data>
    """ |> assert!("10")
  end

  test "returning cdata" do
    ~S"""
    <data>
      <fn/>
    </data>
    """ |> assert!(nil)
    
    ~S"""
    <data>
      <fn foo=''/>
    </data>
    """ |> assert!(nil)

    ~S"""
    <data>
      <fn foo='p1, p2' opt1='' opt2=''/>
    </data>
    """ |> assert!(nil)

    ~S"""
    <data>
      <fn foo=''>
        1
      </fn>

      | foo
    </data>
    """ |> assert!(1)

    ~S"""
    <data>
      <fn foo=''>
        "hello world"
      </fn>

      | foo
    </data>
    """ |> assert!("hello world")

    ~S"""
    <data>
      @cdata
      <fn foo=''>
        <html/>
      </fn>

      | foo
    </data>
    """ |> assert!("<html/>")

    ~S"""
    <data>
      <fn foo='p1'>
        p1
      </fn>

      | foo [1, 2, {}, {:}]
    </data>
    """ |> assert!([1, 2, {}, %{}])

    ~S"""
    <data>
      <fn foo='p1, p2, p3'>
        [p1, p2, p3 + 1]
      </fn>

      | foo "hello", "world", 1
    </data>
    """ |> assert!(["hello", "world", 2])

    ~S"""
    <data>
      <fn foo='p1, p2, p3'>
        [p1, p2, p3 + 1]
      </fn>

      | foo "hello", "world", 1
    </data>
    """ |> assert!(["hello", "world", 2])

    ~S"""
    <data>
      <fn foo='p1, p2, p3'>
        {p1: p1, p2: p2, p3: p3}
      </fn>

      | foo "hello", "world", 1
    </data>
    """ |> assert!(%{"p1"=>"hello", "p2"=>"world", "p3"=>1})
  end

  test "javascript" do
    ~S"""
    <data>
    @lang javascript
    <fn js='cmd'>
      return eval(cmd);
    </fn>

    | js "1+1"
  </data>
    """ |> assert!(2)

    ~S"""
    <data>
      @lang javascript
      <fn js='cmd'>
        return eval(cmd);
      </fn>

      | js ~s/"hello world"/
    </data>
    """ |> assert!("hello world")
  end

  test "calling in function" do
    _ = ~S'''
    (task = Task.async fn ->
      ~S"""
      <data>
        @private <fn foo=''>
          | bar
        </fn>

        @private <fn bar=''>
          | foo
        </fn>

        | foo
      </data>
      """ |> do!
    end)
    |> Task.yield(1_000) || Task.shutdown(task)
    |> assert?(nil)
    '''
    ~S"""
    <data>
      @private <fn foo=''>
        | bar
      </fn>

      @private <fn bar=''>
        | foo
      </fn>

      | foo
    </data>
    """ |> assert_raise!(Dex.Error.FunctionDepthOver)
  end

  test "variable scope" do
    ~S"""
    <data>
      <fn test=''>
        | set foo: "bar"
      </fn>

      | test | set foo
    </data>
    """ |> assert!(nil)

    ~S"""
    <data>
      <fn test=''>
        | assert 0
        | set nil, x: 2
        | assert nil, x: 2
      </fn>

      | set 0, x: 1 | test | assert nil, x: 1
    </data>
    """ |> assert!(nil)
  end

  test "case sensitivity" do
    ~S"""
    <data>
      <fn Echo='x'>
        | set x
      </fn>

      | ECHO 1 | assert 1
      | Echo "foo" | assert "foo"
      | echo | assert nil
    </data>
    """ |> assert!(nil)
  end

  test "fn name for unicode" do
    ~S"""
    <data>
      <fn 더하기='x'>
        | set 0 if: nil
        | set x: 0 if: x == nil
        | set data + x
      </fn>

      <fn 빼기='x'>
        | set 0 if: nil
        | set x: 0 if: x == nil
        | set data - x
      </fn>

      | 더하기    | assert 0
      | 더하기 10 | assert 10
      | 빼기 5    | assert 5
      | set 빼기(5)
    </data>
    """ |> assert!(0)
  end

  test "html" do
    ~S"""
    @dexyml

    <fn columns=''>
      [
        ["data1", 100, 200, 150, 300, 200],
        ["data2", 400, 500, 250, 700, 300],
      ]
    </fn>

    <fn html='cols'>
      | set cols
    </fn>

    | set columns() | to_string
    | map body: html(data)
    | nil
    """ |> assert!(nil)
  end

  test "error" do
    ~S"""
    <data>
      <fn output=''>
        123 "hello world"
      </fn>

      | output
    </data>
    """ |> assert_raise!(Dex.Error.SyntaxError)
  end

end

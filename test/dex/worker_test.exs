defmodule Dex.WorkerTest do

  use ExUnit.Case, async: false
  use Dex.Test
  alias Dex.Test.Helper

  setup do
    :ok
  end

  test "putting the app1" do
    ~S"""
      <data>
        @cdata
        <fn:1 app_body=''>
          <data>
            <fn get=''> "hello world" </fn>
          
            | set "invalid function"
          </data>
        </fn:1>

        | app.disable "app1" | app.delete "app1" 
        | app.put "app1", app_body() | assert "ok"
        | app.get "app1" 
        | assert data.enabled: true
        | assert data.export: false
        | nil
      </data>
    """ |> assert!(nil)
  end

  test "app1 - calling valid function" do
    assert {:ok, "hello world"} == call "app1", "get" 
  end

  test "app1 - error when invalid call" do
    assert call("app1", "invalid") == {:error, %{
      args: [], code: 400, error: "FunctionNotFound", fun: "invalid",
      line: 0, message: nil, opts: %{}}
     }
  end

  test "putting the app2" do
    ~S"""
      <data>
        @cdata
        <fn:1 app_body=''>
          <data>
            @use app1 as: 마이앱
            <fn app1_get=''> | 마이앱.get </fn>
            
            | set "invalid function"
          </data>
        </fn:1>

        | app.post "app2", app_body() 
        | nil
      </data>
    """ |> assert!(nil)
  end

  test "app2 - valid calling app1" do
    assert {:ok, "hello world"} == call "app2", "app1_get" 
  end

  test "app2 - invalid calling app1" do
    assert call("app2", "invalid") == {:error, %{
      args: [], code: 400, error: "FunctionNotFound", fun: "invalid",
      line: 0, message: nil, opts: %{}}
   }
  end

  test "pipeline 'use'" do
    ~S"""
      <data>
        @cdata <fn:1 script=''>
          <data>
            <fn foo='a, b' c='0'>
              | set a + b + c
            </fn>
          </data>
        </fn:1>

        | script | use as: "myapp"
        | set fun: "foo"
        | apply "myapp.#{fun}" args: [1,2], opts: {c: 10}
      </data>
    """ |> assert!(13)
    ~S"""
      <data>
        | set "<data> \"hello\" </data>"
        | use as: "myapp2"
        | apply "myapp2._test"
      </data>
    """ |> assert!("hello")
    ~S"""
      <data>
        | set "<data> \"hello\" </data>"
        | use as: "myapp3"
        | apply "myapp3._test"
      </data>
    """ |> assert!("hello")
  end
  
  defp call app, fun do
    user = Helper.user
    req = Helper.request_props app, fun
    {:ok, res} = Dex.Service.start_worker user, req
    rid = res[:rid]
    receive do {^rid, msg} -> msg
    after 3*1000 -> :timeout
    end
  end

end

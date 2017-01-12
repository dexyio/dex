defmodule Dex.Service.Plugins.Core.DatetimeTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "datetime" do
    ~S"""
    <data>
      | datetime.now | is_datetime      | assert true
      | datetime.now | to_map | is_map  | assert true
      | datetime.now | to_string | is_string | assert true
      | datetime.now | datetime.to_secs | is_number | assert true
      | datetime.now | datetime.to_msecs | is_number | assert true
      | datetime.now | datetime.to_usecs | is_number | assert true
      
      | now.secs  | is_number | assert true
      | now.msecs | is_number | assert true
      | now.usecs | is_number | assert true
      
      | now.secs  | datetime.from_secs  | is_number | assert true 
      | now.msecs | datetime.from_msecs | is_number | assert true 
      | now.usecs | datetime.from_usecs | is_number | assert true 

      | nil
    </data>
    """ |> assert!(nil)
  end

end

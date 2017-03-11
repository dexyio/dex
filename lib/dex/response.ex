defmodule Dex.Response do

  defstruct code: nil,
            header: nil,
            body: nil

  @type t :: %__MODULE__{
    code: pos_integer,
    header: bitstring,
    body: bitstring
  }

end

defmodule Dex.Service.Request do

  defstruct id: nil,
            peer: nil,
            user: "",
            app: "",
            fun: "",
            args: [],
            opts: %{},
            vars: %{},
            header: %{},
            body: "",
            callback: nil,
            remote_ip: []

  @type t :: %__MODULE__{
    id: bitstring,
    peer: Peer.t,
    user: bitstring,
    app: bitstring,
    fun: bitstring,
    args: list,
    opts: map,
    vars: map,
    header: map,
    body: map,
    callback: pid,
    remote_ip: list
  }


  defmodule Peer do
    defstruct ip: nil,
              port: nil,
              remote: nil,
              protocol: nil

    @type t :: %__MODULE__{
      ip: list,
      port: pos_integer,
      remote: list,
      protocol: atom
    }
  end

  defmacro default_timeout, do: 60_000

end

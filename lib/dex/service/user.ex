defmodule Dex.Service.User do

  defstruct id: nil,
            no: 0,
            __secret: nil,
            email: nil,
            country: nil,
            language: nil,
            timezone: nil,
            balance: 0,
            created: nil,
            public: false,
            enabled: false

  @type app_name :: bitstring
  @type bucket :: bitstring
  @type flag :: <<_::1>>
  @type key :: <<_::8, >>
  @type t :: %__MODULE__{
    id: bitstring,
    no: pos_integer,
    balance: non_neg_integer,
    created: pos_integer,
    enabled: boolean
  }

  @bucket :erlang.term_to_binary(__MODULE__)
  @new_flags for <<flag <- "11111111">>, into: <<>>, do: <<flag::1>>

  use Dex.Common
  use Timex
  require Dex.KV, as: KV
 
  @spec get(bitstring) :: {:ok, %__MODULE__{}} | {:error, :user_notfound}

  def get(id) do
    case KV.get(@bucket, id) do
      {:error, _} -> {:error, :user_notfound}
      {:ok, user} -> {:ok, user}
    end
  end

  @spec new(bitstring, bitstring, bitstring) :: :ok | {:error, term}

  def new(id, spw, email) do
    user = %__MODULE__{
      id: id,
      __secret: secret(id, spw),
      email: email,
      created: Timex.now |> Timex.format!("{RFC1123}"),  #"Tue, 08 Nov 2016 06:39:55 +0000"
      enabled: true
    }
    KV.put(@bucket, id, user)
  end

  defp secret(id, spw) do
    sha256(id <> ":" <> spw)
  end

end

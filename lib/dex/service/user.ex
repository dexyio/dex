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

  use Dex.Common
  use Timex
  require Dex.KV, as: KV
 
  @spec get(bitstring) :: {:ok, %__MODULE__{}} | {:error, :user_notfound}

  def get user_id do
    user_id = String.downcase user_id
    case KV.get(@bucket, user_id) do
      {:error, _} -> {:error, :user_notfound}
      {:ok, user} -> {:ok, user}
    end
  end

  def exist? user_id do
    case get user_id do
      {:ok, _} -> true
      {:error, :user_notfound} -> false
    end
  end

  @spec new(bitstring, bitstring, bitstring) :: :ok | {:error, term}

  def new user_id, secured_pw, email do
    case exist? user_id do
      true -> {:error, :user_already_exists}
      false -> put user_id, secured_pw, email
    end
  end

  @spec put(bitstring, bitstring, bitstring) :: :ok | {:error, term}

  def put user_id, secured_pw, email do
    user_id = String.downcase user_id
    user = %__MODULE__{
      id: user_id,
      __secret: secret(user_id, secured_pw),
      email: email,
      created: Timex.now |> Timex.format!("{RFC1123}"),  #"Tue, 08 Nov 2016 06:39:55 +0000"
      enabled: true
    }
    KV.put(@bucket, user_id, user)
  end

  defp secret(user_id, secured_pw) do
    String.downcase user_id
    sha256(user_id <> ":" <> secured_pw)
  end

end

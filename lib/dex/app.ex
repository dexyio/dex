defmodule Dex.App do

  use Dex.Common
  require Dex.KV, as: KV
  alias Dex.Event
  alias Dex.Parsers.XML
  require Logger

  defmodule Fun do
    defstruct no: 0,
              access: :protected,
              args: [],
              opts: %{},
              annots: %{}
    
    @type default :: any
    @type t :: %__MODULE__{
      access: :public | :protected | :private,
      args: [bitstring],
      opts: %{bitstring => default},
      annots: %{bitstring => any}
    }
  end

  defstruct id: nil,
            rev: 0,
            owner: nil,
            title: nil,
            hash: nil,
            script: nil,
            parsed: nil,
            tags: [],
            vars: nil,
            funs: %{},
            uses: nil,
            created: 0,
            export: false,
            enabled: true

  @type fun_name:: bitstring
  @type app_alias :: bitstring
  @type ref :: function
  @type funs :: %{fun_name => %Fun{}}

  @type t :: %__MODULE__{
    id: bitstring,
    owner: bitstring,
    title: bitstring,
    hash: bitstring,
    rev: pos_integer,
    script: bitstring,
    parsed: bitstring,
    vars: %{bitstring => any()},
    funs: %{fun_name => %Fun{}},
    uses: %{app_alias => %__MODULE__{}},
    tags: list(bitstring),
    created: pos_integer,
    export: boolean,
    enabled: boolean
  }

  @default_userid "*"
  @default_fun "_test"

  def notify(msg), do: Event.notify __MODULE__, msg
  def notify_cluster(msg), do: Event.notify_cluster __MODULE__, msg

  @bucket :erlang.term_to_binary(__MODULE__)

  def default_userid, do: @default_userid

  @spec parse!(bitstring, bitstring) :: %__MODULE__{} | Dex.Error

  def parse! user_id, script do
    case String.split(script, ~r/\n|$/u, parts: 2) do
      [pre, post] ->
        pre |> String.trim |> do_parse({user_id, post})
      _ ->
        XML.parse! user_id, "<data/>"
    end
  end

  @spec default_fun() :: bitstring

  def default_fun, do: @default_fun

  @spec compile!(%Dex.App{}, bitstring) :: {atom, binary}

  def compile! app = %Dex.App{}, module_name do
    codes = "defmodule #{module_name} " <> app.parsed #IO.puts codes
    try do
      [{mod, bin}] = Elixir.Code.compile_string codes
      {mod, bin}
    rescue ex ->
      #IO.inspect ex
      handle_exception ex, codes
    catch :throw, {err, state} ->
      raise Error.CompileError, reason: err, state: state
    end
  end

  @spec get(bitstring, bitstring) :: {:ok, %__MODULE__{}} | {:error, term}

  def get(user_id, app_id) when is_bitstring(user_id) and is_bitstring(app_id) do
    key = key(user_id, app_id)
    case KV.get(@bucket, key) do
      {:ok, app} -> {:ok, app}
      {:error, :notfound} -> {:error, :app_notfound}
      error -> error
    end
  end

  @spec exist?(bitstring, bitstring) :: true | false

  def exist?(user_id, app_id) do
    get(user_id, app_id) != {:error, :app_notfound}
  end

  @spec create(bitstring, bitstring, bitstring) :: :ok | {:error, term}

  def create(user_id, app_id, body) do
    if exist?(user_id, app_id) do
      {:error, :app_already_exists}
    else
      :ok = put user_id, app_id, body
      notify {:app_created, user_id, app_id}
    end
  end

  @spec put(bitstring, bitstring, bitstring) :: :ok | {:error, term}

  def put(user_id, app_id, body) when is_bitstring(body) do
    app = parse! user_id, body
    put %{app | id: app_id}
  end

  @spec put(%__MODULE__{}) :: :ok | {:error, term}

  def put app = %__MODULE__{owner: user_id, id: app_id} do
    key = key(user_id, app_id)
    :ok = KV.put @bucket, key, app
    notify_cluster {:app_updated, user_id, app_id}
  end

  @spec delete(bitstring, bitstring) :: :ok | {:error, term}

  def delete(user_id, app_id) do
    with \
      {:ok, app} <- get(user_id, app_id),
      false <- app.enabled && {:error, :app_not_disabled}
    do
      :ok = KV.delete @bucket, key(user_id, app_id)
      notify_cluster {:app_deleted, user_id, app_id}
    end
  end

  @spec enable(bitstring, bitstring) :: :ok | {:error, term}

  def enable user_id, app_id do
    with \
      {:ok, app} <- get(user_id, app_id),
      :ok <- %{app | enabled: true} |> put()
    do
      notify {:app_enabled, user_id, app_id}
    end
  end

  @spec disable(bitstring, bitstring) :: :ok | {:error, term}

  def disable user_id, app_id do
    with \
      {:ok, app} <- get(user_id, app_id),
      :ok <- %{app | enabled: false} |> put()
    do
      notify {:app_disabled, user_id, app_id}
    end
  end

  @spec real_fun(bitstring, %__MODULE__{}) :: nil | atom

  def real_fun name, app = %__MODULE__{} do
    case app.funs[name] do
      %Fun{} = fun -> "_F#{fun.no}" |> String.to_existing_atom
      nil -> nil
    end
  end

  # Private functions

  defp do_parse head = "<data" <> _, {user_id, rest} do
    XML.parse! user_id, head <> "\n" <> rest
  end

  defp do_parse "@dexyml" <> _, {user_id, script} do
    script = """
    <data>
    #{script}
    </data>
    """
    XML.parse! user_id, script
  end

  defp do_parse "@html" <> _, {user_id, script} do
    {annots, script} = annotations script
    script = """
    <data>
    #{annots} @cdata <fn:_html_ html=''> #{script}
    </fn:_html_>
    | map header: {content-type: "text/html;charset=utf8"}
          body: html()
          code: 200
    </data>
    """
    XML.parse! user_id, script
  end

  defp do_parse "@text" <> _, {user_id, script} do
    {annots, script} = annotations script
    script = """
    <data>
    #{annots} @cdata <do:_text_> #{script}
    </do:_text_>
    </data>
    """
    XML.parse! user_id, script
  end

  defp do_parse "@javascript" <> _, {user_id, script} do
    {annots, script} = annotations script
    script = """
    <data>
    #{annots} @lang javascript <do:_js_> #{script}
    </do:_js_>
    </data>
    """
    XML.parse! user_id, script
  end

  defp do_parse "@coffeescript" <> _, {user_id, script} do
    {annots, script} = annotations script
    script = """
    <data>
    #{annots} @lang coffeescript <do:_js_> #{script}
    </do:_js_>
    </data>
    """
    XML.parse! user_id, script
  end
  
  defp do_parse pre, {user_id, post} do
    do_parse "@text", {user_id, pre <> "\r\n" <> post}
  end

  defp annotations script do
    regex = ~r/\s*@\w+[\s\S]*?\n *(?=<!?\w)/u
    case Regex.run regex, script do
      nil -> {"", script}
      [captured] ->
        replaced = String.replace(script, regex, "")
        {captured, replaced}
    end
  end

  defp handle_exception ex = %SyntaxError{}, codes do
    line_no = get_codeline(codes, ex.line) |> get_lineno
    raise Error.SyntaxError,
      reason: replace_errmsg(ex.description, line_no),
      state: %Dex.Service.State{line: line_no}
  end

  defp handle_exception ex = %TokenMissingError{}, codes do
    line_no = get_codeline(codes, ex.line) |> get_lineno
    raise Error.SyntaxError,
      reason: replace_errmsg(ex.description, line_no),
      state: %Dex.Service.State{line: line_no}
  end

  defp handle_exception ex = %CompileError{}, _codes do
    raise Error.CompileError, reason: ex.description
  end

  defp handle_exception ex, _codes do
    reraise ex, System.stacktrace
  end

  defp key _user_id, "_" <> app_id do
    app_id = app_id |> String.trim_leading("_")
    key @default_userid, app_id
  end

  defp key user_id, app_id do
    user_id <> "/" <> (app_id || "")
  end

  defp replace_errmsg "unexpected token: \"]\". " <> str, line_no do
    str |> replace_lineno(line_no)
  end

  defp replace_errmsg str = "missing terminator: " <> _, line_no do
    str |> replace_lineno(line_no)
  end

  defp replace_errmsg str, line_no do
    case Regex.run ~r/(?<=unexpected token: ")[^"]+/u, str do
      nil -> default_errmsg :syntax, line_no
      [token] -> "unexpected token #{token} at line #{line_no}"
    end
  end

  defp default_errmsg :syntax, line_no do
    "syntax error at line " <> to_string(line_no)
  end

  defp replace_lineno str, line_no do
    String.replace str, ~r/line [0-9]+/, "line " <> to_string(line_no)
  end

  defp get_codeline codes, line do
    Lib.lines(codes, parts: line)
      |> Enum.reverse
      |> Enum.drop_while(fn x ->
        regex = ~r/(line:\s+|do!\(s,\s+|defp _L|def _F|defp _F)[0-9]+/u
        not Regex.match?(regex , x)
      end)
      |> List.first
  end

  defp get_lineno line do
    regex = ~r/(?<=line: |do!\(s, |defp _L|def _F|defp _F)[0-9]+/
    case Regex.run regex, line do
      nil -> 0
      [no] -> String.to_integer(no)
    end
  end

end

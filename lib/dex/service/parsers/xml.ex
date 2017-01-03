defmodule Dex.Service.Parsers.XML do
 
  use Dex.Common
  use Dex.Service
  alias DexyLib.Mappy
  alias Dex.Service.App
  alias Dex.Service.Routes

  defmodule State do
    defstruct user: nil,
              app: %App{},
              fun: nil,
              args: nil,
              opts: nil,
              annots: nil,
              cdata: nil,
              line: "",
              uses: nil,
              tags: nil,
              removers: nil,
              script: nil,
              full_codes: "",
              main_codes: "",
              line_codes: "",
              indents: []

    @type t :: %__MODULE__{
      user: bitstring,
      app: %App{},
      fun: bitstring,
      args: list,
      opts: map,
      annots: map,
      cdata: bitstring,
      line: bitstring,
      uses: map,
      tags: list,
      script: bitstring,
      full_codes: bitstring,
      main_codes: bitstring,
      line_codes: bitstring,
      indents: list
    }
  end

  @type script :: bitstring
  @type parsed_codes :: bitstring
  @type fun_name :: bitstring
  @type whitespace :: bitstring
  @type annotations :: map

  @global_annots ~w(id title export tags use disable appdoc set)
  @block_annots ~w(public protected private lang doc noparse cdata)

  @spec parse!(bitstring, bitstring) :: %Dex.Service.App{}

  def parse! user_id, script do
    %State{user: user_id, script: script}
      |> init
      |> pre_process      
      |> parse_xml!
      |> set_app(:parsed)
      |> Map.get(:app)
  end

  defp init state do
    state
      |> init_indents
      |> set_app(:owner)
      |> set_app(:script)
  end

  defp init_indents state do
    %{state | indents: [space 4]}
  end

  defp pre_process state do
    state 
      |> transform_script
      |> register_prerequisites
      |> remove_global_annots
  end

  defp transform_script state do
    state
      |> prepend_pipes
      |> wrap_noparse_with_cdata
      |> wrap_annot_cdata
      |> fix_line_syntax
      |> append_line_no
      |> remove_cdata_areas
      |> remove_block_comments
      |> wrap_pipescript_with_do
      |> wrap_script_with_cdata
      |> restore_cdata_areas
      |> fix_pipe_comments
  end

  @spec set_app(%State{}, atom) :: %State{}

  defp set_app state, :owner do
    put_in state.app.owner, state.user
  end

  defp set_app state, :script do
    put_in state.app.script, state.script
  end

  defp set_app state, :parsed do
    put_in state.app.parsed, state.full_codes
  end

  defp fix_line_syntax state do
    res = String.split(state.script, ~R/\r?\n/)
      |> Enum.reduce({"", 1, false}, fn line, {script, no, pass?} ->
        {line2, no} = pass? && {line, no} || (
          {line, no}
            |> do_fix_line_syntax(:remove_line_comment)
            |> do_fix_line_syntax(:check_syntax)
            |> do_fix_line_syntax(:fix_noset_value)
            |> do_fix_line_syntax(:fix_element_fn)
            |> do_fix_line_syntax(:fix_ifunless_opts)
            |> do_fix_line_syntax(:fix_do_opts)
            |> do_fix_line_syntax(:fix_question_mark)
            |> do_fix_line_syntax(:fix_array_bracket)
        )
        pass? = pass? || Regex.match?(~R/<!\[CDATA\[/, line2)
        pass? = pass? && not Regex.match?(~R/]]>/, line2)
        {script <> line2 <> "\n", no + 1, pass?}
      end) |> elem(0)
    %{state | script: res}
  end

  defp do_fix_line_syntax {line, no}, :remove_line_comment do
    line2 = Regex.replace ~R/(\s+|^)\/\/.*/u, line, "\\1"
    {line2, no}
  end

  defp do_fix_line_syntax {line, no}, :check_syntax do
    Regex.match?(~R/\s*\|[\w:\-\.]+($|\s+)/u, line) && raise Error.SyntaxError,
      reason: line, state: %Dex.Service.State{line: no}
    {line, no} 
  end

  defp do_fix_line_syntax {line, no}, :fix_noset_value do
    line2 = ~R/(\s*\|\s+)([0-9]|[^\w\s])(.*?)(?=\s+\|\s+|\s*$)/u
      |> Regex.replace(line, "\\1set \\2\\3")
    {line2, no} 
  end

  defp do_fix_line_syntax {line, no}, :fix_element_fn do
    line2 = ~R/(<fn(?::\w+)?)\s+(\w+)\s*=\s*['"]([\s\S]*?)['"]/u
      |> Regex.replace(line, "\\1 _id='\\2' _params='\\3'")
    {line2, no} 
  end

  defp do_fix_line_syntax {line, no}, :fix_ifunless_opts do
    line2 = ~R/(^|\s)(\|\s+[\w\.\-]+[^\|]*?)\s+(if|unless)( +[\w\.\-:]+)?:\s+(.+?)\s*(?=(\s\|\s+[\w\.\-]+.*)|$)\6*/u
      |> Regex.replace(line, fn
        _, f1, f2, f3, "", f5, "" -> "#{f1}| #{f3} #{f5} do #{f2} | end"
        _, f1, f2, f3, "", f5, f6 -> "#{f1}| #{f3} #{f5} do #{f2} | else#{f6} | end"
        _, f1, f2, f3, f4, f5, "" -> "#{f1}| #{f3}#{f4}: #{f5} do #{f2} | end"
        _, f1, f2, f3, f4, f5, f6 -> "#{f1}| #{f3}#{f4}: #{f5} do #{f2} | else#{f6} | end"
      end)
    {line2, no}
  end

  defp do_fix_line_syntax {line, no}, :fix_do_opts do
    line1 = ~R/((?:^ *|\s+)\|\s+[\w\.\-]+[^\|]*)\s+do:\s+((?:\|\s+)?)(.+)/u
      |> Regex.replace(line, "\\1 do | \\3 | end")
    line2 = ~R/(\s*\|\s+)([\w\.\-]+)(\s+[^\|]*?)do(?=\s*$|\s+\|\s+[\w\.\-]+)/u
      |> Regex.replace(line1, "\\1do.\\2\\3")
    {line2, no}
  end

  defp do_fix_line_syntax {line, no}, :fix_question_mark do
    line2 = ~R/(^ *)\|\s+([\w\.\-]+)\? *?(.*?)([\w\.\-:]+: +.+?)?(?=(\s+\|\s+[\w\.\-]+.*)|\s*$)\5?/u
      |> Regex.replace(line, fn
        _, _1, _2, "", _4, "" -> ""
        _, f1, f2, "", _4, f5 -> "#{f1}| unless do #{f2}#{f5} | end"
        _, f1, f2, f3, f4, "" -> "#{f1}| if #{f2}: true do |#{f3} #{f2} #{f4} | end"
        _, f1, f2, f3, f4, f5 -> "#{f1}| if #{f2}: true do |#{f3} #{f2} #{f4} | else#{f5} | end"
      end)
    {line2, no}
  end

  defp do_fix_line_syntax {line, no}, :fix_array_bracket do
    if Regex.match? ~R/^ *\|\s+\w+/u, line do
      {Mappy.transform(line), no}
    else
      {line, no}
    end
  end

  @spec remove_block_comments(%State{}) :: %State{}

  defp remove_block_comments state do
    script = ~R/(\s+)\/\*[\s\S]+?\*\/(?=\s+)/u
      |> Regex.replace(state.script, "\\1")
    %{state | script: script}
  end

  defp register_prerequisites state do
    state
      |> register_libraries 
      |> register_functions
      |> set_app_environment
  end

  defp remove_global_annots state do
    state
      |> remove_annots(@global_annots)
  end

  defp prepend_pipes state do
    regex = ~R/(@lang\s+pipescript[\s\S]+?)<([\w\.\-]+)([^>]*?)>([\s\S]+?)<\/\2>/u
    res = Regex.replace regex, state.script, fn
      _match, f1, f2, f3, f4 ->
        new_f4 = Regex.replace ~R/((?:\r?\n|^)\s*)([\w\.\-]+)/u, f4, fn
          _match, f1, f2 -> f1 <> "| " <> f2
        end
        "#{f1}<#{f2}#{f3}>#{new_f4}</#{f2}>"
    end
    %{state | script: res}
  end

  defp wrap_pipescript_with_do state do
    regex = ~R/(<\s*(?!do|fn)[^>]*>\s*?)(\|\s+[\s\S]+?):([0-9]+)([\s\S]*?)(?=\n\s*@\w+\s+|\n\s*<\/?[\w\.\-]+)/u
    replace_stmt = "\\1 <do _line='\\3'> <![CDATA[ \\2\\4 ]]> </do>"
    res = Regex.replace regex, state.script, replace_stmt
    %{state | script: res}
  end

  defp wrap_noparse_with_cdata state do
    regex = ~R/((?:@noparse)[^<]*)<\s*([\w\.\-]+)((?::\w+)?)([^>]*)>([\s\S]+?)<\/\s*\2\3>/u
    replace_stmt = ~s(\\1<\\2\\4> <![CDATA[ ~// \\5 ]]> </\\2>)
    res = Regex.replace regex, state.script, replace_stmt
    %{state | script: res}
  end

  defp wrap_annot_cdata state do
    regex = ~R/((?:@cdata\s|@lang\s)[^<]*)<\s*([\w\.\-]+)((?::\w+)?)([^>]*)>(?!\s*<\!\[CDATA\[)([\s\S]+?)<\/\s*\2\3>/u
    replace_stmt = ~s(\\1<\\2\\4> <![CDATA[ \\5 ]]> </\\2>)
    res = Regex.replace regex, state.script, replace_stmt
    %{state | script: res}
  end

  defp append_line_no state do
    res = String.split(state.script, ~R/\r?\n/)
    |> Enum.reduce({"", 1, false}, fn line, {script, no, pass?} ->
      res = pass? && line || (
      #regex = ~R/^\s*(@[a-z]+(?:\s+.*|\s*$)|<[a-z][\w\.\-]*[^\s\/>]+|\|\s+[\w\.\-]+.*?(?=\s+\|\s+[\w\.\-]+|\s*<\/\s*[\w\.\-]+>|\s*$))/u
        regex = ~R/^\s*(@[a-z]+(?:\s+.*|\s*$)|<[a-z][\w\.\-]*[^\s\/>]+|\|\s+[\w\.\-]+(?=.*?\s+\|\s+[\w\.\-]+|\s*<\/\s*[\w\.\-]+>|.*))/u
        Regex.replace regex, line, fn 
          match, "<" <> _ -> match <> " _line='#{no}'"
          match, "|" <> _ -> String.rstrip(match) <> ":#{no}"
          match, "@" <> _ -> ~R/(@\w+)(\s*?.*?)(?=\s+@\w+|$)/u
            |> Regex.replace(match, fn _, f1, f2 ->
              "#{f1} ##{no}#{f2}"
            end)
        end
      )
      pass? = pass? || Regex.match?(~R/<!\[CDATA\[/, line)
      pass? = pass? && not Regex.match?(~R/]]>/, line)
      {script <> res <> "\n", (no + 1), pass?}
    end) |> elem(0)
    %{state | script: res}
  end

  defp remove_cdata_areas state do
    regex = ~R/(?<=<\!\[CDATA\[)(?!\s*\|)[\s\S]*?(?=]]>)/u
    removers = Regex.scan(regex, state.script) |> List.flatten
    script = Regex.replace regex, state.script, "<!cdata!>"
    %{state | removers: removers, script: script}
  end

  defp restore_cdata_areas state do
    script = Enum.reduce state.removers, state.script, fn short, script ->
      String.replace script, "<!cdata!>", short, global: false
    end
    %{state | script: script}
  end

  defp wrap_script_with_cdata state do
    regex = ~R/<\s*(do|fn)([^\>]*)>(?!\s*<\!\[CDATA\[)([\s\S]+?)<\/\s*\1\s*>/u
    replace_stmt = ~s(<\\1\\2> <![CDATA[ \\3 ]]> </\\1>)
    res = Regex.replace regex, state.script, replace_stmt
    %{state | script: res}
  end

  defp fix_pipe_comments state do
    regex = ~R/(\s+)'(\|\s+[\w\.\-]+)/u
    res = Regex.replace regex, state.script, "\\1\\2"
    %{state | script: res}
  end

  defp remove_annots(state, annots) when is_list(annots) do
    script = Enum.reduce annots, state.script, fn annot, acc ->
      remove_annot(annot, acc)
    end
    %{state | script: script}
  end

  defp register_libraries state do
    state
      |> do_register_lib(:scan_tags)
      |> do_register_lib(:load_apps)
      |> do_register_lib(:register)
  end

  defp do_register_lib state, :scan_tags do
    apps =
      annots("use", state.script)
      |> Enum.map(fn %{line: line, data: data, opts: opts} ->
        {user, app} = case String.split(data, "/") do
          [user, app] -> {user, app}
          [app] -> {state.user, app}
        end
        opts = Map.put(opts, :line, line)
        %{user: user, app: app, opts: opts}
      end)
    {apps, state}
  end

  defp do_register_lib {apps, state}, :load_apps do
    {
      Enum.into(apps, %{}, fn %{user: user, app: app, opts: opts} ->
        case App.get user, app do
          {:ok, found = %{owner: ^user}} ->
            {opts["as"] || app, found}
          {:ok, found = %{export: true}} ->
            {opts["as"] || app, found}
          {:error, :app_notfound} ->
            raise Error.AppNotFound, reason: [user, app], state: state
          _ ->
            raise Error.AppNotExported, reason: [user, app], state: state
        end
      end),
      state
    }
  end

  defp do_register_lib {apps, state}, :register do
    uses = (state.uses || %{}) |> Map.merge(apps)
    %{state | uses: uses}
  end

  defp register_functions state do
    funs = ~R/<fn\s+[\s\S]*?id\s*=\s*(['"])(\w+)\1/u
      |> Regex.scan(state.script)
      |> Enum.map_reduce(0, fn [_match, _quote, id], no ->
        no = no + 1
        {{id |> String.downcase, %App.Fun{no: no}}, no}
      end) |> elem(0)
      |> Enum.into(%{App.default_fun => %App.Fun{no: 0, access: :public}})
    funs = Map.merge(state.app.funs, funs)
    put_in state.app.funs, funs
  end

  defp set_app_environment state do
    @global_annots
      |> Enum.map(&annots &1, state.script)
      |> Enum.reduce(state, &do_set_appenv(&1, &2))
  end

  defp do_set_appenv [], state do state end

  defp do_set_appenv [%{name: "title"} = annot | rest], state do
    state = put_in state.app.title, annot.data
    do_set_appenv rest, state
  end

  defp do_set_appenv [%{name: "tags"} = annot | rest], state do
    tags = Regex.scan(~R/\w+/u, annot.data) |> List.flatten
    state = put_in state.app.tags, tags
    do_set_appenv rest, state
  end

  defp do_set_appenv [%{name: "export"} = _annot | rest], state do
    state = put_in state.app.export, true
    do_set_appenv rest, state
  end

  defp do_set_appenv [%{name: "disable"} | rest], state do
    state = put_in state.app.enabled, false
    do_set_appenv rest, state
  end

  defp do_set_appenv [annot = %{name: "set"} | rest], state do
    vars = Map.merge(state.app.vars || %{}, annot.opts || %{})
    state = put_in state.app.vars, vars
    do_set_appenv rest, state
  end

  defp do_set_appenv [_ | rest], state do
    do_set_appenv rest, state
  end

  defp parse_xml! state do
    #IO.puts state.script
    try do
      state.script
        |> :erlsom.parse_sax(state, &sax_event_handler/2)
        |> case do
          {:ok, state, _rest} -> state
          {:error, reason} -> throw reason
        end
    catch
      :throw, {:error, err} ->
        raise Error.SyntaxError, reason: to_string(err), state: state
    rescue
      ex ->
        #IO.inspect ex; IO.puts ""
        handle_exception ex
    end
  end

  defp handle_exception ex do
    reraise ex, System.stacktrace
  end

  defp remove_annot(name, script) do
    regex(:annot, name) |> Regex.replace(script, "")
  end

  defp annots(name \\ "\\w+", script) when is_bitstring(name) do
    regex(:annot, name)
      |> Regex.scan(script)
      |> Enum.map(fn list ->
        %{
          name: Enum.at(list, 1),
          line: Enum.at(list, 2) |> String.to_integer,
          data: Enum.at(list, 3) |> String.strip,
          opts: Enum.at(list, 4) |> extract_opts
        }
      end)
  end

  defp extract_opts nil do %{} end
  defp extract_opts opts do
    ~R/([\w\.\-:]+): +([\s\S]+?)(?=\s+[\w\.\-:]+: +|$)/u
      |> Regex.scan(opts)
      |> Enum.into(%{}, fn [_match, key, val] ->
        {key, String.rstrip val}
      end)
  end

  defp regex(:annot, name) do
    regex = ~S/(?:^|\s)@(/ <> name <> ~S/)\s#([0-9]+)([\s\S]*?)(?=$|\s*\n|\s+@\w+\s|\s+<\/?[\w\.\-]+|(\s+\w+:\s[^@<\n]+))\4*/
    {:ok, res} = Regex.compile(regex, "iu")
    res
  end

  # callback
  defp sax_event_handler :startDocument, state do
    full_codes = """
    do\n
      use Dex.Service.Plugins
      use Dex.Service.Helper
    """
    main_codes = "\n" <> """
    #{space 2}def _F0 state do
    #{space 4}state
    """ 
    %{state | full_codes: state.full_codes <> full_codes,
              main_codes: main_codes}
  end

  defp sax_event_handler :endDocument, state do
    main_codes = state.main_codes <> "#{space 2}end\n"
    full_codes = state.full_codes <> main_codes <> state.line_codes <> """
    \nend  # defmodule
    """
    %{state | full_codes: full_codes}
  end

  defp sax_event_handler \
    {:startElement, _uri, elem, _prefix, attrs}, state
  do
    fun = elem |> to_string |> String.downcase
    opts = attrs_to_map(attrs, state)
    line = opts["_line"] || state.line
    state = %{state | fun: fun, opts: opts, line: line, tags: [fun | state.tags]}
    do_start_element(state, fun)
  end

  defp sax_event_handler {:characters, chars}, state do
    (chars |> to_string |> Lib.trim)
      |> case do
        str = "@" <> _ -> translate_annot state, str
        str -> put_in(state.cdata, str) |> translate_cdata
      end
  end

  defp sax_event_handler {:endElement, _, elem, _prefix}, state do
    [_ | tags] = state.tags
    state = %{state | annots: nil, tags: tags}
    do_end_element(state, to_string elem)
  end

  defp sax_event_handler _event, state do state end

  defp valid_opts nil do %{} end

  defp valid_opts map do
    for kv = {<<f::8, _::bits>>, _} <- map, f != ?_, into: %{}, do: kv
  end

  defp do_start_element state, "data" do state end
  defp do_start_element state, "fn" do write_fn state end
  defp do_start_element state, "do" do write_do state end

  defp do_start_element state, fun do
    fun_ref = fun |> Routes.fn!(state)
    args = state.opts["_blank"] && "[]" || "_L#{state.line}(s)"
    opts = state.opts |> translate_opts(state)
    codes = """
    #{indent state}|> (fn s -> do!(s, #{state.line}, #{inspect fun}, #{fun_ref}, #{args}, #{opts})
    """
    indents = indents_inc state.indents
    %{state | main_codes: state.main_codes <> codes, indents: indents}
  end

  defp do_end_element state, "data" do state end

  defp do_end_element state, "fn" do
    codes = """
        |> data!; set_data(s, data)
      end
    """
    %{state | full_codes: state.full_codes <> codes}
  end

  defp do_end_element state, "do" do
    [_ | indents] = state.indents
    codes = """
    #{indent state.indents}|> data!; set_data(s, data)
    #{indent indents}end).()
    """
    %{state | main_codes: state.main_codes <> codes, indents: indents}
  end

  defp do_end_element state, _fun do
    [_ | indents] = state.indents
    codes = "#{indent indents}end).()\n"
    %{state | main_codes: state.main_codes <> codes, indents: indents}
  end

  defp indent(indents) when is_list(indents) do
    Enum.join indents
  end

  defp indent %{indents: indents} do
    Enum.join indents
  end

  defp check_block_annots annots, state do
    Enum.into annots, %{}, fn annot ->
      (annot.name in @block_annots) || raise Error.InvalidAnnotation,
        reason: annot.name, state: state
      Map.pop(annot, :name)
    end
  end

  defp pipes_to_codes {state, pipes} do
    Enum.reduce pipes, {state, ""}, fn {fun, args, opts, line}, {state, codes} ->
      state = %{state | line: line}
      args = translate_args args, state
      opts = translate_opts opts, state
      do_pipes_to_codes {state, codes}, {fun, args, opts}
    end
  end

  defp do_pipes_to_codes {state, acc}, {"do." <> fun, args, opts} do
    fun_ref = Routes.fn! fun, state
    indents = indents_inc state.indents
    acc = acc <> """
    #{indent state}|> (fn s -> do!(s, #{state.line}, #{inspect fun}, #{fun_ref}, [
    #{indent indents}{fn s -> _=s; #{args} end, fn s -> _=s; #{opts} end, fn s -> s
    """
    state = %{state | indents: indents_inc indents}
    {state, acc}
  end

  defp do_pipes_to_codes({state, acc}, {fun, args, opts})
    when fun in ~w(else when)
  do
    [_ | indents] = state.indents
    acc = acc <> """
    #{indent indents}end},
    #{indent indents}{fn s -> _=s; #{args} end, fn s -> _=s; #{opts} end, fn s -> s
    """
    {state, acc}
  end

  defp do_pipes_to_codes {state, acc}, {"end", _args, _opts} do
    [_ | indents] = state.indents
    [_ | indents2] = indents
    acc = acc <> """
    #{indent indents}end}
    #{indent indents2}]) end).()
    """
    state = %{state | indents: indents2}
    {state, acc}
  end

  defp do_pipes_to_codes {state, acc}, {fun, args, opts} do
    fun_ref = Routes.fn! fun, state
    acc = acc <> """
    #{indent state}|> (fn s -> do!(s, #{state.line}, #{inspect fun}, #{fun_ref}, #{args}, #{opts}) end).()
    """
    {state, acc}
  end

  defp translate_annot state, str do
    annots = annots(str) |> check_block_annots(state)
    line = case Enum.at(annots, 0) do
      nil -> state.line
      {_annot, props} -> props[:line] || state.line
    end
    %{state | annots: annots, line: line}
  end

  defp translate_args str, state do
    str
      |> String.trim
      |> transform_maps
      |> transform_vars(state)
      |> wrap_args
  end

  defp transform_vars str, _state do
    %{str: str, quots: [], reserved: []}
      |> do_transform_vars(:remove_reserved)
      |> do_transform_vars(:remove_quotations)
      |> do_transform_vars(:replace_vars)
      |> do_transform_vars(:restore_quotations)
      |> do_transform_vars(:restore_reserved)
      |> Map.get(:str)
  end

  defp do_transform_vars state = %{str: str}, :remove_reserved do
    re = ~R/~[a-z]+\/.*?\/[a-z]*|(?<=\s)(?:and|or)\s+/u
    reserved = Regex.scan(re, str) |> List.flatten
    str = Regex.replace re, str, "<!reserved!>"
    %{state | str: str, reserved: reserved}
  end

  defp do_transform_vars state = %{str: str}, :remove_quotations  do
    re = ~R/".+?"/u
    quots = Regex.scan(re, str) |> List.flatten
    str = Regex.replace re, str, "<!quot!>"
    %{state | str: str, quots: quots}
  end

  defp do_transform_vars state = %{str: str}, :replace_vars  do
    %{state | str: replace_vars str}
  end

  defp do_transform_vars state, :restore_quotations do
    res = Enum.reduce state.quots, state.str, fn quot, str ->
      quot = transform_sharp_brackets quot, state
      String.replace str, "<!quot!>", quot, global: false
    end
    %{state | str: res}
  end

  defp do_transform_vars state, :restore_reserved do
    res = Enum.reduce state.reserved, state.str, fn reserved, str ->
      String.replace str, "<!reserved!>", reserved, global: false
    end
    %{state | str: res}
  end

  defp replace_vars(str) when str in ~W(true false nil)  do
    str
  end

  defp replace_vars str do
    ~R/([,\(\[\{:\+\-\*\/><=]|^|<>)\s*(\p{L}[\w\.\:-]*)\s*(?=[\+\-\*\/><=,\)\]\}]|!=|\n|$)/u
      |> Regex.replace(str, ~s/\\1val!("\\2",s)\\3/)
  end

  defp transform_sharp_brackets str, state do
    Regex.replace ~R/#\{([\s\S]+?)\}/u, str, fn _match, f1 ->
      f1 = Mappy.transform(f1) |> replace_vars |> extract_funs(state) 
      "\#{#{f1}}"
    end
  end

  defp replace_map str do
    ~R/(?<=[\{,])\s*([\w\.\-]+): *(?=.+?\s*,\s*[\w\.\-]+: +|.*\s*}|$)/u
      |> Regex.replace(str, fn _, f1 -> ~s("#{f1}"=>) end)
  end

  defp wrap_args nil do "[]" end
  defp wrap_args str do ~s/[#{str}]/ end

  defp translate_opts nil, _ do "%{}" end

  defp translate_opts(str, state) when is_bitstring(str) do
    res = (str |> String.strip)
      |> split_opts 
      |> Enum.filter_map(
        fn {"_" <> _, _} -> false; _ -> true end,
        fn {k, v} ->
          ~s("#{k}"=>#{v |> transform_maps |> transform_vars(state)})
        end
      )
      |> Enum.join(",")
    "%{#{res}}"
  end

  defp translate_opts(opts, state) when is_map(opts) do
    res = for {k, v} <- opts, not match?("_" <> _, k) do
      ~s("#{k}"=>#{v |> transform_maps |> inspect_val(state)})
    end |> Enum.join(",")
    "%{#{res}}"
  end

  defp split_opts str do
    ~R/(?:\s+|^)([\w\.\-:]+): +([\s\S]+?)(?=,?\s+[\w\.\-:]+: +|$)/u
      |> Regex.scan(str)
      |> Enum.into(%{}, fn [_, k, v] -> {k, v} end)
  end

  defp transform_maps state = %{cdata: cdata} do
    %{state | cdata: transform_maps cdata}
  end

  defp transform_maps str do
    String.strip(str)
      |> do_transform_maps(:transform_key)
      |> do_transform_maps(:transform_empty)
      |> do_transform_maps(:prepend_head)
  end

  defp do_transform_maps str, :transform_key do
    ~R/(?<!%){(?:\s*[\w\.\-]+: *[\s\S]+?,)*\s*[\w\.\-]*: *[\s\S]*?}/u
      |> Regex.replace(str, &replace_map &1)
  end

  defp do_transform_maps str, :transform_empty do
    ~R/(?<!%){\s*:\s*}/u
      |> Regex.replace(str, "%{}")
  end

  defp do_transform_maps str, :prepend_head do
    ~R/(?<!%){\s*"[\w\.\-]+"\s*=>/u
      |> Regex.replace(str, &("%#{String.strip &1}"))
  end

  defp translate_cdata state do
    lang = annot_data("lang", state)
    do_translate_cdata state, lang
  end

  defp do_translate_cdata state, "pipescript" do
    state
      |> check_pipescript!
      |> write_pipescript
  end

  defp do_translate_cdata state, "javascript" do
    state
      |> check_javascript!
      |> write_javascript
  end

  defp do_translate_cdata state, "coffeescript" do
    state
      |> check_coffeescript!
      |> write_coffeescript
  end

  defp do_translate_cdata state = %{cdata: "|" <> _}, nil do
    cdata = state.annots["cdata"]
    case state.tags |> List.first do
      tag when cdata == nil and tag in ~w(data do fn) ->
        do_translate_cdata state, "pipescript"
      _ ->
        state |> check_cdata! |> write_cdata
    end
  end

  defp do_translate_cdata state, nil do
    state
      |> check_cdata!
      |> write_cdata
  end

  defp do_translate_cdata(state, lang) when is_bitstring(lang) do
    raise Error.InvalidAnnotation, reason: ["@lang", lang], state: state
  end

  defp check_pipescript! state do
    state
  end

  defp check_javascript! state do
    lines = state.cdata |> Lib.lines 
    script = case List.last lines do
      "" -> "return null"
      last -> 
        case Regex.run(~R/ *(?=return\s.+$)/, last) do
          [""] -> state.cdata
          nil -> raise Error.SyntaxError,
            reason: "missed 'return' in Javascript", state: state
          [spaces] ->
            Enum.into(lines, "", & Lib.ltrim(&1, spaces) <> "\n")
        end
    end
    %{state | cdata: script}
  end

  defp check_coffeescript! state do
    check_javascript! state
  end

  defp check_cdata! state do
    state
  end

  defp inspect_val(val = <<hd::8, _::bits>>, _state)
  when hd == ?- or hd in ?0..?9 do
    case Integer.parse(val) do
      {val, ""} -> val
      {from, ".." <> to} ->
        case Integer.parse(to) do
          {to, ""} -> Range.new(from, to) 
          _ -> val
        end
      {_, "." <> _} ->
        case Float.parse(val) do
          {val, ""} -> val
          _ -> val
        end
      _ -> val
    end
    |> inspect
  end

  defp inspect_val str = "[" <> _, state do
    case Regex.match? ~R/^\[.*\]$/u, str do
      true -> str |> transform_vars(state)
      false -> inspect str
    end
  end

  defp inspect_val str = "{" <> _, state do
    case Regex.match? ~R/^\{.*}$/u, str do
      true -> str |> transform_vars(state)
      false -> inspect str
    end
  end

  defp inspect_val str = "%{" <> _, state do
    case Regex.match? ~R/^%\{.*}$/u, str do
      true -> str |> transform_vars(state)
      false -> inspect str
    end
  end

  defp inspect_val "~//" <> str, _ do
    ~s(~S/#{str}/)
  end

  defp inspect_val str, state do
    case Regex.match? ~R/\#{.*?}/u, str do
      true -> ~s/"#{str}"/ |> transform_sharp_brackets(state)
      false when str in ~w(true false nil) -> str
      false -> inspect str
    end
  end

  defp fun_no nil, _ do "" end
    
  defp fun_no fn_id, state do
    fn_id = String.downcase fn_id
    case state.app.funs[fn_id] do
      %App.Fun{} = fun -> fun.no
      nil -> nil
    end
  end

  defp access_from_annots annots do
    with \
      nil <- annots["public"] && :public,
      nil <- annots["private"] && :private,
      do: :protected
  end

  defp set_function_access state, fun_name, access do
    fun_name = String.downcase (fun_name || "")
    case state.app.funs[fun_name] do
      nil -> state
      fun_obj ->
        fun_obj = %{fun_obj| access: access}
        new_funs = Map.put(state.app.funs, fun_name, fun_obj)
        %{state | app: %{state.app | funs: new_funs}}
    end
  end

  defp write_fn state = %{annots: annots} do
    access = access_from_annots annots
    defstr = access == :private && "defp" || "def"
    fun_name = state.opts["_id"] 
    fun_no = fun_no(fun_name, state)
    params = (state.opts["_params"] || "") |> String.replace(",", "")
    opts = state.opts |> Enum.map(fn {k, v} ->
      ~s/{"#{k}", #{v |> transform_maps |> inspect_val(state)}}/
    end) |> Enum.join(",") |> wrap_args
    codes = """
    \n#{space 2}#{defstr} _F#{fun_no} s do  # id: #{state.opts["_id"]}
    #{space 4}data = s
    #{space 4}|> set_args(~w/#{params}/)
    #{space 4}|> set_opts(#{opts})
    """
    state
      |> set_function_access(fun_name, access)
      |> Map.put(:full_codes, state.full_codes <> codes)
  end

  defp write_do state do
    codes = """
    #{indent state}|> (fn s -> data = %{s | line: #{state.line}}
    """
    indents = indents_inc state.indents
    %{state | main_codes: state.main_codes <> codes, indents: indents}
  end

  defp write_pipescript state do
    state
      |> transform_maps
      |> extract_funs
      |> extract_pipes
      |> pipes_to_codes
      |> write_codes
  end

  defp write_javascript state do
    state
      |> do_write_javascript(:define)
      |> do_write_javascript(:call)
  end

  defp write_coffeescript state do
    state
      |> compile_coffeescript
      |> write_javascript
  end

  defp compile_coffeescript state do
    js = Dex.JS.take_handle
    compiled = try do
      Dex.JS.call(js, "CoffeeScript.compile", [state.cdata])
      |> case do
        {:ok, script} -> script
          |> Lib.ltrim("(function() {\n")
          |> Lib.rtrim("}).call(this);\n")
        {:error, reason} -> 
          raise Error.CompileError, reason: inspect(reason), state: state
      end
    after
      Dex.JS.return_handle js
    end
    %{state | cdata: compiled}
  end

  defp do_write_javascript state, :define  do
    params = case state.opts["_params"] do
      nil -> []; "" -> []
      params -> String.split(params, ",")
    end
    opt_keys = state.opts |> valid_opts |> Map.keys
    total_params = ["data" | (params ++ opt_keys)] |> Enum.join(",")
    line_codes = state.line_codes <> "\n" <> """
      defp _L#{state.line} s do
        script = \"\"\"
        function(#{total_params}) {
          #{state.cdata}
        }
        \"\"\" |> String.strip
        run_javascript(s, script, [#{transform_vars total_params, state}])
      end
    """
    %{state | line_codes: line_codes}
  end

  defp do_write_javascript state, :call do
    codes = """
    #{indent state.indents}|> (fn s -> do!(s, #{state.line}, "", &_L#{state.line}/1) end).()
    """
    case List.first(state.tags) do
      "fn" -> %{state | full_codes: state.full_codes <> codes}
      "do" -> %{state | main_codes: state.main_codes <> codes}
    end
  end

  defp write_cdata state do
    state |> write_cdata_codes
  end

  defp write_cdata_codes state do
    state = %{state | line_codes: state.line_codes <> codes_defcdata state}
    case List.first(state.tags) do
      tag when tag in ~w(data do) ->
        %{state | main_codes: state.main_codes <> codes_callcdata state}
      "fn" ->
        %{state | full_codes: state.full_codes <> codes_callcdata state}
      _ -> state
    end
  end

  defp codes_defcdata state do
    cdata = case annot_defined? "cdata", state do
      true ->
        """
        \n#{space 4}[\"\"\"
        #{space 4}#{transform_sharp_brackets state.cdata, state}
        #{space 4}\"\"\" |> String.strip]
        """ |> String.rstrip
      false ->
        translate_args state.cdata, state
    end
    "\n" <> """
      defp _L#{state.line} s do
        _=s; #{cdata}
      end
    """
  end

  defp codes_callcdata state do
    """
    #{indent state.indents}|> (fn s -> do!(s, #{state.line}, "", &Core.set/1, _L#{state.line}(s)) end).()
    """
  end

  defp annot_defined? annot, state do
    state.annots[annot] && true || false
  end

  defp annot_data annot, state do
    state.annots[annot][:data]
  end

  defp write_codes {state, codes} do
    do_write_codes state, {state.fun, codes}
  end

  defp do_write_codes state, {"fn", codes} do
    %{state | full_codes: state.full_codes <> codes}
  end

  defp do_write_codes state, {_, codes} do
    %{state | main_codes: state.main_codes <> codes}
  end

  defp extract_funs(str, state) when is_bitstring(str) do
    do_extract_funs str, 0, state
  end

  defp extract_funs state = %{cdata: cdata} do
    res = do_extract_funs cdata, 0, state
    %{state | cdata: res}
  end

  defp do_extract_funs str, cnt, state do
    regex = ~R/([\w\.\-]*\w+)\(([^\(\)]*)\)/u
    if Regex.match? regex, str do
        Regex.replace(regex, str, fn _, fun, arg_opt ->
          fun_ref = Routes.fn! fun, state
          {args, opts} = split_args_opts(arg_opt)
          args = transform_maps(args) |> wrap_args
          opts = translate_opts opts, state
          "s |> <do!#{state.line}, #{inspect fun}, #{fun_ref}, #{args}, #{opts}!do> |> data!"
        end)
        |> do_extract_funs(cnt+1, state)
    else
        if cnt > 0, do: replace_do!(str), else: str
    end
  end

  defp replace_do! str do
    Regex.replace ~R/<do!|!do>/u, str, fn
      "<do!" -> "do!("
      "!do>" -> ")"
    end
  end

  defp split_args_opts str do
    ~R/(.*?)(?=,? +(\w+: +.+)|$)/u
      |> Regex.scan(str) |> List.first
      |> case do
        [_match, args] -> {args, ""}
        [_match, args, opts] -> {args, opts}
      end
  end

  defp extract_pipes state do
    res = ~R/(?:^|\s)\|\s+(\S+)([\s\S]*?),?(\s+[\w\.\-:]+: +[\s\S]+?)?(?=\s+\|\s+\S+|\s*$)/u
      |> Regex.scan(state.cdata)
      |> Enum.map(fn list ->
        args = (Enum.at(list, 2) || "") 
        opts = (Enum.at(list, 3) || "")
        {fun, line} = Enum.at(list, 1) |> String.downcase |> split_funline(state)
        {fun, args, opts, line}
      end)
      {state, res}
  end

  defp split_funline funline, state do
    case String.split funline, ":" do
      [^funline] -> {funline, state.line}
      [fun, line] -> {fun, line}
    end
  end

  defp indents_inc indents do ["  " | indents] end

  defp space n do String.ljust("", n, ?\s) end

  defp attrs_to_map attrs, _state do
    if attrs == [] do nil else
      Enum.into attrs, %{}, fn
      ({:attribute, name, ns, _, val}) ->
        key = (ns == '' && name || ns ++ ':' ++ name) |> to_string
        val = val |> to_string 
        {key, val}
      end
    end
  end

end

defmodule AssertValue.Formatter do

  import AssertValue.StringTools

  def new_expected_from_actual_value(actual) do
    if is_binary(actual) and length(to_lines(actual)) > 1 do
      format_as_heredoc(actual)
    else
      if Version.match?(System.version, ">= 1.6.5") do
        Macro.to_string(actual)
      else
        format_with_inspect_fix(actual)
      end
    end
  end

  def format_with_indentation(code, indentation, formatter_opts) do
    # 98 is default Elixir line length
    line_length = Keyword.get(formatter_opts, :line_length, 98)
    # Reduce line length to indentation
    # Since we format only assert_value statement, formatter will unindent
    # it as it is the only statement in all code. When we add indentation
    # back, line length may exceed limits.
    line_length = line_length - String.length(indentation)
    formatter_opts = Keyword.put(formatter_opts, :line_length, line_length)

    code =
      code
      |> Code.format_string!(formatter_opts)
      |> IO.iodata_to_binary
      |> to_lines

    auto_parens =
      if System.get_env("ASSERT_VALUE_AUTO_PARENS") == "true" ||
          Keyword.get(formatter_opts, :assert_value_auto_parens, false) do
        max_line_length =
          Enum.reduce(code, 0, fn(line, acc) ->
            len = String.length(line)
            if len > acc do
              len
            else
              acc
            end
          end)
        max_line_length > line_length
      else
        false
      end

    # Try to save some horizontal space by adding parens
    if auto_parens do
      # Remove assert_value from locals_without_parens formatter options
      locals_without_parens =
        formatter_opts
        |> Keyword.get(:locals_without_parens)
        |> Keyword.delete(:assert_value)

      formatter_opts =
        formatter_opts
        |> Keyword.put(:locals_without_parens, locals_without_parens)

      code
      |> Enum.join("\n")
      |> Code.format_string!(formatter_opts)
      |> IO.iodata_to_binary
      |> to_lines

    else
      code
    end
    |> Enum.map(&(indentation <> &1))
    |> Enum.join("\n")
  end

  # Private

  defp format_with_inspect_fix(actual) do
    # Temporary (until Elixir 1.6.5) workaround for Macro.to_string()
    # to make it work with big binaries as suggested on Elixir Forum:
    # https://elixirforum.com/t/how-to-increase-printable-limit/13613
    # Without it big binaries (>4096 symbols) are truncated because of bug
    # in Inspect module.
    # TODO Change to plain Macro.to_string() when we drop support for
    # Elixirs < 1.6.5
    Macro.to_string(actual, fn
      node, _ when is_binary(node) ->
        inspect(node, printable_limit: :infinity)
      _, string ->
        string
    end)
  end

  defp format_as_heredoc(actual) do
    actual =
      actual
      |> add_noeol_if_needed
      |> to_lines
      |> Enum.map(&escape_heredoc_line/1)
    [~s(""")] ++ actual ++ [~s(""")]
    |> Enum.join("\n")
  end

  # Inspect protocol for String has the best implementation
  # of string escaping. Use it, but remove surrounding quotes
  # https://github.com/elixir-lang/elixir/blob/master/lib/elixir/lib/inspect.ex
  defp escape_heredoc_line(s) do
    inspect(s, printable_limit: :infinity)
    |> String.replace(~r/(\A"|"\Z)/, "")
  end

  # to work as a heredoc a string must end with a newline.  For
  # strings that don't we append a special token and a newline when
  # writing them to source file.  This way we can look for this
  # special token when we read it back and strip it at that time.
  defp add_noeol_if_needed(arg) do
    if String.at(arg, -1) == "\n" do
      arg
    else
      arg <> "<NOEOL>\n"
    end
  end

end

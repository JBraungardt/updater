defmodule OutputFormatter do
  @main_branch_names ~w(main master default develop)

  def error(message) do
    IO.ANSI.red() <> message <> IO.ANSI.reset()
  end

  def repo_header(dir, branch) do
    base_dir = File.cwd!()

    branch_color =
      if branch in @main_branch_names do
        IO.ANSI.yellow()
      else
        IO.ANSI.light_red_background() <> IO.ANSI.white()
      end

    branch_text =
      branch_color <>
        "#{branch} " <>
        IO.ANSI.reset()

    IO.ANSI.light_blue() <>
      "=== #{Path.relative_to(dir, base_dir)} on " <>
      branch_text <>
      IO.ANSI.light_blue() <>
      " ===" <>
      IO.ANSI.reset() <>
      "\n"
  end

  def diff(diff) do
    diff
    |> String.split("\n")
    |> Enum.map_join("\n", fn
      "-" <> _ = line -> IO.ANSI.red() <> line <> IO.ANSI.reset()
      "+" <> _ = line -> IO.ANSI.green() <> line <> IO.ANSI.reset()
      line -> line
    end)
  end
end

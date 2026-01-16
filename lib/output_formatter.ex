defmodule OutputFormatter do
  def error(message) do
    IO.ANSI.red() <> message <> IO.ANSI.reset()
  end

  def repo_header(dir, branch) do
    base_dir = File.cwd!()

    branch_color =
      case branch do
        "main" -> IO.ANSI.yellow()
        "master" -> IO.ANSI.yellow()
        "default" -> IO.ANSI.yellow()
        "develop" -> IO.ANSI.yellow()
        _ -> IO.ANSI.light_red_background() <> IO.ANSI.white()
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
    String.split(diff, "\n")
    |> Enum.map(fn line ->
      cond do
        String.starts_with?(line, "-") -> IO.ANSI.red() <> line <> IO.ANSI.reset()
        String.starts_with?(line, "+") -> IO.ANSI.green() <> line <> IO.ANSI.reset()
        true -> line
      end
    end)
    |> Enum.join("\n")
  end
end

defmodule OutputFormatter do
  require Logger

  def error(message) do
    IO.ANSI.red() <> message <> IO.ANSI.reset()
  end

  def repo_header(dir, branch) do
    base_dir = File.cwd!()

    IO.ANSI.light_blue() <>
      "=== #{Path.relative_to(dir, base_dir)} on " <>
      IO.ANSI.yellow() <>
      "#{branch} " <>
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

  def log_verbose(message) do
    if(Application.get_env(:updater, :verbose, false)) do
      Logger.info(message)
    end
  end
end

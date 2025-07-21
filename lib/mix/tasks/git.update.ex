defmodule Mix.Tasks.Git.Update do
  use Mix.Task

  @shortdoc "Updates the repositories"

  @impl true
  def run(args) do
    {opts, _} = OptionParser.parse!(args, strict: [stash: :boolean])
    RepoWorker.process_repos(&process_repo/2, opts)
  end

  defp process_repo(dir, opts) do
    with {:ok, branch} <- GitCommand.current_branch_name(dir),
         :ok <- maybe_stash(dir, opts),
         {:ok, _} <- GitCommand.git(dir, ~w(fetch)) do
      changelog = changelog(dir, branch)
      diff = changes_diff(dir, branch)
      pull = pull(dir)

      maybe_un_stash(dir, opts)

      if String.length(pull) > 0 do
        IO.ANSI.light_blue() <>
          "=== #{Path.relative_to(dir, File.cwd!())} on #{branch} ===\n" <>
          IO.ANSI.reset() <>
          changelog <>
          "\n" <>
          pull <>
          diff <>
          "\n"
      end
    else
      _ -> nil
    end
  end

  defp maybe_stash(dir, opts) do
    if opts[:stash] do
      {state, _} = GitCommand.stash(dir)
      state
    else
      :ok
    end
  end

  defp maybe_un_stash(dir, opts) do
    if opts[:stash] do
      GitCommand.stash_pop(dir)
    end
  end

  defp changelog(dir, branch) do
    with {:ok, changelog} <-
           GitCommand.git(dir, ["log", "#{branch}..origin/#{branch}", "--pretty=format:\"%s\""]) do
      reverse_changelog(changelog) <> "\n"
    else
      _ -> ""
    end
  end

  defp changes_diff(dir, branch) do
    ["CHANGELOG.md", "README.md"]
    |> Enum.map(fn file_name -> file_change_diff(dir, branch, file_name) end)
    |> Enum.filter(&(String.length(&1) > 0))
    |> Enum.join("\n")
  end

  defp file_change_diff(dir, branch, file_name) do
    with {:ok, diff} <-
           GitCommand.git(dir, ["diff", "#{branch}..origin/#{branch}", "--", file_name]),
         true <- String.length(diff) > 0 do
      "\n=== #{file_name} ===\n" <> print_file_diff(diff)
    else
      _ -> ""
    end
  end

  defp print_file_diff(diff) do
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

  def pull(dir) do
    {_, pull_output} = GitCommand.git(dir, ~w(pull))

    up_to_date =
      ["Already up to date.", "Bereits aktuell."]
      |> Enum.any?(&String.contains?(pull_output, &1))

    if up_to_date do
      ""
    else
      pull_output
    end
  end

  defp reverse_changelog(changelog) do
    changelog
    |> String.split("\n")
    |> Enum.reverse()
    |> Enum.join("\n")
  end
end

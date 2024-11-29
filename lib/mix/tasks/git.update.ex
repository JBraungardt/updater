defmodule Mix.Tasks.Git.Update do
  use Mix.Task

  @shortdoc "Updates the repositories"

  @impl true
  def run(_) do
    GitWorker.process_repos(&process_repo/1)
  end

  defp process_repo(dir) do
    base_dir = File.cwd!()
    branch = GitWorker.current_branch_name(dir)

    GitWorker.git(dir, ~w(fetch))

    changelog = changelog(dir, branch)
    diff = changes_diff(dir, branch)
    pull = pull(dir)

    if String.length(pull) > 0 do
      IO.ANSI.light_blue() <>
        "=== #{Path.relative_to(dir, base_dir)} on #{branch} ===\n" <>
        IO.ANSI.reset() <>
        changelog <>
        "\n" <>
        pull <>
        diff <>
        "\n"
    end
  end

  defp changelog(dir, branch) do
    changelog =
      GitWorker.git(dir, ["log", "#{branch}..origin/#{branch}", "--pretty=format:\"%s\""])

    reverse_changelog(changelog) <> "\n"
  end

  defp changes_diff(dir, branch) do
    ["CHANGELOG.md", "README.md"]
    |> Enum.map(fn file_name -> file_change_diff(dir, branch, file_name) end)
    |> Enum.filter(&(String.length(&1) > 0))
    |> Enum.join("\n")
  end

  defp file_change_diff(dir, branch, file_name) do
    diff = GitWorker.git(dir, ["diff", "#{branch}..origin/#{branch}", "--", file_name])

    if String.length(diff) == 0 do
      ""
    else
      "\n=== #{file_name} ===\n" <> print_file_diff(diff)
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
    pull_output = GitWorker.git(dir, ~w(pull))

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

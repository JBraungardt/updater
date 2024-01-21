defmodule Mix.Tasks.Update do
  use Mix.Task

  @shortdoc "Updates the reference repositories"

  @impl true
  def run(_) do
    base_dir = Application.fetch_env!(:updater, :base_dir)

    unless File.exists?(base_dir) do
      Mix.raise("Directory #{base_dir} does not exist")
    end

    unless File.exists?("#{base_dir}/.dicts") do
      Mix.raise("File #{base_dir}/.dicts does not exist")
    end

    File.stream!("#{base_dir}/.dicts")
    |> Enum.map(&String.trim/1)
    |> Enum.flat_map(&collect_repos(&1, base_dir))
    |> Task.async_stream(&process_repo/1,
      timeout: :infinity,
      ordered: false
    )
    |> Enum.each(fn {:ok, output} -> IO.write(output) end)
  end

  defp collect_repos(dir, base_dir) do
    dir = Path.absname(dir, base_dir)

    File.ls!(dir)
    |> Enum.filter(&is_git_dir?("#{dir}/#{&1}/.git"))
    |> Enum.map(&Path.absname(&1, dir))
  end

  defp is_git_dir?(dir) do
    File.dir?(dir)
  end

  defp process_repo(dir) do
    base_dir = Application.fetch_env!(:updater, :base_dir)
    branch = current_branch_name(dir)

    System.cmd("git", ~w(fetch), cd: dir, stderr_to_stdout: true)
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

  defp current_branch_name(dir) do
    {branch, 0} = System.cmd("git", ~w(branch --show-current), cd: dir, stderr_to_stdout: true)
    String.trim(branch)
  end

  defp changelog(dir, branch) do
    {changelog, 0} =
      System.cmd("git", ["log", "#{branch}..origin/#{branch}", "--pretty=format:\"%s\""],
        cd: dir,
        stderr_to_stdout: true
      )

    changelog <> "\n"
  end

  defp changes_diff(dir, branch) do
    ["CHANGELOG.md", "README.md"]
    |> Enum.map(fn file_name -> file_change_diff(dir, branch, file_name) end)
    |> Enum.filter(&(String.length(&1) > 0))
    |> Enum.join("\n")
  end

  defp file_change_diff(dir, branch, file_name) do
    {diff, 0} =
      System.cmd("git", ["diff", "#{branch}..origin/#{branch}", "--", file_name],
        cd: dir,
        stderr_to_stdout: true
      )

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
    {pull_output, 0} = System.cmd("git", ["pull"], cd: dir, stderr_to_stdout: true)

    up_to_date =
      ["Already up to date.", "Bereits aktuell."]
      |> Enum.any?(&String.contains?(pull_output, &1))

    if up_to_date do
      ""
    else
      pull_output
    end
  end
end

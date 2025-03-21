defmodule GitWorker do
  def process_repos(action) do
    base_dir = File.cwd!()

    if File.exists?("#{base_dir}/.dicts") do
      File.stream!("#{base_dir}/.dicts")
      |> Enum.map(&String.trim/1)
      |> Enum.flat_map(&collect_repos(&1, base_dir))
    else
      (Path.wildcard("*/.git", match_dot: true) ++ Path.wildcard("*/*/.git", match_dot: true))
      |> Enum.map(&Path.dirname/1)
      |> Enum.map(&Path.absname(&1, base_dir))
    end
    |> Task.async_stream(action,
      timeout: :infinity,
      ordered: false
    )
    |> Enum.each(fn {:ok, output} -> IO.write(output) end)
  end

  def current_branch_name(dir) do
    if not is_detached?(dir) do
      current_branch(dir)
    end
  end

  def git(repo_dir, args) when is_list(args) do
    {output, exit_code} = System.cmd("git", args, cd: repo_dir, stderr_to_stdout: true)

    if exit_code != 0 do
      IO.write(
        IO.ANSI.red() <>
          "git #{args} failed for #{repo_dir}\n" <>
          IO.ANSI.reset() <>
          output
      )

      exit({:shutdown, 1})
    end

    output
  end

  defp is_detached?(dir) do
    git(dir, ~w(status))
    |> String.split("\n")
    |> Enum.any?(&String.starts_with?(&1, "HEAD detached at"))
  end

  defp current_branch(dir) do
    branch = git(dir, ~w(branch --show-current))
    branch = String.trim(branch)

    if branch == "" do
      current_branch_name(dir)
    else
      branch
    end
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
end

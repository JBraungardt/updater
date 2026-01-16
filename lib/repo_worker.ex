defmodule RepoWorker do
  require Logger

  @doc """
  Processes all repositories using the given RepoTask module.

  ## Parameters

    * `task_module` - A module implementing the `RepoTask` behavior
    * `opts` - A keyword list of options to pass to the task's action/2 callback

  ## Examples

      RepoWorker.process_repos(Mix.Tasks.Git.Status, [])
      RepoWorker.process_repos(Mix.Tasks.Git.Update, stash: true)
  """
  def process_repos(task_module, opts \\ []) do
    base_dir = File.cwd!()

    cond do
      File.dir?("#{base_dir}/.git") ->
        [base_dir]

      File.exists?("#{base_dir}/.dicts") ->
        File.stream!("#{base_dir}/.dicts")
        |> Enum.map(&String.trim/1)
        |> Enum.flat_map(&collect_repos_in_dir(&1, base_dir))

      true ->
        collect_repos_in_dir(".", base_dir)
    end
    |> remove_blacklisted_repos()
    |> Task.async_stream(fn dir -> task_module.action(dir, opts) end,
      timeout: :infinity,
      ordered: false
    )
    |> Enum.each(fn {:ok, output} -> IO.write(output) end)
  end

  defp collect_repos_in_dir(dir, base_dir) do
    Path.absname(dir, base_dir)
    |> find_git_dirs()
    |> Enum.map(&Path.dirname/1)
    |> Enum.map(&Path.absname(&1, base_dir))
  end

  defp find_git_dirs(dir) do
    depth = Application.get_env(:updater, :depth)

    if depth < 1 do
      Logger.error("depth must be greater than 0 got #{depth}")
      raise "depth must be greater than 0"
    end

    Enum.reduce(1..depth, [], fn level, acc ->
      acc ++
        (Path.wildcard("#{dir}/#{String.duplicate("*/", level)}.git", match_dot: true)
         |> Enum.filter(&File.dir?/1))
    end)
  end

  defp remove_blacklisted_repos(repos) do
    black_list_file = Path.join(File.cwd!(), ".ignoreRepos")

    black_list =
      if File.exists?(black_list_file) do
        File.stream!(black_list_file)
        |> Enum.map(&String.trim/1)
      else
        []
      end

    Enum.reject(repos, fn repo ->
      Enum.any?(black_list, &String.ends_with?(repo, &1))
    end)
  end
end

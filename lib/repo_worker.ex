defmodule RepoWorker do
  require Logger

  def process_repos(action, opts \\ []) do
    base_dir = File.cwd!()

    cond do
      File.dir?("#{base_dir}/.git") ->
        [base_dir]

      File.exists?("#{base_dir}/.dicts") ->
        File.stream!("#{base_dir}/.dicts")
        |> Enum.map(&String.trim/1)
        |> Enum.flat_map(&collect_repos(&1, base_dir))

      true ->
        find_git_dirs()
        |> Enum.map(&Path.dirname/1)
        |> Enum.map(&Path.absname(&1, base_dir))
    end
    |> remove_blacklisted_repos()
    |> Task.async_stream(fn dir -> action.(dir, opts) end,
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

  defp find_git_dirs() do
    depth =
      System.get_env("GIT_DIR_SEARCH_DEPTH", "2")
      |> String.to_integer()

    if depth < 1 do
      Logger.error("GIT_DIR_SEARCH_DEPTH must be greater than 0 got #{depth}")
      raise "GIT_DIR_SEARCH_DEPTH must be greater than 0"
    end

    Enum.reduce(1..depth, [], fn level, acc ->
      acc ++
        (Path.wildcard("#{String.duplicate("*/", level)}.git", match_dot: true)
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

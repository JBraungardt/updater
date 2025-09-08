defmodule RepoWorker do
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
        (Path.wildcard("*/.git", match_dot: true) ++ Path.wildcard("*/*/.git", match_dot: true))
        |> Enum.map(&Path.dirname/1)
        |> Enum.map(&Path.absname(&1, base_dir))
    end
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
end

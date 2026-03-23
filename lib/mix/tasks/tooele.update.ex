defmodule Mix.Tasks.Tooele.Update do
  @moduledoc false

  use Mix.Task

  @shortdoc "Update Tooele repositories"

  @impl Mix.Task
  def run(_) do
    Application.put_env(:updater, :depth, 1)

    tooele_dir = File.cwd!()

    RepoWorker.collect_repos_in_dir(".", tooele_dir)
    |> Task.async_stream(&process_repo/1, max_concurrency: 4, timeout: :infinity, ordered: false)
    |> Stream.filter(fn
      {:ok, output} -> !is_nil(output)
      {:error, _} -> false
    end)
    |> Enum.each(fn {:ok, output} -> IO.write(output) end)
  end

  defp process_repo(dir) do
    with {:ok, branch} <- GitCommand.current_branch_name(dir),
         {:ok, pull} <- GitCommand.git(dir, ~w(pull --no-recurse-submodules)),
         {:ok, submodule} <- maybe_update_submodule(dir, pull),
         {:ok, generate} <- maybe_run_generate(dir, pull) do
      OutputFormatter.repo_header(dir, branch) <>
        format_section("PULL:", pull) <>
        format_section("SUBMODULE:", submodule) <>
        format_section("GENERATE:", generate)
    else
      _ -> nil
    end
  end

  defp maybe_update_submodule(dir, pull_output) do
    if up_to_date?(pull_output) do
      {:ok, ""}
    else
      do_update_submodule(dir)
    end
  end

  defp do_update_submodule(dir) do
    case File.exists?(Path.absname(".gitmodules", dir)) do
      true ->
        case GitCommand.git(dir, ~w(submodule update --init)) do
          {:ok, submodule} -> {:ok, submodule}
          _ -> {:ok, "Update of submodules failed"}
        end

      false ->
        {:ok, ""}
    end
  end

  defp maybe_run_generate(dir, pull_output) do
    if up_to_date?(pull_output) do
      {:ok, ""}
    else
      do_run_generate(dir)
    end
  end

  defp do_run_generate(dir) do
    case File.exists?(Path.absname("generate.bat", dir)) do
      true ->
        case System.cmd("cmd", ~w(/d /c generate.bat), cd: dir, stderr_to_stdout: true) do
          {generate, 0} -> {:ok, generate}
          {generate, _exit_code} -> {:ok, "Running generate.bat failed:\n#{generate}"}
        end

      false ->
        {:ok, ""}
    end
  end

  defp up_to_date?(pull_output) when is_binary(pull_output) do
    ["Already up to date.", "Bereits aktuell."]
    |> Enum.any?(&String.contains?(pull_output, &1))
  end

  defp format_section(_title, ""), do: ""

  defp format_section(title, content) do
    OutputFormatter.section(title) <> "\n" <> content <> "\n"
  end
end

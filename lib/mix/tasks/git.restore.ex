defmodule Mix.Tasks.Git.Restore do
  use Mix.Task

  @shortdoc "Revert all changes of the repositories"

  @impl true
  def run(_) do
    GitWorker.process_repos(&restore/2)
  end

  defp restore(dir, _opts) do
    base_dir = File.cwd!()

    with {:ok, branch} <- GitWorker.current_branch_name(dir),
         {:ok, status} <- GitWorker.git(dir, ~w(status --porcelain)),
         true <- String.length(status) > 0,
         {:ok, _} <- GitWorker.git(dir, ~w(restore .)) do
      IO.ANSI.light_blue() <>
        "=== #{Path.relative_to(dir, base_dir)} on #{branch} ===\n" <>
        IO.ANSI.reset() <>
        "restored\n"
    else
      _ -> nil
    end
  end
end

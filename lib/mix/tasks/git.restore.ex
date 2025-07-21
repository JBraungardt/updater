defmodule Mix.Tasks.Git.Restore do
  use Mix.Task

  @shortdoc "Revert all changes of the repositories"

  @impl true
  def run(_) do
    RepoWorker.process_repos(&restore/2)
  end

  defp restore(dir, _opts) do
    base_dir = File.cwd!()

    with {:ok, branch} <- GitCommand.current_branch_name(dir),
         {:ok, status} <- GitCommand.status(dir),
         true <- String.length(status) > 0,
         {:ok, _} <- GitCommand.git(dir, ~w(restore .)) do
      IO.ANSI.light_blue() <>
        "=== #{Path.relative_to(dir, base_dir)} on #{branch} ===\n" <>
        IO.ANSI.reset() <>
        "restored\n"
    else
      _ -> nil
    end
  end
end

defmodule Mix.Tasks.Git.Restore do
  use Mix.Task

  @shortdoc "Revert all changes of the repositories"

  @impl true
  def run(_) do
    GitWorker.process_repos(&restore/1)
  end

  defp restore(dir) do
    {_output, 0} = System.cmd("git", ~w(restore .), cd: dir, stderr_to_stdout: true)
  end
end

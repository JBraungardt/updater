defmodule Mix.Tasks.Git.Branch do
  use Mix.Task

  @shortdoc "List the current branch of the repos"

  @impl true
  def run(_) do
    RepoWorker.process_repos(&branch/2)
  end

  defp branch(dir, _opts) do
    with {:ok, branch} <- GitCommand.current_branch_name(dir) do
      OutputFormatter.repo_header(dir, branch)
    else
      _ -> nil
    end
  end
end

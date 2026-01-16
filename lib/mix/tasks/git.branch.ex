defmodule Mix.Tasks.Git.Branch do
  use RepoTask

  @shortdoc "List the current branch of the repos"

  @impl RepoTask
  def action(dir, _opts) do
    with {:ok, branch} <- GitCommand.current_branch_name(dir) do
      OutputFormatter.repo_header(dir, branch)
    else
      _ -> nil
    end
  end
end

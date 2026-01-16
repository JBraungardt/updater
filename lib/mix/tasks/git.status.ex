defmodule Mix.Tasks.Git.Status do
  use RepoTask

  @shortdoc "Shows the status of the repositories"

  @impl RepoTask
  def action(dir, _opts) do
    with {:ok, branch} <- GitCommand.current_branch_name(dir),
         {:ok, status} <- GitCommand.status(dir),
         true <- String.length(status) > 0 do
      OutputFormatter.repo_header(dir, branch) <> status
    else
      _ -> nil
    end
  end
end

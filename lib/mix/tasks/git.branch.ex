defmodule Mix.Tasks.Git.Branch do
  @moduledoc false

  use RepoTask

  @shortdoc "List the current branch of the repos"

  @impl RepoTask
  def action(dir, _opts) do
    case GitCommand.current_branch_name(dir) do
      {:ok, branch} ->
        OutputFormatter.repo_header(dir, branch)

      _ ->
        nil
    end
  end
end

defmodule Mix.Tasks.Git.Status do
  use Mix.Task

  @shortdoc "Shows the status of the repositories"

  @impl true
  def run(args) do
    StartArgs.parse(args)

    RepoWorker.process_repos(&get_status/2)
  end

  defp get_status(dir, _opts) do
    with {:ok, branch} <- GitCommand.current_branch_name(dir),
         {:ok, status} <- GitCommand.status(dir),
         true <- String.length(status) > 0 do
      OutputFormatter.repo_header(dir, branch) <> status
    else
      _ -> nil
    end
  end
end

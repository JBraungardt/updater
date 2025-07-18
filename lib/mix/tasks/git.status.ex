defmodule Mix.Tasks.Git.Status do
  use Mix.Task

  @shortdoc "Shows the status of the repositories"

  @impl true
  def run(_) do
    GitWorker.process_repos(&get_status/2)
  end

  defp get_status(dir, _opts) do
    base_dir = File.cwd!()
    branch = GitWorker.current_branch_name(dir)

    status = GitWorker.git(dir, ~w(status --porcelain))

    if String.length(status) > 0 do
      IO.ANSI.light_blue() <>
        "=== #{Path.relative_to(dir, base_dir)} on #{branch} ===\n" <>
        IO.ANSI.reset() <>
        status
    end
  end
end

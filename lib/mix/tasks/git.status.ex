defmodule Mix.Tasks.Git.Status do
  use Mix.Task

  @shortdoc "Shows the status of the repositories"

  @impl true
  def run(_) do
    GitWorker.process_repos(&get_status/1)
  end

  defp get_status(dir) do
    base_dir = File.cwd!()
    branch = GitWorker.current_branch_name(dir)

    {status, 0} = System.cmd("git", ~w(status --porcelain), cd: dir, stderr_to_stdout: true)

    if String.length(status) > 0 do
      IO.ANSI.light_blue() <>
        "=== #{Path.relative_to(dir, base_dir)} on #{branch} ===\n" <>
        IO.ANSI.reset() <>
        status
    end
  end
end

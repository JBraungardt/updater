defmodule Mix.Tasks.Git.Restore do
  use Mix.Task

  @shortdoc "Revert all changes of the repositories"

  @impl true
  def run(_) do
    GitWorker.process_repos(&restore/1)
  end

  defp restore(dir) do
    base_dir = File.cwd!()
    branch = GitWorker.current_branch_name(dir)

    {status, 0} = System.cmd("git", ~w(status --porcelain), cd: dir, stderr_to_stdout: true)

    if String.length(status) > 0 do
      {_output, 0} = System.cmd("git", ~w(restore .), cd: dir, stderr_to_stdout: true)

      IO.ANSI.light_blue() <>
        "=== #{Path.relative_to(dir, base_dir)} on #{branch} ===\n" <>
        IO.ANSI.reset() <>
        "restored"
    end
  end
end

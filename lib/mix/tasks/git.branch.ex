defmodule Mix.Tasks.Git.Branch do
  use Mix.Task

  @shortdoc "List the current branch of the repos"

  @impl true
  def run(_) do
    GitWorker.process_repos(&branch/2)
  end

  defp branch(dir, _opts) do
    base_dir = File.cwd!()
    branch = GitWorker.current_branch_name(dir)

    IO.ANSI.light_blue() <>
      "=== #{Path.relative_to(dir, base_dir)} on " <>
      IO.ANSI.yellow() <>
      "#{branch} " <>
      IO.ANSI.light_blue() <>
      " ===\n" <>
      IO.ANSI.reset()
  end
end

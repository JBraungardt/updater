defmodule Updater.CLI do
  @moduledoc false

  @commands ~w(branch explain msg restore status update help)

  def main(args) do
    Application.ensure_all_started(:logger)

    case args do
      [] ->
        print_usage()

      ["help" | _rest] ->
        print_usage()

      [command | rest] ->
        dispatch(command, rest)
    end
  end

  defp dispatch("status", rest) do
    opts = StartArgs.parse(rest)
    RepoWorker.process_repos(Mix.Tasks.Git.Status, opts)
  end

  defp dispatch("update", rest) do
    opts = StartArgs.parse(rest, stash: :boolean, explain: :boolean)
    RepoWorker.process_repos(Mix.Tasks.Git.Update, opts)
  end

  defp dispatch("restore", rest) do
    opts = StartArgs.parse(rest)
    RepoWorker.process_repos(Mix.Tasks.Git.Restore, opts)
  end

  defp dispatch("branch", rest) do
    opts = StartArgs.parse(rest)
    RepoWorker.process_repos(Mix.Tasks.Git.Branch, opts)
  end

  defp dispatch("explain", rest) do
    opts = StartArgs.parse(rest, range: :string)
    range = Keyword.get(opts, :range)

    ExplainChanges.generate_explanation(".", range)
    |> IO.write()
  end

  defp dispatch("msg", rest) do
    _opts = StartArgs.parse(rest)

    {:ok, _} = GitCommand.git(".", ~w(add -N .))
    {:ok, diff} = GitCommand.git(".", ~w(diff -U500))

    """
    You are a git commit message generator.
    Write a single line commit message following Conventional Commits (feat, fix, docs, style, refactor, test, chore) based on this diff.
    Do NOT use markdown.
    Do NOT explain.
    Just the message.

    #{diff}
    """
    |> Ollama.call()
    |> elem(1)
    |> IO.write()
  end

  defp dispatch(_command, _rest) do
    print_usage()
  end

  defp print_usage do
    message = """
    usage: updater <command> [options]

    commands:
      branch   List the current branch of the repos
      explain  Explain git commits (use --range)
      msg      Generate commit message for current repo
      restore  Revert all changes of the repositories
      status   Shows the status of the repositories
      update   Updates the repositories (use --stash, --explain)

    global options:
      --verbose
      --depth N
    """

    IO.write(message)
  end
end

defmodule Mix.Tasks.Git.Msg do
  use Mix.Task

  @shortdoc "Generate commit message for the changes in current git repo"

  @impl Mix.Task
  def run(_) do
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
end

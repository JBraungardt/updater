defmodule Mix.Tasks.Git.Msg do
  use Mix.Task

  @shortdoc "Generate commit message for the changes in current git repo"

  @impl Mix.Task
  def run(_) do
    {:ok, _} = GitCommand.git(".", ~w(add -N .))
    {:ok, diff} = GitCommand.git(".", ~w(diff -U500))

    """
    Please give me a concise and short git commit message for the following changes.
    The message shoul consists of one short line as the summery followed by an empty line
    followed by a more detailed explanation. DO NOT USE ANY MARKDOWN IN OUTPUT!

    #{diff}
    """
    |> Ollama.call()
    |> elem(1)
    |> IO.write()
  end
end

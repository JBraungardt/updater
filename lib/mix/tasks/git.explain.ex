defmodule Mix.Tasks.Git.Explain do
  use Mix.Task

  @shortdoc "Explain git commits"

  @impl Mix.Task
  def run(args) do
    {opts, _} = OptionParser.parse!(args, strict: [range: :string])
    range = Keyword.get(opts, :range)

    ExplainChanges.generate_explanation(".", range)
    |> IO.write()
  end
end

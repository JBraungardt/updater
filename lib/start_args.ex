defmodule StartArgs do
  def parse(args, params \\ []) do
    {opts, _} = OptionParser.parse!(args, strict: [verbose: :boolean, depth: :integer] ++ params)

    if opts[:verbose] do
      Application.put_env(:updater, :verbose, true)
    end

    Application.put_env(:updater, :depth, Keyword.get(opts, :depth, 2))

    opts
  end
end

defmodule StartArgs do
  def parse(args, params \\ []) do
    {opts, _} = OptionParser.parse!(args, strict: [verbose: :boolean] ++ params)

    if opts[:verbose] do
      Application.put_env(:updater, :verbose, true)
    end

    opts
  end
end

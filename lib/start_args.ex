defmodule StartArgs do
  @moduledoc """
  Handles command-line argument parsing and global configuration for the `:updater` application.

  This module serves as the entry point for configuring the runtime environment.
  It maps command-line flags (e.g., `--verbose`) directly to Application environment
  variables.
  """

  @strict_config [verbose: :boolean, depth: :integer]

  @doc """
  Parses command-line arguments and updates the Application environment.

  It parses `args` based on a strict configuration `@strict_config`.
  Any additional strict configuration options can be passed via `extra_strict`.

  ## Side Effects

  This function performs **side effects**. It directly updates the `:updater` application
  environment using `Application.put_env/3`:
  """
  def parse(args, extra_strict \\ []) do
    strict_opts = Keyword.merge(@strict_config, extra_strict)

    {opts, _remaining} = OptionParser.parse!(args, strict: strict_opts)

    verbose = Keyword.get(opts, :verbose, false)
    depth = Keyword.get(opts, :depth, 2)

    Application.put_env(:updater, :verbose, verbose)
    Application.put_env(:updater, :depth, depth)

    opts
  end
end

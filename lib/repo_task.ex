defmodule RepoTask do
  @moduledoc """
  Behavior and macro for Mix tasks that operate on git repositories.

  This module provides a common interface for all repository-related Mix tasks.
  Tasks that `use RepoTask` automatically get a `run/1` function that:

  1. Parses command-line arguments using `StartArgs.parse/2`
  2. Calls `RepoWorker.process_repos/2` with the task module and parsed options

  Each task only needs to implement the `action/2` callback which defines
  the operation to perform on each repository.

  ## Example (simple task with no parameters)

      defmodule Mix.Tasks.Git.Branch do
        use RepoTask

        @shortdoc "List the current branch of the repos"

        @impl RepoTask
        def action(dir, _opts) do
          with {:ok, branch} <- GitCommand.current_branch_name(dir) do
            OutputFormatter.repo_header(dir, branch)
          else
            _ -> nil
          end
        end
      end

  ## Example (task with custom parameters)

      defmodule Mix.Tasks.Git.Update do
        use RepoTask, params: [stash: :boolean]

        @shortdoc "Updates the repositories"

        @impl RepoTask
        def action(dir, opts) do
          # opts[:stash] will be available here
          ...
        end
      end
  """

  @doc """
  Performs an action on a single repository.

  ## Parameters

    * `dir` - The absolute path to the repository directory
    * `opts` - A keyword list of options parsed from command-line arguments

  ## Returns

    * A string containing output to be displayed, or
    * `nil` if there is no output for this repository
  """
  @callback action(dir :: String.t(), opts :: Keyword.t()) :: String.t() | nil

  @doc false
  defmacro __using__(opts \\ []) do
    params = Keyword.get(opts, :params, [])

    quote do
      @behaviour RepoTask
      use Mix.Task

      @params unquote(params)

      @impl Mix.Task
      def run(args) do
        opts = StartArgs.parse(args, @params)
        RepoWorker.process_repos(__MODULE__, opts)
      end
    end
  end
end

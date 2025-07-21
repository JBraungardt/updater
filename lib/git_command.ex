defmodule GitCommand do
  def git(repo_dir, args) when is_list(args) do
    {output, exit_code} = System.cmd("git", args, cd: repo_dir, stderr_to_stdout: true)

    if exit_code != 0 do
      IO.write(
        IO.ANSI.red() <>
          "git #{args} failed for #{repo_dir}\n" <>
          IO.ANSI.reset() <>
          output
      )

      {:error, output}
    end

    {:ok, output}
  end

  def status(dir) do
    git(dir, ~w(status --porcelain))
  end

  def current_branch_name(dir) do
    if is_detached?(dir) do
      {:error, "HEAD detached"}
    else
      current_branch(dir)
    end
  end

  def stash(dir) do
    with {:ok, status} <- status(dir),
         true <- String.length(status) > 0 do
      git(dir, ~w(stash))
    else
      _ -> {:error, "Stash failed"}
    end
  end

  def stash_pop(dir) do
    if stash_count(dir) > 0 do
      git(dir, ~w(stash pop))
    else
      :ok
    end
  end

  defp stash_count(dir) do
    with {:ok, output} <- GitCommand.git(dir, ~w(stash list)) do
      output
      |> String.split("\n")
      |> Enum.count(&(String.length(&1) > 0))
    else
      _ -> 0
    end
  end

  defp is_detached?(dir) do
    with {:ok, output} <- git(dir, ~w(status)) do
      output
      |> String.split("\n")
      |> Enum.any?(&String.starts_with?(&1, "HEAD detached at"))
    else
      _ -> false
    end
  end

  defp current_branch(dir) do
    with {:ok, branch} <- git(dir, ~w(branch --show-current)) do
      branch = String.trim(branch)

      if branch == "" do
        current_branch_name(dir)
      else
        {:ok, branch}
      end
    end
  end
end

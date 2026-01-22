defmodule ExplainChanges do
  require Logger

  @diff_context_lines 500
  @system_prompt """
  You are a helpful assistant. Output your answer in plain text only.
  Do not use Markdown formatting (no bold, italics, or headers).
  DO NOT CALL ANY TOOL!
  DO NOT OUTPUT MARKDOWN SYNTAX!
  """

  def maybe_explain(dir, range, opts) do
    if opts[:explain] do
      generate_explanation(dir, range)
    else
      ""
    end
  end

  def generate_explanation(dir, range) do
    with {:ok, changelog} <- GitCommand.git(dir, ["log", range, "--pretty=format:\"* %B\""]),
         {:ok, diff} <- GitCommand.git(dir, ["diff", range, "-U#{@diff_context_lines}"]),
         false <- empty_content?(changelog, diff),
         {:ok, explanation} <- ask_ollama(changelog, diff) do
      "\n\n" <> explanation <> "\n"
    else
      :empty_content ->
        ""

      {:error, reason} ->
        Logger.warning("Explanation failed: #{inspect(reason)}")
        ""

      _ ->
        ""
    end
  end

  defp empty_content?(changelog, diff) do
    if changelog == "" or diff == "" do
      :empty_content
    else
      false
    end
  end

  defp ask_ollama(changelog, diff) do
    """
    #{@system_prompt}

    #{Utf8Sanitizer.sanitize(changelog)}

    with this diff
    ```diff
    #{Utf8Sanitizer.sanitize(diff)}
    ```

    DO NOT OUTPUT MARKDOWN SYNTAX!
    """
    |> Ollama.call()
  end
end

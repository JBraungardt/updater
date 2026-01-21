defmodule ExplainChanges do
  require Logger

  @ollama_endpoint "http://localhost:11434/api/generate"
  @model "gpt-oss:20b"
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
    prompt =
      """
      #{@system_prompt}

      #{Utf8Sanitizer.sanitize(changelog)}

      with this diff
      ```diff
      #{Utf8Sanitizer.sanitize(diff)}
      ```

      DO NOT OUTPUT MARKDOWN SYNTAX!
      """

    payload = %{
      model: @model,
      prompt: prompt,
      stream: false
    }

    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    headers = [{~c"content-type", ~c"application/json"}]

    request =
      {String.to_charlist(@ollama_endpoint), headers, ~c"application/json", JSON.encode!(payload)}

    case :httpc.request(:post, request, [], body_format: :binary) do
      {:ok, {{_ver, 200, _msg}, _headers, response_body}} ->
        %{"response" => content} = JSON.decode!(response_body)
        {:ok, "\n\n" <> content <> "\n"}

      {:ok, {{_ver, status, _msg}, _headers, body}} ->
        {:error, "Ollama API Error: #{status} - #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end

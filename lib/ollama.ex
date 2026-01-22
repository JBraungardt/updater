defmodule Ollama do
  @ollama_endpoint "http://localhost:11434/api/generate"
  @model "gpt-oss:20b"

  def call(prompt) do
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
        {:ok, "\n" <> content <> "\n"}

      {:ok, {{_ver, status, _msg}, _headers, body}} ->
        {:error, "Ollama API Error: #{status} - #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end

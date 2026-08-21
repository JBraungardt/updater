defmodule Mix.Tasks.Tooele.Mirror do
  @moduledoc false

  use Mix.Task

  @shortdoc "En/Disables the usage of the gitlab mirror repositories"

  @config_file "~/.git_config_tooele"

  @impl true
  def run(args) do
    {opts, []} = OptionParser.parse!(args, strict: [on: :boolean, off: :boolean, mirror: :boolean])

    enable? = Enum.any?(opts, &(&1 in [on: true, mirror: true]))
    disable? = Enum.any?(opts, &(&1 in [off: true, mirror: false]))

    case {enable?, disable?} do
      {true, false} ->
        use_mirror(true)

      {false, true} ->
        use_mirror(false)

      {false, false} ->
        check_mirror()

      {true, true} ->
        Mix.raise(
          "Cannot combine mirror enable options (--on, --mirror) with disable options (--off, --no-mirror)"
        )
    end
  end

  defp check_mirror() do
    Mix.shell().info("Mirror is #{File.exists?(Path.expand(@config_file))}")
  end

  defp use_mirror(false) do
    path = Path.expand(@config_file)

    if File.exists?(path) do
      case File.rm(path) do
        :ok ->
          Mix.shell().info("Removed #{path}")

        {:error, reason} ->
          Mix.shell().error("Failed to remove #{path}: #{inspect(reason)}")
      end
    else
      Mix.shell().info("No mirror config found at #{path}")
    end

  end

  defp use_mirror(true) do
    path = Path.expand(@config_file)
    url = "http://tooele-repo.mevis.lokal/git-config"

    _ = :inets.start()

    case :httpc.request(:get, {String.to_charlist(url), []}, [], [{:body_format, :binary}]) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        case File.write(path, body) do
          :ok ->
            Mix.shell().info("Wrote #{path}")

          {:error, reason} ->
            Mix.shell().error("Failed to write #{path}: #{inspect(reason)}")
        end

      {:ok, {{_, status, _}, _headers, _body}} ->
        Mix.shell().error("Failed to fetch #{url}: HTTP #{status}")

      {:error, reason} ->
        Mix.shell().error("Failed to fetch #{url}: #{inspect(reason)}")
    end

  end

end

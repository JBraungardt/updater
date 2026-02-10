defmodule VerboseLogger do
  @moduledoc false

  require Logger

  def log(message) do
    if Application.get_env(:updater, :verbose, false) do
      Logger.info(to_string(message))
    end
  end
end

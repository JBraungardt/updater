defmodule Utf8Sanitizer do
  @moduledoc false

  @replacement <<0xFFFD::utf8>>

  def sanitize(binary) do
    if String.valid?(binary) do
      binary
    else
      binary
      |> do_sanitize([])
      |> IO.iodata_to_binary()
    end
  end

  defp do_sanitize(binary, acc) do
    # This scans the string until it hits an error.
    case :unicode.characters_to_binary(binary, :utf8, :utf8) do
      # The rest of the string is valid; append it and finish.
      valid when is_binary(valid) ->
        [acc, valid]

      # We hit an invalid byte.
      # `valid` is the good chunk we scanned so far.
      # `rest` contains the remaining binary starting with the bad byte.
      {:error, valid, <<_bad_byte, rest::binary>>} ->
        # Append the valid chunk, the replacement char,
        # skip the bad byte, and recurse on the rest.
        do_sanitize(rest, [acc, valid, @replacement])

      # The string ends with an incomplete UTF-8 sequence (e.g., a cut-off multibyte char).
      {:incomplete, valid, _rest} ->
        [acc, valid, @replacement]
    end
  end
end

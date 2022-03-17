defmodule XtbClient.Messages.KeepAlive do
  @enforce_keys [:timestamp]

  @derive Jason.Encoder
  defstruct timestamp: nil

  def new(%{"timestamp" => timestamp_value}) when is_integer(timestamp_value) do
    %__MODULE__{
      timestamp: DateTime.from_unix!(timestamp_value, :millisecond)
    }
  end

  def match(method, data) when method in ["getKeepAlive"] do
    {:ok, __MODULE__.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end

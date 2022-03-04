defmodule XtbClient.Messages.ServerTime do
  @enforce_keys [:time, :time_string]

  @derive Jason.Encoder
  defstruct time: nil,
            time_string: ""

  def new(%{
        "time" => time_value,
        "timeString" => time_string
      })
      when is_number(time_value) and is_binary(time_string) do
    %__MODULE__{
      time: DateTime.from_unix!(time_value, :millisecond),
      time_string: time_string
    }
  end

  def match(%{"time" => _, "timeString" => _} = data) when map_size(data) == 2 do
    {:ok, __MODULE__.new(data)}
  end

  def match(_data) do
    {:no_match}
  end
end
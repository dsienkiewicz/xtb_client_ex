defmodule XtbClient.Messages.ServerTime do
  @moduledoc """
  Info about current time on trading server.
  """

  @type t :: %__MODULE__{
          time: DateTime.t(),
          time_string: binary()
        }

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

  def match(method, data) when method in ["getServerTime"] do
    {:ok, __MODULE__.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end

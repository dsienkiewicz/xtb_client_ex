defmodule XtbClient.Messages.ServerTime do
  @moduledoc """
  Info about current time on trading server.

  ## Parameters
  - `time` actual time on server,
  - `time_string` string version of `time` value.

  ## Handled Api methods
  - `getServerTime`
  """

  @type t :: %__MODULE__{
          time: DateTime.t(),
          time_string: String.t()
        }

  @enforce_keys [:time, :time_string]
  @derive Jason.Encoder
  defstruct time: nil,
            time_string: ""

  def new(%{
        "time" => time_value,
        "timeString" => time_string
      })
      when is_number(time_value) do
    %__MODULE__{
      time: DateTime.from_unix!(time_value, :millisecond),
      time_string: time_string || ""
    }
  end
end

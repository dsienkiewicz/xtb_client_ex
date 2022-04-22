defmodule XtbClient.Messages.KeepAlive do
  @moduledoc """
  Info representing response from the server sent to keep alive command.
  
  ## Parameters
  - `timestamp` current timestamp.
  
  ## Handled Api methods
  - `getKeepAlive`
  """

  @type t :: %__MODULE__{
          timestamp: DateTime.t()
        }

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

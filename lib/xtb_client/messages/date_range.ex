defmodule XtbClient.Messages.DateRange do
  @moduledoc """
  Info about time range - stores `start` and `end` information as milliseconds in Unix format.
  """

  @type t :: %__MODULE__{
          start: integer(),
          end: integer()
        }

  @enforce_keys [:start, :end]

  @derive Jason.Encoder
  defstruct start: nil,
            end: nil

  def new(%{from: from, to: to}) when not is_nil(from) and not is_nil(to) do
    %__MODULE__{
      start: DateTime.to_unix(from, :millisecond),
      end: DateTime.to_unix(to, :millisecond)
    }
  end
end

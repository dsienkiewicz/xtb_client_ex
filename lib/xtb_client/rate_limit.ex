defmodule XtbClient.RateLimit do
  @moduledoc """
  Helper module for handling with rate limits.
  """

  @type t :: %__MODULE__{
          limit_interval: integer(),
          time_stamp: integer()
        }

  @enforce_keys [:limit_interval, :time_stamp]
  @derive Jason.Encoder
  defstruct limit_interval: 200,
            time_stamp: 0

  @doc """
  Creates a new rate limit with given limit interval.
  """
  @spec new(integer()) :: t()
  def new(limit_interval) when is_integer(limit_interval) and limit_interval > 0 do
    %__MODULE__{
      limit_interval: limit_interval,
      time_stamp: 0
    }
  end

  @doc """
  Checks if the rate limit is exceeded and if so, sleeps for the difference.
  """
  @spec check_rate(t()) :: t()
  def check_rate(%__MODULE__{limit_interval: limit_interval, time_stamp: previous_stamp} = limit) do
    current_stamp = actual_rate()
    rate_diff = current_stamp - previous_stamp

    case rate_diff > limit_interval do
      true ->
        %{limit | time_stamp: current_stamp}

      false ->
        Process.sleep(rate_diff)
        %{limit | time_stamp: actual_rate()}
    end
  end

  defp actual_rate do
    DateTime.to_unix(DateTime.utc_now(), :millisecond)
  end
end

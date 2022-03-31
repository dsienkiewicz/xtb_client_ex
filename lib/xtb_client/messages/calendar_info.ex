defmodule XtbClient.Messages.CalendarInfo do
  @moduledoc """
  Calendar event, described by properties:
  - `country` two letter country code,
  - `current` market value (current), empty before time of release of this value (time from "time" record),
  - `forecast` forecasted value,
  - `impact` impact on market,
  - `period` information period,
  - `previous` value from previous information release,
  - `time` time, when the information will be released (in this time empty "current" value should be changed with exact released value),
  - `title` name of the indicator for which values will be released.
  """

  @type t :: %__MODULE__{
          country: binary(),
          current: binary(),
          forecast: binary(),
          impact: binary(),
          period: binary(),
          previous: binary(),
          time: DateTime.t(),
          title: binary()
        }

  @enforce_keys [:country, :current, :forecast, :impact, :period, :previous, :time, :title]

  @derive Jason.Encoder
  defstruct country: "",
            current: "",
            forecast: "",
            impact: "",
            period: "",
            previous: "",
            time: nil,
            title: ""

  def new(%{
        "country" => country,
        "current" => current,
        "forecast" => forecast,
        "impact" => impact,
        "period" => period,
        "previous" => previous,
        "time" => time_value,
        "title" => title
      })
      when is_binary(country) and is_binary(current) and is_binary(forecast) and
             is_binary(impact) and is_binary(period) and is_binary(previous) and
             is_number(time_value) and is_binary(title) do
    %__MODULE__{
      country: country,
      current: current,
      forecast: forecast,
      impact: impact,
      period: period,
      previous: previous,
      time: DateTime.from_unix!(time_value, :millisecond),
      title: title
    }
  end
end

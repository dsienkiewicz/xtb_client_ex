defmodule XtbClient.Messages.CalendarInfo do
  @moduledoc """
  Calendar event.

  ## Parameters
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
          country: String.t(),
          current: String.t(),
          forecast: String.t(),
          impact: String.t(),
          period: String.t(),
          previous: String.t(),
          time: DateTime.t(),
          title: String.t()
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
      }) do
    %__MODULE__{
      country: country || "",
      current: current || "",
      forecast: forecast || "",
      impact: impact || "",
      period: period || "",
      previous: previous || "",
      time: DateTime.from_unix!(time_value, :millisecond),
      title: title || ""
    }
  end
end

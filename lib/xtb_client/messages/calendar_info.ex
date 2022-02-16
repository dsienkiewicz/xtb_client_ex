defmodule XtbClient.Messages.CalendarInfo do
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

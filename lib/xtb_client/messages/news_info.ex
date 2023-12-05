defmodule XtbClient.Messages.NewsInfo do
  @moduledoc """
  Info about recent news.

  ## Properties
  - `body` body of message,
  - `body_length` body length,
  - `key` news key,
  - `time` time of news,
  - `time_string` string version of `time`,
  - `title` news title.
  """

  @type t :: %__MODULE__{
          body: String.t(),
          body_length: integer(),
          key: String.t(),
          time: DateTime.t(),
          time_string: String.t(),
          title: String.t()
        }

  @enforce_keys [:body, :body_length, :key, :time, :time_string, :title]
  @derive Jason.Encoder
  defstruct body: "",
            body_length: 0,
            key: "",
            time: nil,
            time_string: "",
            title: ""

  def new(
        %{
          "bodylen" => body_length,
          "timeString" => time_string
        } = args
      )
      when is_number(body_length) do
    value = args |> Map.drop(["bodylen", "timeString"]) |> new()

    %{
      value
      | body_length: body_length,
        time_string: time_string || ""
    }
  end

  def new(%{
        "body" => body,
        "key" => key,
        "time" => time_value,
        "title" => title
      })
      when is_number(time_value) do
    %__MODULE__{
      body: body || "",
      body_length: String.length(body),
      key: key || "",
      time: DateTime.from_unix!(time_value, :millisecond),
      time_string: "",
      title: title || ""
    }
  end
end

defmodule XtbClient.Messages.NewsInfo do
  @enforce_keys [:body, :body_length, :key, :time, :time_string, :title]

  @derive Jason.Encoder
  defstruct body: "",
            body_length: 0,
            key: "",
            time: nil,
            time_string: "",
            title: ""

  def new(%{
        "body" => body,
        "bodylen" => body_length,
        "key" => key,
        "time" => time_value,
        "timeString" => time_string,
        "title" => title
      })
      when is_binary(body) and is_number(body_length) and
             is_binary(key) and is_number(time_value) and is_binary(time_string) and
             is_binary(title) do
    %__MODULE__{
      body: body,
      body_length: body_length,
      key: key,
      time: DateTime.from_unix!(time_value, :millisecond),
      time_string: time_string,
      title: title
    }
  end
end

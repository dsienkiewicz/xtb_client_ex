defmodule XtbClient.StreamingMessage do
  @moduledoc """
  Helper module for encoding and decoding streaming messages.
  """

  @type t :: %__MODULE__{
          method: String.t(),
          response_method: String.t(),
          metadata: map(),
          params: map() | nil
        }

  @enforce_keys [:method, :response_method, :metadata, :params]
  defstruct method: "",
            response_method: "",
            metadata: %{},
            params: nil

  def new(method, response_method, metadata, params \\ nil) do
    %__MODULE__{
      method: method,
      response_method: response_method,
      metadata: metadata,
      params: params
    }
  end

  def get_method_name(%__MODULE__{method: method_name}) do
    method_name
  end

  def get_metadata(%__MODULE__{metadata: metadata}) do
    metadata
  end
end

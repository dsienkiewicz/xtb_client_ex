defmodule XtbClient.StreamingMessage do
  @type t :: %__MODULE__{
          method: binary(),
          response_method: binary(),
          params: map() | nil
        }
  @type token :: {:method, binary()} | {:hashed_params, binary(), binary()}

  defstruct method: "",
            response_method: "",
            params: nil

  def new(method, response_method, params \\ nil) do
    %__MODULE__{
      method: method,
      response_method: response_method,
      params: params
    }
  end

  def encode_token("getTrades" = method_name, _params) do
    {:method, method_name}
  end

  def encode_token(method_name, %{symbol: symbol} = _params) do
    {:hashed_params, method_name, symbol}
  end

  def encode_token(method_name, _) do
    {:method, method_name}
  end

  def decode_method_name({:method, method}) do
    method
  end

  def decode_method_name({:hashed_params, method, _symbol}) do
    method
  end
end

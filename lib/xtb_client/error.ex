defmodule XtbClient.Error do
  @moduledoc """
  Struct to represent errors returned by the XTB API
  """

  @type t :: %__MODULE__{
          code: String.t(),
          message: String.t()
        }

  @enforce_keys [:code, :message]
  defstruct [:code, :message]

  def new!(%{
        "errorCode" => code,
        "errorDescr" => message
      }) do
    %__MODULE__{
      code: code,
      message: message
    }
  end
end

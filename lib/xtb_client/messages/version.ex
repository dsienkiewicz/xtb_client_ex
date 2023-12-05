defmodule XtbClient.Messages.Version do
  @moduledoc """
  Info about actual version of Api.

  ## Parameters
  - `version` string version of Api.

  ## Handled Api methods
  - `getVersion`
  """

  @type t :: %__MODULE__{
          version: String.t()
        }

  @enforce_keys [:version]
  @derive Jason.Encoder
  defstruct version: ""

  def new(%{"version" => version}) when is_binary(version) do
    %__MODULE__{
      version: version
    }
  end
end

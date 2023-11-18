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

  defstruct version: ""

  def new(%{"version" => version}) when is_binary(version) do
    %__MODULE__{
      version: version
    }
  end

  def match(method, data) when method in ["getVersion"] do
    {:ok, __MODULE__.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end

defmodule XtbClient.Messages.Version do
  @moduledoc """
  Info about actual version of Api.

  ## Parameters
  - `version` string version of Api.

  ## Handled Api methods
  - `getVersion`
  """

  defmodule Query do
    @moduledoc """
    Returns the current API version.
    """
    alias XtbClient.Messages.Version

    @behaviour XtbClient.Message

    @type t :: %__MODULE__{}

    @derive Jason.Encoder
    defstruct []

    def new do
      %__MODULE__{}
    end

    @impl XtbClient.Message
    def operation(%__MODULE__{}), do: "getVersion"

    @impl XtbClient.Message
    def encode(%__MODULE__{} = data), do: data

    @impl XtbClient.Message
    def decode(data), do: Version.new(data)
  end

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

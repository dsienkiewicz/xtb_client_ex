defmodule XtbClient.Messages.Version do
  @enforce_keys [:version]

  defstruct version: ""

  def new(%{"version" => version}) when is_binary(version) do
    %__MODULE__{
      version: version
    }
  end

  def match(%{"version" => _} = data) do
    {:ok, __MODULE__.new(data)}
  end

  def match(_data) do
    {:no_match}
  end
end

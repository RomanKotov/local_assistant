defmodule Mopidy.Models.Ref do
  defstruct [:name, :type, :uri]

  @type t() :: %__MODULE__{
    name: String.t() | nil,
    type: String.t() | nil,
    uri: String.t() | nil,
  }
end

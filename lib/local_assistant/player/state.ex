defmodule LocalAssistant.Player.State do
  defstruct [
    state: "stopped",
    track: nil,
    volume: 0,
    position: 0
  ]

  @type t() :: %__MODULE__{
    state: String.t(),
    track: MopidyWS.Models.Track.t() | nil,
    volume: integer(),
    position: integer()
  }
end
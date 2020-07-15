defmodule LocalAssistant.Player.State do
  defstruct [
    state: "stopped",
    track: %MopidyWS.Models.Track{},
    stream_title: "",
    volume: 0,
    position: 0
  ]

  @type t() :: %__MODULE__{
    state: String.t(),
    track: MopidyWS.Models.Track.t() | nil,
    volume: integer(),
    position: integer(),
    stream_title: String.t() | nil,
  }
end

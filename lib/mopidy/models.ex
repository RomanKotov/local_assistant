defmodule Mopidy.Models do
  defmodule Ref do
    defstruct [:name, :type, :uri]

    @type t() :: %__MODULE__{
            name: String.t() | nil,
            type: String.t() | nil,
            uri: String.t() | nil
          }
  end

  defmodule Track do
    defstruct [
      :album,
      :artists,
      :bitrate,
      :comment,
      :composers,
      :date,
      :disc_no,
      :genre,
      :last_modified,
      :length,
      :muzicbrainz_id,
      :name,
      :performers,
      :track_no,
      :uri
    ]

    @type t() :: %__MODULE__{
            uri: String.t() | nil,
            name: String.t() | nil,
            artists: list(Mopidy.Models.Artist.t()),
            album: Mopidy.Models.Album.t() | nil,
            composers: list(Mopidy.Models.Artist.t()),
            performers: list(Mopidy.Models.Artist.t()),
            genre: String.t() | nil,
            track_no: integer() | nil,
            disc_no: integer() | nil,
            date: String.t() | nil,
            length: integer() | nil,
            bitrate: integer() | nil,
            comment: String.t() | nil,
            muzicbrainz_id: String.t() | nil,
            last_modified: String.t() | nil
          }
  end

  defmodule Album do
    defstruct [
      :uri,
      :name,
      :artists,
      :num_tracks,
      :num_discs,
      :date,
      :muzicbrainz_id
    ]

    @type t() :: %__MODULE__{
            uri: String.t() | nil,
            name: String.t() | nil,
            artists: list(Mopidy.Models.Artist.t()),
            num_tracks: integer() | nil,
            num_discs: integer() | nil,
            date: String.t() | nil,
            muzicbrainz_id: String.t() | nil
          }
  end

  defmodule Artist do
    defstruct [
      :uri,
      :name,
      :shortname,
      :muzicbrainz_id
    ]

    @type t() :: %__MODULE__{
            uri: String.t() | nil,
            name: String.t() | nil,
            shortname: String.t() | nil,
            muzicbrainz_id: String.t() | nil
          }
  end

  defmodule Playlist do
    defstruct [
      :uri,
      :name,
      :tracks,
      :last_modified
    ]

    @type t() :: %__MODULE__{
            uri: String.t() | nil,
            name: String.t() | nil,
            tracks: list(Mopidy.Player.Track.t()) | nil,
            last_modified: integer() | nil
          }
  end

  defmodule Image do
    defstruct [
      :uri,
      :width,
      :height
    ]

    @type t() :: %__MODULE__{
            uri: String.t() | nil,
            width: integer() | nil,
            height: integer() | nil
          }
  end

  defmodule TlTrack do
    defstruct [
      :tlid,
      :track
    ]

    @type t() :: %__MODULE__{
            tlid: integer() | nil,
            track: Mopidy.Player.Track.t() | nil
          }
  end

  defmodule SearchResult do
    defstruct [
      :uri,
      :tracks,
      :artists,
      :albums
    ]

    @type t() :: %__MODULE__{
            uri: String.t() | nil,
            tracks: list(Mopidy.Player.Track.t()) | nil,
            artists: list(Mopidy.Player.Artist.t()) | nil,
            albums: list(Mopidy.Player.Album.t()) | nil
          }
  end
end

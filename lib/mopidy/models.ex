defmodule Mopidy.Models.Generator do
  defmacro defmodel(model_name, do: body) do
    model_keys = body |> Keyword.keys()
    model_name_str = model_name |> Macro.to_string()

    quote do
      defmodule unquote(model_name) do
        defstruct unquote(model_keys)

        @type t() :: %__MODULE__{unquote_splicing(body)}

        defimpl Jason.Encoder, for: __MODULE__ do
          def encode(data, opts) do
            data
            |> Map.from_struct()
            |> Map.put("__model__", unquote(model_name_str))
            |> Jason.Encode.map(opts)
          end
        end
      end

      def deserialize(data = %{"__model__" => unquote(model_name_str)}) do
        model_data =
          for key <- unquote(model_keys) do
            {key, data["#{key}"] |> deserialize}
          end

        struct(unquote(model_name), model_data)
      end
    end
  end
end

defmodule Mopidy.Models do
  import Mopidy.Models.Generator, only: [defmodel: 2]

  defmodel(Ref,
    do: [
      name: String.t() | nil,
      type: String.t() | nil,
      uri: String.t() | nil
    ]
  )

  defmodel(Track,
    do: [
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
    ]
  )

  defmodel(Album,
    do: [
      uri: String.t() | nil,
      name: String.t() | nil,
      artists: list(Mopidy.Models.Artist.t()),
      num_tracks: integer() | nil,
      num_discs: integer() | nil,
      date: String.t() | nil,
      muzicbrainz_id: String.t() | nil
    ]
  )

  defmodel(Artist,
    do: [
      uri: String.t() | nil,
      name: String.t() | nil,
      shortname: String.t() | nil,
      muzicbrainz_id: String.t() | nil
    ]
  )

  defmodel(Playlist,
    do: [
      uri: String.t() | nil,
      name: String.t() | nil,
      tracks: list(Mopidy.Player.Track.t()) | nil,
      last_modified: integer() | nil
    ]
  )

  defmodel(Image,
    do: [
      uri: String.t() | nil,
      width: integer() | nil,
      height: integer() | nil
    ]
  )

  defmodel(TlTrack,
    do: [
      tlid: integer() | nil,
      track: Mopidy.Player.Track.t() | nil
    ]
  )

  defmodel(SearchResult,
    do: [
      uri: String.t() | nil,
      tracks: list(Mopidy.Player.Track.t()) | nil,
      artists: list(Mopidy.Player.Artist.t()) | nil,
      albums: list(Mopidy.Player.Album.t()) | nil
    ]
  )

  def deserialize(result) when is_list(result), do: result |> Enum.map(&deserialize/1)
  def deserialize(result), do: result
end

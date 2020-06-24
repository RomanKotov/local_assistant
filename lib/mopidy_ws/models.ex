defmodule MopidyWS.Models.Generator do
  defmacro defmodel(model_name, fields: fields) do
    model_keys = fields |> Keyword.keys()
    model_name_str = model_name |> Macro.to_string()

    quote do
      defmodule unquote(model_name) do
        defstruct unquote(model_keys)

        @type t() :: %__MODULE__{unquote_splicing(fields)}

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

defmodule MopidyWS.Models do
  import MopidyWS.Models.Generator, only: [defmodel: 2]

  defmodel(Ref,
    fields: [
      name: String.t() | nil,
      type: String.t() | nil,
      uri: String.t() | nil
    ]
  )

  defmodel(Track,
    fields: [
      uri: String.t() | nil,
      name: String.t() | nil,
      artists: list(MopidyWS.Models.Artist.t()),
      album: MopidyWS.Models.Album.t() | nil,
      composers: list(MopidyWS.Models.Artist.t()),
      performers: list(MopidyWS.Models.Artist.t()),
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
    fields: [
      uri: String.t() | nil,
      name: String.t() | nil,
      artists: list(MopidyWS.Models.Artist.t()),
      num_tracks: integer() | nil,
      num_discs: integer() | nil,
      date: String.t() | nil,
      muzicbrainz_id: String.t() | nil
    ]
  )

  defmodel(Artist,
    fields: [
      uri: String.t() | nil,
      name: String.t() | nil,
      shortname: String.t() | nil,
      muzicbrainz_id: String.t() | nil
    ]
  )

  defmodel(Playlist,
    fields: [
      uri: String.t() | nil,
      name: String.t() | nil,
      tracks: list(MopidyWS.Models.Track.t()) | nil,
      last_modified: integer() | nil
    ]
  )

  defmodel(Image,
    fields: [
      uri: String.t() | nil,
      width: integer() | nil,
      height: integer() | nil
    ]
  )

  defmodel(TlTrack,
    fields: [
      tlid: integer() | nil,
      track: MopidyWS.Models.Track.t() | nil
    ]
  )

  defmodel(SearchResult,
    fields: [
      uri: String.t() | nil,
      tracks: list(MopidyWS.Models.Track.t()) | nil,
      artists: list(MopidyWS.Models.Artist.t()) | nil,
      albums: list(MopidyWS.Models.Album.t()) | nil
    ]
  )

  def deserialize(result) when is_map(result) do
    for {key, value} <- result, into: %{} do
      {key, deserialize(value)}
    end
  end

  def deserialize(result) when is_list(result), do: result |> Enum.map(&deserialize/1)
  def deserialize(result), do: result
end

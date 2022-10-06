defmodule Leif.Bot do
  require Logger
  use Telegram.ChatBot
  alias Leif.Presence

  # 5 minutes
  @session_ttl 5 * 60 * 1_000

  @impl Telegram.ChatBot
  def init(_chat) do
    {:ok, %{new?: true}, @session_ttl}
  end

  @impl Telegram.ChatBot
  def handle_update(
        %{
          "message" => %{
            "from" => user_info,
            "text" => text,
            "chat" => %{"id" => chat_id},
            "message_id" => message_id
          }
        } = update,
        token,
        state
      ) do
    path =
      case download_picture!(user_info, token) do
        {:ok, path} when is_binary(path) -> path
        _ -> nil
      end

    username =
      get_in(update, ["message", "chat", "username"]) ||
        "Unknown user #{:erlang.unique_integer([:positive])}"

    first = String.at(update["message"]["chat"]["first_name"] || "?", 0)
    second = String.at(update["message"]["chat"]["last_name"] || "?", 0)
    initials = first <> second

    emoji =
      text
      |> Exmoji.Scanner.scan()
      |> Enum.map(&Exmoji.EmojiChar.render/1)
      |> Enum.join()

    if state.new? do
      Telegram.Api.request(token, "sendMessage", chat_id: chat_id, text: "Welcome!")

      {:ok, _} =
        Presence.track(self(), "chat", chat_id, %{
          online_at: inspect(System.system_time(:second)),
          initials: initials,
          user_id: user_info["id"],
          latest: emoji,
          picture: path
        })
    else
      Presence.update(self(), "chat", chat_id, %{
        online_at: inspect(System.system_time(:second)),
        initials: initials,
        user_id: user_info["id"],
        latest: emoji,
        picture: path
      })
    end

    {:ok, %{state | new?: false}, @session_ttl}
  end

  defp download_picture!(%{"id" => user_id}, token) do
    with {:ok, %{"photos" => [photos | _]}} <-
           Telegram.Api.request(token, "getUserProfilePhotos", user_id: user_id),
         {:ok, file_id} <- largest_photo(photos),
         {:ok, %{"file_path" => file_path}} <-
           Telegram.Api.request(token, "getFile", file_id: file_id),
         {:ok, file_data} <- Telegram.Api.file(token, file_path) do
      ext = Path.extname(file_path)
      File.mkdir_p!("photos")
      path = Path.join("photos", "#{user_id}#{ext}")
      File.write!(path, file_data)
      {:ok, path}
    end
  end

  defp largest_photo(photos) do
    case Enum.max_by(photos, fn p -> p["file_size"] end) do
      %{"file_id" => file_id} -> {:ok, file_id}
      _ -> {:error, "no photo found"}
    end
  end
end

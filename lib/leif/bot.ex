defmodule Leif.Bot do
  require Logger
  use Telegram.Bot

  @impl Telegram.Bot
  def handle_update(%{"message" => %{"text" => text, "chat" => %{"chat" => %{"id" => chat_id},  "message_id" => message_id} = update) do
    username = get_in(update, ["message", "chat", "username"]) || "Unknown user #{:erlang.unique_integer([:positive])}"
    {:ok, _} = Presence.track(self(), chat_id, %{
      online_at: inspect(System.system_time(:second)),
      username: username,
      latest: text
    })
  end
end

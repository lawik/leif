defmodule LeifWeb.BaseLive do
  use LeifWeb, :live_view

  alias Leif.Presence

  def mount(_, _, socket) do
    Phoenix.PubSub.subscribe(Leif.PubSub, "chat")
    {:ok, refresh_people(socket)}
  end

  def handle_info(%{event: "presence_diff"} = _message, socket) do
    {:noreply, refresh_people(socket)}
  end

  defp refresh_people(socket) do
    people =
      Presence.list("chat")
      |> Enum.sort_by(fn {_key, %{metas: metas}} ->
        case metas do
          [p | _] -> p.online_at
          _ -> 0
        end
      end)

    assign(socket, people: people)
  end
end

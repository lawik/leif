defmodule Leif.Presence do
  use Phoenix.Presence, otp_app: :leif, pubsub_server: Leif.PubSub
end

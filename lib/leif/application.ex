defmodule Leif.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Telegram.Poller, bots: [{Leif.Bot, token: System.get_env("BOT_TOKEN"), max_bot_concurrency: 1000}]},
      # Start the Ecto repository
      Leif.Repo,
      # Start the Telemetry supervisor
      LeifWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Leif.PubSub},
      Leif.Presence,
      # Start the Endpoint (http/https)
      LeifWeb.Endpoint
      # Start a worker by calling: Leif.Worker.start_link(arg)
      # {Leif.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Leif.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LeifWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

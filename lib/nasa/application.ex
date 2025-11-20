defmodule Nasa.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NasaWeb.Telemetry,
      Nasa.Repo,
      {DNSCluster, query: Application.get_env(:nasa, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Nasa.PubSub},
      # Start a worker by calling: Nasa.Worker.start_link(arg)
      # {Nasa.Worker, arg},
      # Start to serve requests, typically the last entry
      NasaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nasa.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NasaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

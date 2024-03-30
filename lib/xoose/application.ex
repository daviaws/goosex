defmodule Xoose.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      XooseWeb.Telemetry,
      # Xoose.Repo,
      {DNSCluster, query: Application.get_env(:xoose, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Xoose.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Xoose.Finch},
      # Start a worker by calling: Xoose.Worker.start_link(arg)
      # {Xoose.Worker, arg},
      # Start to serve requests, typically the last entry
      XooseWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Xoose.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    XooseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

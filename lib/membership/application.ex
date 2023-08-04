defmodule Membership.Application do
  @moduledoc false
  use Application

  alias Membership.Repo

  @impl true
  def start(_type, args \\ []) do

    children = [
      {Repo, args},
      {Membership.Registry, []}
    ]

    opts = [strategy: :one_for_one, name: Membership.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @version Mix.Project.config()[:version]
  def version, do: @version
end

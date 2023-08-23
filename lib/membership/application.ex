defmodule Membership.Application do
  @moduledoc false
  use Application

  alias Membership.Repo

  @impl true
  def start(_type, args \\ []) do
    children = [
      {Repo, []},
      ## store ref to ets
      {Registry, keys: :unique, name: :active_memberships},
      ## start/stop members for ref cleanup when killed
      {DynamicSupervisor, strategy: :one_for_one, name: :memberships_supervisor}
    ]

    opts = [strategy: :one_for_one, name: Membership.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @version Mix.Project.config()[:version]
  def version, do: @version
end

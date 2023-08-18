defmodule Membership.Application do
  @moduledoc false
  use Application

  alias Membership.Repo

  @impl true
  def start(_type, args \\ []) do

    children = [
      {Repo, []},
      {Registry, keys: :unique, name: :memberships}, ## store ref to ets
      {DynamicSupervisor, strategy: :one_for_one, name: :memberships_supervisor},  ## start/stop members for ref cleanup when killed
    ]

    opts = [strategy: :one_for_one, name: Membership.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @version Mix.Project.config()[:version]
  def version, do: @version
end

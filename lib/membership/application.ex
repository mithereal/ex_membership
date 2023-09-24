defmodule Membership.Application do
  @moduledoc false
  use Application

  alias Membership.Repo
  alias Membership.Plan.Server, as: Plans
  alias Membership.Role.Server, as: Roles
  #  alias Membership.EntityServer, as: Entities

  @impl true
  def start(_type, args \\ []) do
    children = [
      {Repo, args},
      {Plans, []},
      {Roles, []},
      #      {Entities, []},
      {Registry, keys: :unique, name: :active_memberships},
      {Registry, keys: :unique, name: :module_permissions},
      {DynamicSupervisor, strategy: :one_for_one, name: :memberships_supervisor},
      {DynamicSupervisor, strategy: :one_for_one, name: :module_permissions_supervisor}
    ]

    opts = [strategy: :one_for_one, name: Membership.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @version Mix.Project.config()[:version]
  def version, do: @version
end

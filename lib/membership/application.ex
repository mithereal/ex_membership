defmodule Membership.Application do
  @moduledoc false
  use Application

  alias Membership.Repo

  @impl true
  def start(_type, args \\ []) do
    children = [
      {Repo, args},
      {Registry, keys: :unique, name: :active_memberships},
      {DynamicSupervisor, strategy: :one_for_one, name: :memberships_supervisor}
    ]

    opts = [strategy: :one_for_one, name: Membership.Supervisor]
    Supervisor.start_link(children, opts) |> load_plans() |> load_roles()
  end

  @version Mix.Project.config()[:version]
  def version, do: @version

  def load_plans(params) do
    :ets.new(:membership_plans, [:named_table, :set, :public, read_concurrency: true])
    reload_plans()
    params
  end

  def load_roles(params) do
    :ets.new(:membership_roles, [:named_table, :set, :public, read_concurrency: true])
    reload_roles()
    params
  end

  def reload_plans() do
    Repo.all(Membership.Plan)
    |> Repo.preload([:features])
    |> Enum.each(fn x ->
      features = Enum.map(x.features, fn x -> x.identifier end)
      :ets.insert(:membership_plans, {x.identifier, features})
    end)
  end

  def reload_roles() do
    Repo.all(Membership.Role)
    |> Repo.preload([:features])
    |> Enum.each(fn x ->
      features = Enum.map(x.features, fn x -> x.identifier end)
      :ets.insert(:membership_roles, {x.identifier, features})
    end)
  end
end

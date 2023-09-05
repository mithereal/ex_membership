defmodule Membership.Application do
  @moduledoc false
  use Application

  alias Membership.Repo

  @impl true
  def start(_type, args \\ []) do
    storage_type = Membership.Config.storage_type()

    children =
      case storage_type do
        :horde ->
          Membership.Application.Horde.start()

        _ ->
          [
            {Repo, args},
            {Registry, keys: :unique, name: :active_memberships},
            {DynamicSupervisor, strategy: :one_for_one, name: :memberships_supervisor}
          ]
      end

    opts = [strategy: :one_for_one, name: Membership.Supervisor]
    Supervisor.start_link(children, opts) |> load_plans()
  end

  @version Mix.Project.config()[:version]
  def version, do: @version

  def load_plans(params) do
    :ets.new(:membership_plans, [:named_table, :set, :public, read_concurrency: true])
    reload_plans()
    params
  end

  def reload_plans() do
    Repo.all(Membership.Plan)
    |> Repo.preload([:features])
    |> Enum.each(fn x ->
      :ets.insert(:membership_plans, {x.identifier, x.features})
    end)
  end
end

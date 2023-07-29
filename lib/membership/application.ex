defmodule Membership.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Membership.Registry, [])
    ]

    children = children ++ load_repos()

    opts = [strategy: :one_for_one, name: Membership.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp load_repos do
    case Application.get_env(:membership, :ecto_repos) do
      nil -> [Membership.Repo]
      repos -> repos
    end
  end
end

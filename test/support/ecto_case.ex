defmodule Membership.EctoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Membership.Repo

      import Ecto
      import Ecto.Query
      import Membership.EctoCase
      import Membership.Factory

      # and any other stuff
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Membership.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Membership.Repo, {:shared, self()})
    end

    :ok
  end
end

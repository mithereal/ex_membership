defmodule Membership.EctoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Membership.TestRepo

      import Ecto
      import Ecto.Query
      import Membership.EctoCase
      import Membership.Factory

      # and any other stuff
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Membership.TestRepo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Membership.TestRepo, {:shared, self()})
    end

    :ok
  end
end

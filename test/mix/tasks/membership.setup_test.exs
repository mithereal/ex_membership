defmodule Mix.Tasks.MembershipSetupTest do
  use ExUnit.Case
  import Mock
  # doesnt work with circle ci
  #  test "provide a list of available membership mix tasks" do
  #    with_mock Mix.Tasks.Ecto.Migrate, run: fn _params -> nil end do
  #      Mix.Tasks.Membership.Setup.run([])
  #      assert_called(Mix.Tasks.Ecto.Migrate.run(["-r", "Membership.Repo"]))
  #    end
  #  end
end

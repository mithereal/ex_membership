defmodule Membership.TestRepo do
  use Ecto.Repo,
    otp_app: :ex_membership,
    adapter: Ecto.Adapters.Postgres
end

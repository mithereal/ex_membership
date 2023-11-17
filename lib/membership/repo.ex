defmodule Membership.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :ex_membership,
    adapter: Ecto.Adapters.Postgres

  def truncate(schema) do
    table_name = schema.__schema__(:source)

    query("TRUNCATE #{table_name}", [])
  end
end

defmodule Membership.Repo do
  @moduledoc """
  Ecto repository
  """

  use Ecto.Repo,
    otp_app: :membership,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Empty the Database Table
  """
  def truncate(schema) do
    table_name = schema.__schema__(:source)

    query("TRUNCATE #{table_name}", [])
  end
end

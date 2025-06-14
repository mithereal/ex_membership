defmodule Membership.TestRepo do
  use Ecto.Repo,
    otp_app: :ex_membership,
    adapter: Ecto.Adapters.Postgres

  @name __MODULE__

  def start_link(_) do
    GenServer.start_link(__MODULE__, [@name])
  end

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(arg, nil) do
    init(arg, [])
  end

  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end

  @doc """
  Empty the Database Table
  """
  def truncate(schema) do
    table_name = schema.__schema__(:source)

    query("TRUNCATE #{table_name}", [])
  end
end

defmodule Membership.Repo do
  alias Membership.Config

  @callbacks_without_opts [
    config: 0,
    default_options: 1,
    get_dynamic_repo: 0,
    in_transaction?: 0,
    load: 2,
    put_dynamic_repo: 1,
    rollback: 1
  ]

  @callbacks_with_opts [
    aggregate: 3,
    all: 2,
    checkout: 2,
    delete!: 2,
    delete: 2,
    delete_all: 2,
    exists?: 2,
    get!: 3,
    get: 3,
    get_by!: 3,
    get_by: 3,
    insert!: 2,
    insert: 2,
    insert_all: 3,
    insert_or_update!: 2,
    insert_or_update: 2,
    one!: 2,
    one: 2,
    preload: 3,
    reload!: 2,
    reload: 2,
    stream: 2,
    transaction: 2,
    update!: 2,
    update: 2,
    update_all: 3
  ]

  for {fun, arity} <- @callbacks_without_opts do
    args = [Macro.var(:conf, __MODULE__) | Macro.generate_arguments(arity, __MODULE__)]

    @doc """
    Wraps `c:Ecto.Repo.#{fun}/#{arity}` with an additional `Membership.Config` argument.
    """
    def unquote(fun)(unquote_splicing(args)) do
      __dispatch__(unquote(fun), unquote(args))
    end
  end

  for {fun, arity} <- @callbacks_with_opts do
    args = [Macro.var(:conf, __MODULE__) | Macro.generate_arguments(arity - 1, __MODULE__)]

    @doc """
    Wraps `c:Ecto.Repo.#{fun}/#{arity}` with an additional `Membership.Config` argument.
    """
    def unquote(fun)(unquote_splicing(args), opts \\ []) do
      __dispatch__(unquote(fun), unquote(args), opts)
    end
  end

  # Manually Defined

  @doc """
  The default values extracted from `Membership.Config` for use in all queries with options.
  """
  @doc since: "2.14.0"
  def default_options(conf) do
    base = [log: conf.log]

    if conf.prefix do
      [prefix: conf.prefix] ++ base
    else
      base
    end
  end

  @doc """
  Wraps `Ecto.Adapters.SQL.Repo.query/4` with an added `Membership.Config` argument.
  """
  @doc since: "1.2.5"
  def query(conf, statement, params \\ [], opts \\ []) do
    __dispatch__(:query, [conf, statement, params], opts)
  end

  @doc """
  Wraps `Ecto.Adapters.SQL.Repo.query!/4` with an added `Membership.Config` argument.
  """
  @doc since: "2.17.0"
  def query!(conf, statement, params \\ [], opts \\ []) do
    __dispatch__(:query, [conf, statement, params], opts)
  end

  @doc """
  Wraps `Ecto.Adapters.SQL.Repo.to_sql/2` with an added `Membership.Config` argument.
  """
  @doc since: "1.2.5"
  def to_sql(conf, kind, queryable) do
    query =
      queryable
      |> Ecto.Queryable.to_query()
      |> Map.put(:prefix, conf.prefix)

    conf.repo.to_sql(kind, query)
  end

  defp __dispatch__(name, [%Config{} = conf | args]) do
    with_dynamic_repo(conf, name, args)
  end

  defp __dispatch__(name, [%Config{} = conf | args], opts) when is_list(opts) do
    opts =
      conf
      |> default_options()
      |> Keyword.merge(opts)

    with_dynamic_repo(conf, name, args ++ [opts])
  end

  defp with_dynamic_repo(%{get_dynamic_repo: fun} = conf, name, args) when is_function(fun, 0) do
    prev_instance = conf.repo.get_dynamic_repo()

    try do
      unless in_transaction?(conf, prev_instance) do
        conf.repo.put_dynamic_repo(fun.())
      end

      apply(conf.repo, name, args)
    after
      conf.repo.put_dynamic_repo(prev_instance)
    end
  end

  defp with_dynamic_repo(conf, name, args) do
    apply(conf.repo, name, args)
  end

  defp in_transaction?(conf, instance) when is_pid(instance), do: conf.repo.in_transaction?()

  defp in_transaction?(conf, instance) when is_atom(instance) do
    case GenServer.whereis(instance) do
      pid when is_pid(pid) -> in_transaction?(conf, pid)
      _ -> false
    end
  end

  defp in_transaction?(_, _), do: false

  @doc """
  Empty the Database Table
  """
  def truncate(schema) do
    table_name = schema.__schema__(:source)

    query("TRUNCATE #{table_name}", [])
  end
end

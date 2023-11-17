defmodule Membership do
  @moduledoc false

  @default_features []

  defmacro __using__(opts) do
    quote do
      opts = unquote(opts)

      @registry Keyword.fetch!(opts, :registry)

      use Membership.Behaviour, registry: @registry
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    create_membership()
  end

  defmacro permissions(do: block) do
    quote do
      load_ets_data(unquote(__MODULE__))
      data = unquote(block)

      case is_nil(data) do
        true -> @default_features
        false -> data
      end
    end
  end

  defmacro permissions(member, do: block) do
    quote do
      load_and_authorize_member(unquote(member))
      load_ets_data(unquote(__MODULE__))
      data = unquote(block)

      case is_nil(data) do
        true -> @default_features
        false -> data
      end
    end
  end

  def add_function_param_to_block(block) do
    {:ok, block}
  end

  def ignored_functions() do
    Membership.module_info()
    |> Keyword.fetch!(:exports)
    |> Enum.map(fn {key, _data} -> key end)
  end

  def load_ets_data(current_module \\ __MODULE__) do
    require Logger

    status = Membership.Permissions.Supervisor.start(current_module)

    case status do
      {:error, error} ->
        Logger.error(error)
        :ok

      {:ok, _} ->
        Map.__info__(:functions)
        |> Enum.filter(fn {x, _} -> Enum.member?(ignored_functions(), x) end)
        |> Enum.each(fn {x, _} ->
          Membership.Permission.Server.insert(current_module, x, [])
        end)
    end
  end

  defmacro as_authorized(member, func_name, do: block) do
    quote do
      with :ok <- perform_authorization!(unquote(member), unquote(func_name)) do
        unquote(block)
      end
    end
  end

  defmacro calculated(current_member, func_name)
           when is_atom(func_name) do
    quote do
      {:ok, current_member} = Membership.Member.Server.show(unquote(current_member))

      rules = unquote(func_name)(current_member)

      data = {unquote(func_name), rules}

      Membership.Member.Server.add_to_calculated_registry(current_member, data)
    end
  end

  defmacro calculated(current_member, callback, func_name) when is_atom(func_name) do
    quote do
      {:ok, current_member} = Membership.Member.Server.show(unquote(current_member))

      result = apply(unquote(callback), [current_member])

      data = {unquote(func_name), [result]}

      Membership.Member.Server.add_to_calculated_registry(current_member, data)
    end
  end

  defmacro calculated(current_member, func_name, bindings) when is_atom(func_name) do
    quote do
      {:ok, current_member} = Membership.Member.Server.show(unquote(current_member))
      result = unquote(func_name)(current_member, unquote(bindings))

      data = {unquote(func_name), [result]}

      Membership.Member.Server.add_to_calculated_registry(current_member, data)
    end
  end

  defmacro calculated(current_member, callback, bindings, func_name)
           when is_atom(func_name) do
    quote do
      {:ok, current_member} = Membership.Member.Server.show(unquote(current_member))
      result = apply(unquote(callback), [current_member, unquote(bindings)])

      data = {unquote(func_name), [result]}

      Membership.Member.Server.add_to_calculated_registry(current_member, data)
    end
  end

  # @spec authorized?() :: :ok | {:error, String.t()}
  def authorized?(member, func_name) do
    perform_authorization!(member, func_name)
  end

  @spec has_plan?(Membership.Member.t(), atom(), String.t()) :: boolean()
  def has_plan?(%Membership.Member{} = member, func_name, plan_name) do
    perform_authorization!(member, func_name, [], [Atom.to_string(plan_name)]) == :ok
  end

  @spec has_role?(Membership.Member.t(), atom(), String.t()) :: boolean()
  def has_role?(%Membership.Member{} = member, role_name) do
    roles = Enum.map(member.roles, fn x -> x.identifier end)
    Enum.member?(roles, role_name) == true
  end

  @spec has_role?(Membership.Member.t(), atom(), String.t()) :: boolean()
  def has_role?(%Membership.Member{} = member, func_name, role_name) do
    perform_authorization!(member, func_name, [], [], [Atom.to_string(role_name)]) == :ok
  end

  def has_feature?(%Membership.Member{} = member, feature_name) do
    Enum.member?(member.features, feature_name)
  end

  def has_feature?(%Membership.Member{} = member, func_name, feature_name) do
    perform_authorization!(member, func_name, [Atom.to_string(feature_name)]) == :ok
  end

  def perform_authorization!(
        current_member \\ nil,
        func_name \\ nil,
        required_features \\ [],
        required_plans \\ [],
        required_roles \\ []
      ) do
    # If no member is given we can assume that as_authorized are not granted
    if is_nil(current_member) do
      {:error, "Member is not granted to perform this action"}
    else
      rules =
        try do
          fetch_rules_from_ets(func_name)
        rescue
          _ ->
            []
        end

      calculated_rules =
        Membership.Member.Server.fetch_from_calculated_registry(current_member, func_name)

      calculated_rules =
        case calculated_rules do
          {_, value} ->
            value

          _ ->
            calculated_rules
        end

      rules =
        case is_nil(rules) do
          true -> @default_features
          false -> rules
        end

      plan_features =
        List.flatten(
          Enum.map(required_plans, fn p ->
            p.features
          end)
        )

      role_features =
        List.flatten(
          Enum.map(required_roles, fn r ->
            r.features
          end)
        )

      required_features =
        required_features ++
          plan_features ++
          role_features ++ rules

      # If no as_authorized were required then we can assume member is granted
      if length(required_features ++ calculated_rules) == 0 do
        :ok
      else
        reply =
          authorize!(
            [
              authorize_features(current_member.features, required_features)
            ] ++
              calculated_rules
          )

        if reply == :ok do
          reply
        else
          {:error, "Member is not granted to perform this action"}
        end
      end
    end
  end

  defp fetch_rules_from_ets(nil) do
    {:error, "Unknown ETS Record for Registry nil"}
  end

  defp fetch_rules_from_ets(func_name) do
    {:ok, value} = Membership.Registry.lookup(__MODULE__, func_name)
    value
  end

  def create_membership() do
    quote do
      import Membership, only: [load_and_store_member!: 2, unload_member!: 1]

      def load_and_authorize_member(%Membership.Member{id: _id} = member),
        do: load_and_store_member!(member, %{})

      def load_and_authorize_member(%Membership.Member{id: _id} = member, opts),
        do: load_and_store_member!(member, opts)

      def load_and_authorize_member(%{member: %Membership.Member{id: _id} = member}),
        do: load_and_store_member!(member, %{})

      def load_and_authorize_member(%{member: %Membership.Member{id: _id} = member}, opts),
        do: load_and_store_member!(member, opts)

      def load_and_authorize_member(%{member_id: member_id}, opts)
          when is_nil(member_id),
          do: nil

      def load_and_authorize_member(%{member_id: member_id}, opts),
        do: load_and_store_member!(%Membership.Member{id: member_id}, opts)

      def load_and_authorize_member(member) do
        load_and_store_member!(%Membership.Member{id: member.member_id}, %{})
      end
    end
  end

  @spec load_and_store_member!(integer(), map()) :: {:ok, Membership.Member.t()}
  def load_and_store_member!(member_id, opts) when is_integer(member_id) do
    opts =
      case is_nil(opts) do
        true -> %{}
        false -> opts
      end

    member = Membership.Repo.get!(Membership.Member, member_id) |> Map.merge(opts)
    status = Membership.Memberships.Supervisor.start(member)

    case status do
      {:ok, _} -> member
      {:error, {:already_started, _}} -> Membership.Memberships.Supervisor.update(member)
      {:error, _} -> nil
    end
  end

  @spec load_and_store_member!(Membership.Member.t(), map()) :: {:ok, Membership.Member.t()}
  def load_and_store_member!(%Membership.Member{} = member, opts) do
    member = Membership.Repo.get!(Membership.Member, member.id)

    case is_nil(opts) do
      true ->
        status = Membership.Memberships.Supervisor.start(member)

        case status do
          {:ok, _} -> member
          {:error, {:already_started, _}} -> member
          {:error, _} -> nil
        end

      false ->
        member = member |> Map.merge(opts)

        status = Membership.Memberships.Supervisor.start(member)

        case status do
          {:ok, _} ->
            member

          {:error, {:already_started, _pid}} ->
            status = Membership.Memberships.Supervisor.reload(member)

            case status do
              {:ok, _} ->
                member

              {:error, _} ->
                member
            end

          {:error, _} ->
            nil
        end
    end
  end

  @spec unload_member!(Membership.Member.t()) :: {:ok, Membership.Member.t()}
  def unload_member!(%Membership.Member{} = member) do
    Membership.Memberships.Supervisor.stop(member.identifier)
  end

  @spec load_member_features(Membership.Member.t()) :: Membership.Member.t()
  def load_member_features(member) do
    member
  end

  def authorize_features(active_features \\ [], required_features \\ []) do
    active_features = Enum.map(active_features, fn x -> String.to_atom(x) end)

    authorized =
      Enum.filter(required_features, fn feature ->
        Enum.member?(active_features, feature)
      end)

    length(authorized) > 0
  end

  def authorize!(conditions) do
    # Authorize empty conditions as true

    conditions =
      case length(conditions) do
        0 -> [true]
        _ -> conditions
      end

    authorized =
      Enum.reduce(conditions, false, fn condition, acc ->
        condition || acc
      end)

    case authorized do
      true -> :ok
      _ -> {:error, "Member is not granted to perform this action"}
    end
  end

  @spec has_plan(atom(), atom()) :: {:ok, atom()}
  def has_plan(plan, func_name) do
    case :ets.lookup(:membership_plans, plan) do
      [] ->
        {:error, "plan: #{plan} Not Found"}

      {plan, features} ->
        Membership.Registry.add(__MODULE__, func_name, features)
        {:ok, plan}
    end
  end

  @spec has_role(atom(), atom()) :: {:ok, atom()}
  def has_role(role, func_name) do
    case :ets.lookup(:membership_roles, role) do
      [] ->
        {:error, "plan: #{role} Not Found"}

      {plan, features} ->
        Membership.Registry.add(__MODULE__, func_name, features)
        {:ok, plan}
    end
  end

  @spec has_feature(atom(), atom()) :: {:ok, atom()}
  def has_feature(feature, func_name) do
    Membership.Registry.add(__MODULE__, func_name, feature)
    {:ok, feature}
  end

  def get_loaded_modules() do
    {:ok, modules} = :application.get_key(:ex_membership, :modules)

    modules
    |> Enum.map(&Module.split/1)
    |> Enum.reject(fn module ->
      Enum.any?(
        module,
        &Enum.member?(
          ["Mix", "Tasks", "Post", "Config", "Application", "Behaviour", "InvalidConfigError"],
          &1
        )
      )
    end)
    |> Enum.map(&Module.concat/1)
  end

  @version Mix.Project.config()[:version]
  def version, do: @version
end

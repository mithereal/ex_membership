defmodule Membership do
  @moduledoc """
  Main Membership module for including macros

  Membership has 4 main components:

    * `Membership.Role` -  Representation of a single role e.g. :admin, :luser, :user
    * `Membership.Plan` -  Representation of a single plan e.g. :gold, :silver, :copper
    * `Membership.Member` - Main actor which is holding given plans
    * `Membership.Feature` - Feature of a plan eg. :edit_feature

  ## Relations between models

  `Membership.Member`  -> `Membership.Feature`[1-n] - Any given member have multiple features with this we can have more granular features for each member is adding a specific feature to a member not in his plan

  `Membership.Member` -> `Membership.Plan` [1-n] - Any given member can have multiple plans

  `Membership.Member` -> `Membership.Role` [1-n] - Any given member can have multiple roles

  `Membership.Plan` -> `Membership.Feature` [m-n] - Any given plan can have multiple features

  `Membership.Role` -> `Membership.Feature` [m-n] - Any given role can have multiple features


  ## Calculating permissions

  Calculation of permissions is done by 2 ets tables one holding the logged in members permissions the other holds modules function/permissions, then
    true = Enum.member?(module_permissions, member_permissions)


  ## Available as_authorized
    * `Membership.has_plan/1` - Requires single plan to be present on member
    * `Membership.has_role/1` - Requires single role to be present on member
    * `Membership.has_feature/1` - Requires single feature to be present on member

  """

  @default_features %{required_features: []}

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

  @doc """
  Macro for defining required permissions

  ## Example

      defmodule HelloTest do
        use Membership

        def test_authorization do
          permissions do
            has_feature(:admin_feature, :test_authorization)
            has_plan(:gold, :test_authorization)
          end
        end
      end
  """
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

  @doc """
  The Function list to ignore when building the permissions registry's
  """
  def ignored_functions() do
    Membership.module_info()
    |> Keyword.fetch!(:exports)
    |> Enum.map(fn {key, _data} -> key end)
  end

  @doc """
  Load the plans into ets for the module/functions
  """
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
          default = %{
            required_features: [],
            calculated_as_authorized: []
          }

          Membership.Permission.Server.insert(current_module, x, default)
        end)
    end
  end

  @doc """
  Macro for wrapping protected code

  ## Example

      defmodule HelloTest do
        use Membership
        member = HelloTest.Repo.get(Membership.Member, 1)
        {:ok, member }  = load_and_authorize_member(member)

        def test_authorization do
          as_authorized(member, :test_authorization) do
            IO.inspect("This code is executed only for authorized member")
          end
        end
      end
  """

  defmacro as_authorized(member, func_name, do: block) do
    quote do
      with :ok <- perform_authorization!(unquote(member), unquote(func_name)) do
        unquote(block)
      end
    end
  end

  @doc """
  Defines calculated permission to be evaluated in runtime

  ## Examples

      defmodule HelloTest do
        use Membership
        member = HelloTest.Repo.get(Membership.Member, 1)
        {:ok, member }  = load_and_authorize_member(member)

        def test_authorization do
          permissions do
            calculated(fn member ->
              member.email_confirmed?
            end)
          end

          as_authorized(member) do
            IO.inspect("This code is executed only for authorized member")
          end
        end
      end

  You can also use DSL form which takes function name as argument

        defmodule HelloTest do
        use Membership

        def test_authorization do
        use Membership
        member = HelloTest.Repo.get(Membership.Member, 1)
       {:ok, member } = load_and_authorize_member(member)

          permissions do
            calculated(member,:email_confirmed, :calculated)
          end

          as_authorized(member) do
            IO.inspect("This code is executed only for authorized member")
          end
        end

        def email_confirmed(member) do
          member.email_confirmed?
        end
      end

    For more complex calculation you need to pass bindings to the function

        defmodule HelloTest do
        use Membership
        member = HelloTest.Repo.get(Membership.Member, 1)
        {:ok, member} = load_and_authorize_member(member)

        def test_authorization do
          post = %Post{owner_id: 1}

          permissions do
            calculated(member,:is_owner, [post])
            calculated(fn member, [post] ->
              post.owner_id == member.id
            end)
          end

          as_authorized(member) do
            IO.inspect("This code is executed only for authorized member")
          end
        end

        def is_owner(member, [post]) do
          post.owner_id == member.id
        end
      end

  """
  defmacro calculated(current_member, func_name)
           when is_atom(func_name) do
    quote do
      {:ok, current_member} = Membership.Member.Server.show(unquote(current_member))

      rules = %{calculated_as_authorized: unquote(func_name)(current_member)}

      registry =
        Membership.Registry.add(
          __MODULE__,
          unquote(func_name),
          rules
        )
    end
  end

  defmacro calculated(current_member, callback, func_name) when is_atom(func_name) do
    quote do
      {:ok, current_member} = Membership.Member.Server.show(unquote(current_member))
      result = apply(unquote(callback), [current_member])

      rules = %{calculated_as_authorized: result}

      Membership.Registry.add(
        __MODULE__,
        unquote(func_name),
        rules
      )
    end
  end

  defmacro calculated(current_member, func_name, bindings) when is_atom(func_name) do
    quote do
      {:ok, current_member} = Membership.Member.Server.show(unquote(current_member))
      result = unquote(func_name)(current_member, unquote(bindings))
      rules = %{calculated_as_authorized: result}

      Membership.Registry.add(
        __MODULE__,
        unquote(func_name),
        rules
      )
    end
  end

  defmacro calculated(current_member, callback, bindings, func_name)
           when is_atom(func_name) do
    quote do
      {:ok, current_member} = Membership.Member.Server.show(unquote(current_member))
      result = apply(unquote(callback), [current_member, unquote(bindings)])
      rules = %{calculated_as_authorized: result}

      Membership.Registry.add(
        __MODULE__,
        unquote(func_name),
        rules
      )
    end
  end

  @doc ~S"""
  Returns authorization result on collected member and required features/plans

  ## Example

      defmodule HelloTest do
        use Membership

        def test_authorization do
          case authorized? do
            :ok -> "Member is authorized"
            {:error, message: _message} -> "Member is not authorized"
        end
      end
  """
  # @spec authorized?() :: :ok | {:error, String.t()}
  def authorized?(member, func_name) do
    perform_authorization!(member, func_name)
  end

  @doc """
  Perform authorization on passed member and plans
  """
  @spec has_plan?(Membership.Member.t(), atom(), String.t()) :: boolean()
  def has_plan?(%Membership.Member{} = member, func_name, plan_name) do
    perform_authorization!(member, func_name, [], [Atom.to_string(plan_name)]) == :ok
  end

  @doc """
  Perform authorization on passed member and roles
  """
  @spec has_role?(Membership.Member.t(), atom(), String.t()) :: boolean()
  def has_role?(%Membership.Member{} = member, role_name) do
    roles = Enum.map(member.roles, fn x -> x.identifier end)
    Enum.member?(roles, role_name) == true
  end

  @doc """
  Perform authorization on passed member and roles
  """
  @spec has_role?(Membership.Member.t(), atom(), String.t()) :: boolean()
  def has_role?(%Membership.Member{} = member, func_name, role_name) do
    perform_authorization!(member, func_name, [], [], [Atom.to_string(role_name)]) == :ok
  end

  @doc """
  Perform feature check on passed member and feature
  """
  def has_feature?(%Membership.Member{} = member, feature_name) do
    Enum.member?(member.features, feature_name)
  end

  def has_feature?(%Membership.Member{} = member, func_name, feature_name) do
    perform_authorization!(member, func_name, [Atom.to_string(feature_name)]) == :ok
  end

  @doc false
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
      rules = fetch_rules_from_ets(func_name)

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
          role_features ++ rules.required_features

      # If no as_authorized were required then we can assume member is granted
      if length(required_features) do
        :ok
      else
        reply =
          authorize!(
            [
              authorize_features(current_member.features, required_features)
            ] ++
              rules.calculated_as_authorized
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

  @doc false
  def create_membership() do
    quote do
      import Membership, only: [load_and_store_member!: 2]

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

      def load_and_authorize_member(member),
        do: nil
    end
  end

  @doc false
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
      {:error, {:already_started, _}} -> member
      {:error, _} -> nil
    end
  end

  @doc false
  @spec load_and_store_member!(Membership.Member.t(), map()) :: {:ok, Membership.Member.t()}
  def load_and_store_member!(%Membership.Member{} = member, opts) do
    opts =
      case is_nil(opts) do
        true -> %{}
        false -> opts
      end

    member = Membership.Repo.get!(Membership.Member, member.id) |> Map.merge(opts)
    status = Membership.Memberships.Supervisor.start(member)

    case status do
      {:ok, _} -> member
      {:error, {:already_started, _}} -> member
      {:error, _} -> nil
    end
  end

  @doc false
  @spec load_member_features(Membership.Member.t()) :: Membership.Member.t()
  def load_member_features(member) do
    member
  end

  @doc false
  def authorize_features(active_features \\ [], required_features \\ []) do
    active_features = Enum.map(active_features, fn x -> String.to_atom(x) end)

    authorized =
      Enum.filter(required_features, fn feature ->
        Enum.member?(active_features, feature)
      end)

    length(authorized) > 0
  end

  @doc false
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

  @doc """
  Requires an plan within permissions block

  ## Example

      defmodule HelloTest do
        use Membership

        def test_authorization do
          permissions do
            has_plan(:gold, :test_authorization)
          end
        end
      end
  """
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

  @doc """
  Requires an role within permissions block

  ## Example

      defmodule HelloTest do
        use Membership

        def test_authorization do
          permissions do
            has_role(:gold, :test_authorization)
          end
        end
      end
  """
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

  @doc """
  Requires a feature within permissions block

  ## Example

      defmodule HelloTest do
        use Membership

        def test_authorization do
          permissions do
            has_feature(:admin)
          end
        end
      end
  """
  @spec has_feature(atom(), atom()) :: {:ok, atom()}
  def has_feature(feature, func_name) do
    Membership.Registry.add(__MODULE__, func_name, feature)
    {:ok, feature}
  end

  @doc """
  List version.

  ## Examples

      iex> Membership.version()
  """
  @version Mix.Project.config()[:version]
  def version, do: @version
end

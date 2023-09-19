defmodule Membership do
  @moduledoc """
  Main Membership module for including macros

  Membership has 3 main components:

    * `Membership.Plan` -  Representation of a single plan e.g. :gold, :silver, :copper
    * `Membership.Member` - Main actor which is holding given plans
    * `Membership.Feature` - Feature of a plan eg. :edit_feature

  ## Relations between models

  `Membership.Member`  -> `Membership.Feature`[1-n] - Any given member have multiple features with this we can have more granular features for each member is adding a specific feature to a member not in his plan

  `Membership.Member` -> `Membership.Plan` [1-n] - Any given member can have multiple plans

  `Membership.Plan` -> `Membership.Plan.Feature` [m-n] - Any given plan can have multiple features


  ## Calculating plans

  Calculation of plans is done by *OR* and *DISTINCT* plans. That means if you have

  `MemberPlans[:user, plans: [:gold]]`, `MemberPlans[:user, plans: [:silver]]`, `MemberPlans[:user, plans: [:bronze]]`
  and all plans are granted to single member, resulting plans will be `[:gold, :silver, :bronze]`


  ## Available as_member
  ##todo:: rewrite has_plan to compare features on member vs plan vs plan name in plans array
    * `Membership.has_plan/1` - Requires single plan to be present on member
    * `Membership.has_feature/1` - Requires single feature to be present on member

  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      registry = Keyword.fetch!(opts, :registry)

      import unquote(__MODULE__)

      def ets_exists(module \\ registry) do
        case :ets.whereis(module) do
          :undefined -> false
          _ -> true
        end

        true
      end

      def load_membership_plans() do
        case ets_exists(:membership_plans) do
          true ->
            :ok

          false ->
            Map.__info__(:functions)
            |> Enum.filter(fn {x, _} -> Enum.member?(ignored_functions(), x) end)
            |> Enum.each(fn {x, _} ->
              default = %{
                required_features: [],
                calculated_as_member: [],
                extra_rules: []
              }

              Membership.Registry.insert(registry, x, default)
            end)
        end
      end

      defmacro calculated_member(current_member, func_name)
               when is_atom(func_name) do
        quote do
          {:ok, current_member} = Membership.Member.Server.show(unquote(current_member))

          rules = %{calculated_as_member: unquote(func_name)(current_member)}

          registry =
            Membership.Registry.add(
              registry,
              unquote(func_name),
              rules
            )
        end
      end

      defmacro calculated_member(current_member, callback, func_name) when is_atom(func_name) do
        quote do
          {:ok, current_member} = Membership.Member.Server.show(unquote(current_member))
          result = apply(unquote(callback), [current_member])

          rules = %{calculated_as_member: result}

          Membership.Registry.add(
            registry,
            unquote(func_name),
            rules
          )
        end
      end

      defmacro calculated_member(current_member, func_name, bindings) when is_atom(func_name) do
        quote do
          {:ok, current_member} = Membership.Member.Server.show(unquote(current_member))
          result = unquote(func_name)(current_member, unquote(bindings))
          rules = %{calculated_as_member: result}

          Membership.Registry.add(
            registry,
            unquote(func_name),
            rules
          )
        end
      end

      defmacro calculated_member(current_member, callback, bindings, func_name)
               when is_atom(func_name) do
        quote do
          {:ok, current_member} = Membership.Member.Server.show(unquote(current_member))
          result = apply(unquote(callback), [current_member, unquote(bindings)])
          rules = %{calculated_as_member: result}

          Membership.Registry.add(
            registry,
            unquote(func_name),
            rules
          )
        end
      end

      defp fetch_rules_from_ets(func_name) do
        {:ok, value} = Membership.Registry.lookup(registry, func_name)
        value
      end

      @spec has_plan(atom(), atom()) :: {:ok, atom()}
      def has_plan(plan, func_name) do
        case :ets.lookup(:membership_plans, plan) do
          [] ->
            {:error, "plan: #{plan} Not Found"}

          {plan, features} ->
            Membership.Registry.add(registry, func_name, features)
            {:ok, plan}
        end
      end

      @spec has_feature(atom(), atom()) :: {:ok, atom()}
      def has_feature(feature, func_name) do
        Membership.Registry.add(registry, func_name, feature)
        {:ok, feature}
      end

      #      defoverridable fun_with_default: 0
      @before_compile unquote(__MODULE__)
    end
  end

  ### end of using
  defmacro __before_compile__(_env) do
    create_membership()
  end

  @doc """
  Macro for defining required permissions

  ## Example

      defmodule HelloTest do
        use Membership

        def test_authorization do
          member_permissions do
            has_feature(:admin_feature, :test_authorization)
            has_plan(:gold, :test_authorization)
          end
        end
      end
  """

  defmacro member_permissions(do: block) do
    quote do
      load_membership_plans()
      unquote(block)
    end
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
  Check if membership ets exists for the module
  """
  def ets_exists(module \\ __MODULE__) do
    case :ets.whereis(module) do
      :undefined -> false
      _ -> true
    end

    true
  end

  @doc """
  Load the plans into ets for the module/functions
  """
  def load_membership_plans() do
    case ets_exists(:membership_plans) do
      true ->
        :ok

      false ->
        Map.__info__(:functions)
        |> Enum.filter(fn {x, _} -> Enum.member?(ignored_functions(), x) end)
        |> Enum.each(fn {x, _} ->
          default = %{
            required_features: [],
            calculated_as_member: [],
            extra_rules: []
          }

          Membership.Registry.insert(__MODULE__, x, default)
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
          as_member(member, :test_authorization) do
            IO.inspect("This code is executed only for authorized member")
          end
        end
      end
  """

  defmacro as_member(member, func_name, do: block) do
    quote do
      with :ok <- member_authorization!(unquote(member), unquote(func_name)) do
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
          member_permissions do
            calculated_member(fn member ->
              member.email_confirmed?
            end)
          end

          as_member(member) do
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

          member_permissions do
            calculated_member(member,:email_confirmed)
          end

          as_member(member) do
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

          member_permissions do
            calculated_member(member,:is_owner, [post])
            calculated_member(fn member, [post] ->
              post.owner_id == member.id
            end)
          end

          as_member(member) do
            IO.inspect("This code is executed only for authorized member")
          end
        end

        def is_owner(member, [post]) do
          post.owner_id == member.id
        end
      end

  """
  defmacro calculated_member(current_member, func_name)
           when is_atom(func_name) do
    quote do
      {:ok, current_member} = Membership.Member.Server.show(unquote(current_member))

      rules = %{calculated_as_member: unquote(func_name)(current_member)}

      registry =
        Membership.Registry.add(
          __MODULE__,
          unquote(func_name),
          rules
        )
    end
  end

  defmacro calculated_member(current_member, callback, func_name) when is_atom(func_name) do
    quote do
      {:ok, current_member} = Membership.Member.Server.show(unquote(current_member))
      result = apply(unquote(callback), [current_member])

      rules = %{calculated_as_member: result}

      Membership.Registry.add(
        __MODULE__,
        unquote(func_name),
        rules
      )
    end
  end

  defmacro calculated_member(current_member, func_name, bindings) when is_atom(func_name) do
    quote do
      {:ok, current_member} = Membership.Member.Server.show(unquote(current_member))
      result = unquote(func_name)(current_member, unquote(bindings))
      rules = %{calculated_as_member: result}

      Membership.Registry.add(
        __MODULE__,
        unquote(func_name),
        rules
      )
    end
  end

  defmacro calculated_member(current_member, callback, bindings, func_name)
           when is_atom(func_name) do
    quote do
      {:ok, current_member} = Membership.Member.Server.show(unquote(current_member))
      result = apply(unquote(callback), [current_member, unquote(bindings)])
      rules = %{calculated_as_member: result}

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
          case member_authorized? do
            :ok -> "Member is authorized"
            {:error, message: _message} -> "Member is not authorized"
        end
      end
  """
  @spec member_authorized?() :: :ok | {:error, String.t()}
  def member_authorized? do
    member_authorization!()
  end

  @doc """
  Perform authorization on passed member and plans
  """
  @spec has_plan?(Membership.Member.t(), atom(), String.t()) :: boolean()
  def has_plan?(%Membership.Member{} = member, func_name, plan_name) do
    member_authorization!(member, func_name, [], [Atom.to_string(plan_name)]) == :ok
  end

  #  def has_plan?(
  #        %Membership.Member{} = member,
  #        plan_name,
  #        %{__struct__: _entity_name, id: _entity_id} = entity
  #      ) do
  #    active_plans =
  #      case Membership.Member.load_member_features(member, entity) do
  #        nil -> []
  #        entity -> entity.plans
  #      end
  #
  #    Enum.member?(active_plans, Atom.to_string(plan_name))
  #  end

  @doc """
  Perform feature check on passed member and feature
  """
  def has_feature?(%Membership.Member{} = member, feature_name) do
    Enum.member?(member.features, feature_name)
  end

  def has_feature?(%Membership.Member{} = member, func_name, feature_name) do
    member_authorization!(member, func_name, [Atom.to_string(feature_name)]) == :ok
  end

  @doc false
  def member_authorization!(
        current_member \\ nil,
        func_name \\ nil,
        _required_features \\ [],
        required_plans \\ [],
        _extra_rules \\ []
      ) do
    # If no member is given we can assume that as_member are not granted
    if is_nil(current_member) do
      {:error, "Member is not granted to perform this action"}
    else
      rules = fetch_rules_from_ets(func_name)

      plan_features =
        List.flatten(
          Enum.map(required_plans, fn p ->
            p.features
          end)
        )

      # If no as_member were required then we can assume member is granted
      if length(plan_features) + length(rules.required_features) +
           length(rules.calculated_as_member) +
           length(rules.extra_rules) == 0 do
        :ok
      else
        reply =
          authorize!(
            [
              authorize_features(current_member.features, rules.required_features)
            ] ++ rules.calculated_as_member ++ rules.extra_rules
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
    {:error, "Unknown ETS Record for Registry registry"}
  end

  defp fetch_rules_from_ets(func_name) do
    {:ok, value} = Membership.Registry.lookup(__MODULE__, func_name)
    value
  end

  @doc false
  def create_membership() do
    quote do
      import Membership, only: [load_and_store_member!: 1]

      def load_and_authorize_member(%Membership.Member{id: _id} = member),
        do: load_and_store_member!(member)

      def load_and_authorize_member(%{member: %Membership.Member{id: _id} = member}),
        do: load_and_store_member!(member)

      def load_and_authorize_member(%{member_id: member_id})
          when not is_nil(member_id),
          do: load_and_store_member!(member_id)

      def load_and_authorize_member(member),
        do: raise(ArgumentError, message: "Invalid member given #{inspect(member)}")
    end
  end

  @doc false
  @spec load_and_store_member!(integer()) :: {:ok, Membership.Member.t()}
  def load_and_store_member!(member_id) when is_integer(member_id) do
    member = Membership.Repo.get!(Membership.Member, member_id)
    {status, _} = Membership.Memberships.Supervisor.start(member)
    {status, member}
  end

  @doc false
  @spec load_and_store_member!(Membership.Member.t()) :: {:ok, Membership.Member.t()}
  def load_and_store_member!(%Membership.Member{id: _id} = member) do
    {status, _} = Membership.Memberships.Supervisor.start(member)
    {status, member}
  end

  @doc false
  @spec load_member_features(Membership.Member.t()) :: Membership.Member.t()
  def load_member_features(member) do
    member
  end

  @doc false
  def authorize_inherited_features(active_features \\ [], required_features \\ []) do
    active_features =
      active_features
      |> Enum.map(& &1.features)
      |> List.flatten()
      |> Enum.uniq()

    authorized =
      Enum.filter(required_features, fn feature ->
        Enum.member?(active_features, feature)
      end)

    length(authorized) > 0
  end

  @doc false
  def authorize_features(active_features \\ [], required_features \\ []) do
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
        0 -> conditions ++ [true]
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
  Requires an plan within member_permissions block

  ## Example

      defmodule HelloTest do
        use Membership

        def test_authorization do
          member_permissions do
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

  #  def has_plan(
  #        plan,
  #        %{__struct__: _entity_name, id: _entity_id} = entity,
  #        current_member \\ :current_member,
  #        func_name \\ nil
  #      ) do
  #    {:ok, current_member} = Membership.Member.Server.show(current_member)
  #    rules = %{extra_rules: has_plan?(current_member, plan, entity)}
  #    Membership.Registry.add(__MODULE__, func_name, rules)
  #    {:ok, plan}
  #  end

  @doc """
  Requires a feature within member_permissions block

  ## Example

      defmodule HelloTest do
        use Membership

        def test_authorization do
          member_permissions do
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

  def normalize_struct_name(name) do
    name
    |> Atom.to_string()
    |> String.replace(".", "_")
    |> String.downcase()
    |> String.to_atom()
  end

  @doc """
  List version.

  ## Examples

      iex> Membership.version()
  """
  @version Mix.Project.config()[:version]
  def version, do: @version
end

defmodule Membership do
  @moduledoc """
  Main Membership module for including macros

  Membership has 3 main components:

    * `Membership.Plan` -  Representation of a single plan e.g. :gold, :silver, :copper
    * `Membership.Member` - Main actor which is holding given plans
    * `Membership.MemberPlans` - Grouped set of multiple plans, e.g. :admin, :manager, :editor

  ## Relations between models

  `Membership.Plan` -> `Membership.Plan.Feature` [1-n] - Any given plan can hold multiple features

  `Membership.Member` -> `Membership.Plan` [1-n] - Any given member can hold multiple plans
  this allows you to have very granular set of plans per each member

  `Membership.Member` -> `Membership.MemberPlans` [1-n] - Any given member can act as multiple plans
  this allows you to manage multple sets of plans for multiple members at once

  ## Calculating plans

  Calculation of plans is done by *OR* and *DISTINCT* plans. That means if you have

  `MemberPlans[:admin, plans: [:gold]]`, `MemberPlans[:editor, plans: [:silver]]`, `MemberPlans[:user, plans: [:bromze]]`
  and all plans are granted to single member, resulting plans will be `[:gold, :silver, :bronze]`


  ## Available as_member

    * `Membership.has_plan/1` - Requires single plan to be present on member
    * `Membership.has_feature/1` - Requires single feature to be present on member

  """

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    create_membership()
  end

  @doc """
  Macro for defining required as_member

  ## Example

      defmodule HelloTest do
        use Membership

        def test_authorization do
          as_member do
            has_feature(:admin)
            has_plan(:view)
          end
        end
      end
  """

  defmacro as_member(do: block) do
    quote do
      reset_session()
      unquote(block)
    end
  end

  @doc """
  Resets ETS table
  """
  def reset_session() do
    Membership.Registry.insert(:required_plans, [])
    Membership.Registry.insert(:required_features, [])
    Membership.Registry.insert(:calculated_as_member, [])
    Membership.Registry.insert(:extra_rules, [])
  end

  @doc """
  Macro for wrapping protected code

  ## Example

      defmodule HelloTest do
        use Membership

        def test_authorization do
          as_member do
            IO.inspect("This code is executed only for authorized member")
          end
        end
      end
  """

  defmacro as_member(do: block) do
    quote do
      with :ok <- member_authorization!() do
        unquote(block)
      end
    end
  end

  @doc """
  Defines calculated permission to be evaluated in runtime

  ## Examples

      defmodule HelloTest do
        use Membership

        def test_authorization do
          as_member do
            calculated_member(fn member ->
              member.email_confirmed?
            end)
          end

          as_member do
            IO.inspect("This code is executed only for authorized member")
          end
        end
      end

  You can also use DSL form which takes function name as argument

        defmodule HelloTest do
        use Membership

        def test_authorization do
          as_member do
            calculated_member(:email_confirmed)
          end

          as_member do
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

        def test_authorization do
          post = %Post{owner_id: 1}

          as_member do
            calculated_member(:is_owner, [post])
            calculated_member(fn member, [post] ->
              post.owner_id == member.id
            end)
          end

          as_member do
            IO.inspect("This code is executed only for authorized member")
          end
        end

        def is_owner(member, [post]) do
          post.owner_id == member.id
        end
      end

  """
  defmacro calculated_member(func_name) when is_atom(func_name) do
    quote do
      {:ok, current_member} = Membership.Registry.lookup(:current_member)

      Membership.Registry.add(
        :calculated_as_member,
        unquote(func_name)(current_member)
      )
    end
  end

  defmacro calculated_member(callback) do
    quote do
      {:ok, current_member} = Membership.Registry.lookup(:current_member)

      result = apply(unquote(callback), [current_member])

      Membership.Registry.add(
        :calculated_as_member,
        result
      )
    end
  end

  defmacro calculated_member(func_name, bindings) when is_atom(func_name) do
    quote do
      {:ok, current_member} = Membership.Registry.lookup(:current_member)

      result = unquote(func_name)(current_member, unquote(bindings))

      Membership.Registry.add(
        :calculated_as_member,
        result
      )
    end
  end

  defmacro calculated_member(callback, bindings) do
    quote do
      {:ok, current_member} = Membership.Registry.lookup(:current_member)

      result = apply(unquote(callback), [current_member, unquote(bindings)])

      Membership.Registry.add(
        :calculated_as_member,
        result
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
  @spec has_plan?(Membership.Member.t(), atom()) :: boolean()
  def has_plan?(%Membership.Member{} = member, plan_name) do
    member_authorization!(member, [Atom.to_string(plan_name)], []) == :ok
  end

  def has_plan?(
        %Membership.Member{} = member,
        plan_name,
        %{__struct__: _entity_name, id: _entity_id} = entity
      ) do
    active_plans =
      case Membership.Member.load_member_entities(member, entity) do
        nil -> []
        entity -> entity.plans
      end

    Enum.member?(active_plans, Atom.to_string(plan_name))
  end

  @doc """
  Perform feature check on passed member and feature
  """
  def has_feature?(%Membership.Member{} = member, feature_name) do
    member_authorization!(member, nil, [Atom.to_string(feature_name)], nil) == :ok
  end

  @doc false
  def member_authorization!(
        current_member \\ nil,
        required_plans \\ [],
        required_features \\ [],
        extra_rules \\ []
      ) do
    current_member =
      case current_member do
        nil ->
          {:ok, current_member} = Membership.Registry.lookup(:current_member)
          current_member

        _ ->
          current_member
      end

    required_plans = ensure_membership_array_from_ets(required_plans, :required_plans)
    required_features = ensure_membership_array_from_ets(required_features, :required_features)
    extra_rules = ensure_membership_array_from_ets(extra_rules, :extra_rules)
    calculated_as_member = ensure_membership_array_from_ets([], :calculated_as_member)

    # If no member is given we can assume that as_member are not granted
    if is_nil(current_member) do
      {:error, "Member is not granted to perform this action"}
    else
      # If no as_member were required then we can assume performe is granted
      if length(required_plans) + length(required_features) + length(calculated_as_member) +
           length(extra_rules) == 0 do
        :ok
      else
        # 1st layer of authorization (optimize db load)
        first_layer =
          authorize!(
            [
              authorize_plans(current_member.plans, required_plans)
            ] ++ calculated_as_member ++ extra_rules
          )

        if first_layer == :ok do
          first_layer
        else
          # 2nd layer with DB preloading of features
          %{features: current_features} = load_member_features(current_member)

          second_layer =
            authorize!([
              authorize_features(current_features, required_features),
              authorize_inherited_plans(current_features, required_plans)
            ])

          if second_layer == :ok do
            second_layer
          else
            {:error, "Member is not granted to perform this action"}
          end
        end
      end
    end
  end

  defp ensure_membership_array_from_ets(value, name) do
    value =
      case value do
        [] ->
          {:ok, value} = Membership.Registry.lookup(name)
          value

        value ->
          value
      end

    case value do
      nil -> []
      _ -> value
    end
  end

  @doc false
  def create_membership() do
    quote do
      import Membership, only: [store_member!: 1, load_and_store_member!: 1]

      def load_and_authorize_member(%Membership.Member{id: _id} = member),
          do: store_member!(member)

      def load_and_authorize_member(%{member: %Membership.Member{id: _id} = member}),
          do: store_member!(member)

      def load_and_authorize_member(%{member_id: member_id})
          when not is_nil(member_id),
          do: load_and_store_member!(member_id)

      def load_and_authorize_member(member),
          do: raise(ArgumentError, message: "Invalid member given #{inspect(member)}")
    end
  end

  @doc false
  @spec load_and_store_member!(integer()) :: {:ok, Membership.Member.t()}
  def load_and_store_member!(member_id) do
    member = Membership.Repo.get!(Membership.Member, member_id)
    store_member!(member)
  end

  @doc false
  @spec load_member_features(Membership.Member.t()) :: Membership.Member.t()
  def load_member_features(member) do
    member |> Membership.Repo.preload([:features])
  end

  @doc false
  @spec store_member!(Membership.Member.t()) :: {:ok, Membership.Member.t()}
  def store_member!(%Membership.Member{id: _id} = member) do
    Membership.Registry.insert(:current_member, member)
    {:ok, member}
  end

  @doc false
  def authorize_plans(active_plans \\ [], required_plans \\ []) do
    authorized =
      Enum.filter(required_plans, fn plan ->
        Enum.member?(active_plans, plan)
      end)

    length(authorized) > 0
  end

  @doc false
  def authorize_inherited_plans(active_features \\ [], required_plans \\ []) do
    active_plans =
      active_features
      |> Enum.map(& &1.plans)
      |> List.flatten()
      |> Enum.uniq()

    authorized =
      Enum.filter(required_plans, fn plan ->
        Enum.member?(active_plans, plan)
      end)

    length(authorized) > 0
  end

  @doc false
  def authorize_features(active_features \\ [], required_features \\ []) do
    active_features =
      active_features
      |> Enum.map(& &1.identifier)
      |> Enum.uniq()

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
  Requires an plan within as_member block

  ## Example

      defmodule HelloTest do
        use Membership

        def test_authorization do
          as_member do
            has_plan(:can_run_test_authorization)
          end
        end
      end
  """
  @spec has_plan(atom()) :: {:ok, atom()}
  def has_plan(plan) do
    Membership.Registry.add(:required_plans, Atom.to_string(plan))
    {:ok, plan}
  end

  def has_plan(plan, %{__struct__: _entity_name, id: _entity_id} = entity) do
    {:ok, current_member} = Membership.Registry.lookup(:current_member)

    Membership.Registry.add(:extra_rules, has_plan?(current_member, plan, entity))
    {:ok, plan}
  end

  @doc """
  Requires a feature within as_member block

  ## Example

      defmodule HelloTest do
        use Membership

        def test_authorization do
          as_member do
            has_feature(:admin)
          end
        end
      end
  """
  @spec has_feature(atom()) :: {:ok, atom()}
  def has_feature(feature) do
    Membership.Registry.add(:required_features, Atom.to_string(feature))
    {:ok, feature}
  end
end

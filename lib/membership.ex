defmodule Membership do
  @moduledoc """
  Main Membership module for including macros

  Membership has 3 main components:

    * `Membership.Plan` - Representation of a single plan e.g. :gold, :silver, :copper
    * `Membership.Feature` - Representation of a single plan feature e.g. :feature_a, :feature_b, :feature_c
    * `Membership.Member` - Main actor which is holding given plans

  ## Relations between models

  `Membership.Member` -> `Membership.Plan` [1-n] - Any given member can hold multiple plans
  this allows you to have very granular set of plans per each member

  `Membership.Member` -> `Membership.Plan.Feature` [1-n] - Any given member can hold multiple plan features
  this allows you to have very granular set of which plan features each member has access to.


  ## Available functions

    * `Membership.has_plan/1` - Requires single plan to be present on member

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
  Resets ETS table
  """
  def reset_session() do
    Membership.Registry.insert(:required_plans, [])
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
            IO.inspect("This code is executed only for authorized member")
          end
        end
      end

  You can also use DSL form which takes function name as argument

        defmodule HelloTest do
        use Membership

        def test_authorization do

          as_member do
            IO.inspect("This code is executed only for authorized member")
          end
        end

      end

    For more complex calculation you need to pass bindings to the function

        defmodule HelloTest do
        use Membership

        def test_authorization do
          post = %Post{owner_id: 1}


          as_member do
            IO.inspect("This code is executed only for authorized member")
          end
        end

      end

  """

  @doc ~S"""
  Returns authorization result on collected member and required roles/plans

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

  @doc false
  def member_authorization!(
        current_member \\ nil,
        required_plans \\ [],
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
    extra_rules = ensure_membership_array_from_ets(extra_rules, :extra_rules)

    # If no member is given we can assume that permissions are not granted
    if is_nil(current_member) do
      {:error, "Member is not granted to perform this action"}
    else
      # If no permissions were required then we can assume performe is granted
      if length(required_plans) +
           length(extra_rules) == 0 do
        :ok
      else
        # 1st layer of authorization (optimize db load)
        first_layer =
          member_authorize!(
            [
              authorize_plans(current_member.plans, required_plans)
            ] ++ extra_rules
          )

        if first_layer == :ok do
          first_layer
        else
          {:error, "Member is not granted to perform this action"}
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
  @spec load_member_roles(Membership.Member.t()) :: Membership.Member.t()
  def load_member_roles(member) do
    member |> Membership.Repo.preload([:roles])
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
  def authorize_inherited_plans(active_roles \\ [], required_plans \\ []) do
    active_plans =
      active_roles
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
  def member_authorize!(conditions) do
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
  Requires an plan within permissions block

  ## Example

      defmodule HelloTest do
        use Membership

        def test_authorization do
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
end

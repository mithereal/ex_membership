defmodule Membership.Behaviour do
  defmacro __using__(opts) do
    quote do
      opts = unquote(opts)
      @registry Keyword.fetch!(opts, :registry)

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
          load_ets_data(unquote(@registry))
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
      Load the plans into ets for the module/functions
      """
      def load_ets_data(current_module \\ @registry) do
        status = Membership.Permissions.Supervisor.start(current_module)

        case status do
          {:error, _} ->
            status

          {:ok, _} ->
            Map.__info__(:functions)
            |> Enum.filter(fn {x, _} -> Enum.member?(ignored_functions(), x) end)
            |> Enum.each(fn {x, _} ->
              default = %{
                required_features: [],
                calculated_as_authorized: [],
                extra_rules: []
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
                calculated(member,:email_confirmed)
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
              @registry,
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
            @registry,
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
            @registry,
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
            @registry,
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
      @spec authorized?() :: :ok | {:error, String.t()}
      def authorized? do
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
        # If no member is given we can assume that as_authorized are not granted
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

          # If no as_authorized were required then we can assume member is granted
          if length(plan_features) + length(rules.required_features) +
               length(rules.calculated_as_authorized) +
               length(rules.extra_rules) == 0 do
            :ok
          else
            reply =
              authorize!(
                [
                  authorize_features(current_member.features, rules.required_features)
                ] ++ rules.calculated_as_authorized ++ rules.extra_rules
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
        {:ok, value} = Membership.Registry.lookup(@registry, func_name)
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
            Membership.Registry.add(@registry, func_name, features)
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
        Membership.Registry.add(@registry, func_name, feature)
        {:ok, feature}
      end
    end
  end
end

defmodule Membership.RegistyTest do
  use ExUnit.Case
  alias Membership.Registry

  setup do
    Registry.start_link(%{identifier: Registry.normalize_struct_name(Registry)})
    :ok
  end

  describe "Membership.Registry.insert/2" do
    test "insert string item" do
      assert Registry.insert(Registry, :test_item, "John Snow")
    end

    test "insert struct item " do
      assert Registry.insert(Registry, :test_item, %{name: "John Snow"})
    end

    test "insert tuple item" do
      assert Registry.insert(Registry, :test_item, {:ok, %{name: "John Snow"}})
    end
  end

  describe "Membership.Registry.add/2" do
    test "add array item to the ets table" do
      assert Registry.add(Registry, :test_item, :dummy)
    end
  end

  describe "Membership.Registry.lookup/1" do
    test "lookup string item" do
      Registry.insert(Registry, :test_item, "John Snow")

      assert Registry.lookup(:test_item) == {:ok, "John Snow"}
    end

    test "lookup struct item" do
      Registry.insert(Registry, :test_item, %{name: "John Snow"})

      assert Registry.lookup(Registry, :test_item) == {:ok, %{name: "John Snow"}}
    end

    test "lookup tuple item" do
      Registry.insert(Registry, :test_item, {:ok, %{name: "John Snow"}})
      assert Registry.lookup(Registry, :test_item) == {:ok, {:ok, %{name: "John Snow"}}}
    end

    test "lookup non existing item" do
      assert Registry.lookup(Registry, :bogus_item) == {:ok, nil}
    end

    test "creates and array" do
      Registry.add(Registry, :test_item, :dummy)

      assert Registry.lookup(Registry, :test_item) == {:ok, [:dummy]}
    end

    test "insert and lookup array" do
      Registry.add(Registry, :test_item, :dummy)
      Registry.add(Registry, :test_item, :dummy2)

      assert Registry.lookup(Registry, :test_item) == {:ok, [:dummy, :dummy2]}
    end
  end
end

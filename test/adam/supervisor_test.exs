defmodule Adam.SupervisorTest do
  @moduledoc "Defines an `ExUnit.Case` case."
  @moduledoc since: "0.3.0"

  use ExUnit.Case, async: true

  alias Adam, as: Core
  alias AdamCase, as: Case

  alias Core.Supervisor

  @typedoc "Represents the current context."
  @typedoc since: "0.3.0"
  @type context() :: Case.context()

  @typedoc "Represents the context merge value."
  @typedoc since: "0.3.0"
  @type context_merge() :: Case.context_merge()

  @spec c_init_arg(context()) :: context_merge()
  defp c_init_arg(c) when is_map(c) do
    %{init_arg: %{invalid: %{}, valid: []}}
  end

  @spec start_supervisor!(context()) :: context_merge()
  defp start_supervisor!(c) when is_map(c) do
    start_supervised!(Supervisor)
    :ok
  end

  @spec c_err(context()) :: context_merge()
  defp c_err(c) when is_map(c) do
    %{err: {:error, {:already_started, Process.whereis(Supervisor)}}}
  end

  doctest Supervisor, import: true

  describe "child_spec/1" do
    import Supervisor, only: [child_spec: 1]

    setup :c_init_arg

    test "FunctionClauseError", %{init_arg: init_arg} do
      assert_raise FunctionClauseError, fn -> child_spec(init_arg.invalid) end
    end

    test "success", %{init_arg: init_arg} do
      assert child_spec(init_arg.valid) == %{
               id: Supervisor,
               start: {Supervisor, :start_link, [init_arg.valid]},
               type: :supervisor
             }
    end
  end

  describe "init/1" do
    import Supervisor, only: [init: 1]

    setup :c_init_arg

    test "FunctionClauseError", %{init_arg: init_arg} do
      assert_raise FunctionClauseError, fn -> init(init_arg.invalid) end
    end

    test "success", %{init_arg: init_arg} do
      assert init(init_arg.valid) == {
               :ok,
               {
                 %{intensity: 3, period: 5, strategy: :one_for_one},
                 init_arg.valid
               }
             }
    end
  end

  describe "start_link/1" do
    import Supervisor, only: [start_link: 1]

    setup ~w[start_supervisor! c_init_arg c_err]a

    test "FunctionClauseError", %{init_arg: init_arg} do
      assert_raise FunctionClauseError, fn -> start_link(init_arg.invalid) end
    end

    test "success", %{err: err, init_arg: init_arg} do
      assert start_link(init_arg.valid) == err
    end
  end

  describe "start_link/2" do
    import Supervisor, only: [start_link: 2]

    setup ~w[start_supervisor! c_init_arg c_err]a

    setup do
      %{opt: %{default: [name: Supervisor], empty: [], invalid: %{}}}
    end

    test "FunctionClauseError", %{init_arg: init_arg, opt: opt} do
      assert_raise FunctionClauseError, fn ->
        start_link(init_arg.invalid, opt.default)
      end

      assert_raise FunctionClauseError, fn ->
        start_link(init_arg.valid, opt.invalid)
      end
    end

    test "empty", %{init_arg: init_arg, opt: opt} do
      assert {:ok, _pid} = start_link(init_arg.valid, opt.empty)
    end

    test "default", %{err: err, init_arg: init_arg, opt: opt} do
      assert start_link(init_arg.valid, opt.default) == err
    end
  end
end

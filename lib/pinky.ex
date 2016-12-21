defmodule Pinky do
  @moduledoc """
  Pinky is a promise library for Elixir.
  """

  defmodule Promise do
    defstruct [:value, :error, :pid]
  end

  @doc """
  Constructs a promise already resolved with a predefined value.

  ## Examples

      iex> Pinky.extract(Pinky.resolved(3))
      {:ok, 3}

  """
  def resolved(v) do
    %Promise { value: v }
  end

  @doc """
  Constructs a promise already rejected with a predefined error.

  ## Examples

      iex> Pinky.extract(Pinky.rejected("something went wrong"))
      {:error, "something went wrong"}

  """
  def rejected(e) do
    %Promise { error: e }
  end

  @doc """
  Extracts the value (or the error) of a promise. It will block the caller
  process until the promise is realized.

  ## Examples

      iex> Pinky.extract(Pinky.promise(fn -> 1 + 2 end))
      {:ok, 3}

  """
  def extract(%Promise{ value: v }) when v != nil do
    {:ok, v}
  end

  def extract(%Promise{ error: e }) when e != nil do
    {:error, e}
  end

  def extract(%Promise{ pid: p }) do
    send(p, {:extract, self()})
    receive do
      {:resolve, pid, msg} when pid == p -> {:ok, msg}
      {:reject, pid, msg} when pid == p -> {:error, msg}
    end
  end

  @doc """
  Constructs a promise with a function that will run in a separate process.

  ## Examples

      iex> Pinky.extract(Pinky.promise(fn -> 1 + 2 end))
      {:ok, 3}

  """
  def promise(f) do
    pid = spawn(fn ->
      v = try do
            {:resolve, self(), f.()}
          rescue
            e -> {:reject, self(), e.message}
          end

      receive do
        {:extract, pid} -> send(pid, v)
      end
    end)

    %Promise { pid: pid }
  end

  @doc """
  Applies a function to the eventual result of a promise (when and if it's
  resolved successfully), and returns a promise that will evaluate to that
  result.

  ## Examples

      iex> Pinky.resolved(3) |> Pinky.map(fn x -> x + 1 end) |> Pinky.extract
      {:ok, 4}

      iex> Pinky.rejected("hell") |> Pinky.map(fn x -> x + 1 end) |> Pinky.extract
      {:error, "hell"}

  """
  def map(promise, f) do
    pid = spawn(fn ->
      v = case extract(promise) do
            {:ok, value} -> try do
                              {:resolve, self(), f.(value)}
                            rescue
                              e -> {:reject, self(), e}
                            end
            {:error, e} -> {:reject, self(), e}
          end
      receive do
        {:extract, pid} -> send(pid, v)
      end
    end)

    %Promise { pid: pid }
  end

  @doc """
  Applies a function to the eventual result of a promise (when and if it's
  resolved successfully), assuming the function will return another promise, and
  returns a promise that will evaluate to the result of the inner promise.

  ## Examples

      iex> Pinky.resolved(3) |>
      ...> Pinky.flat_map(fn x -> Pinky.promise(fn -> x + 1 end) end) |>
      ...> Pinky.extract
      {:ok, 4}

      iex> Pinky.rejected("outer failed") |>
      ...> Pinky.flat_map(fn x -> Pinky.promise(fn -> x + 1 end) end) |>
      ...> Pinky.extract
      {:error, "outer failed"}

      iex> Pinky.resolved(3) |>
      ...> Pinky.flat_map(fn x ->
      ...>                if x > 2 do
      ...>                  Pinky.rejected("inner failed")
      ...>                else
      ...>                  Pinky.promise(fn -> x + 1 end)
      ...>                end
      ...>               end) |>
      ...> Pinky.extract
      {:error, "inner failed"}

  """
  def flat_map(promise, f) do
    pid = spawn(fn ->
      v = case extract(promise) do
            {:ok, value} -> try do
                              case extract(f.(value)) do
                                {:ok, value} -> {:resolve, self(), value}
                                {:error, e} -> {:reject, self(), e}
                              end
                            rescue
                              e -> {:reject, self(), e}
                            end
            {:error, e} -> {:reject, self(), e}
          end
      receive do
        {:extract, pid} -> send(pid, v)
      end
    end)

    %Promise { pid: pid }
  end

  @doc """
  Takes a list of promises and returns a promise that will resolve only when all
  of them are successfully resolved. If one of them is rejected, the returned
  promise will be rejected too.

  ## Examples

      iex> Pinky.all([Pinky.resolved(3), Pinky.resolved(5)]) |> Pinky.extract
      {:ok, [3, 5]}

      iex> Pinky.all([Pinky.rejected("error"), Pinky.resolved(5)]) |> Pinky.extract
      {:error, "Some promises failed."}

  """
  def all(promises) do
    pid = spawn(fn ->
      results = for promise <- promises, do: extract(promise)
      result = if Enum.all?(results, fn({tag, _}) -> tag == :ok end) do
        {:resolve, self(), Enum.map(results, fn({_, v}) -> v end)}
      else
        {:reject, self(), "Some promises failed."}
      end
      receive do
        {:extract, pid} -> send(pid, result)
      end
    end)

    %Promise { pid: pid }
  end

  @doc """
  Takes a list of promises and returns a promise that will resolve only when all
  of them are successfully resolved. If one of them is rejected, the returned
  promise will be rejected too.

  ## Examples

      iex> Pinky.some([Pinky.resolved(3), Pinky.resolved(5)]) |> Pinky.extract
      {:ok, [3, 5]}

      iex> Pinky.some([Pinky.rejected("error"), Pinky.resolved(5)]) |> Pinky.extract
      {:ok, [5]}

  """
  def some(promises) do
    pid = spawn(fn ->
      results = for promise <- promises, do: extract(promise)
      result = {:resolve, self(),
                results
                |> Enum.filter(fn ({t, _}) -> t == :ok end)
                |> Enum.map(fn({_, v}) -> v end)}
      receive do
        {:extract, pid} -> send(pid, result)
      end
    end)

    %Promise { pid: pid }
  end
end

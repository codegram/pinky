# Pinky

[![Travis](https://img.shields.io/travis/codegram/pinky.svg?style=flat-square)](https://travis-ci.org/codegram/pinky)
[![Hex.pm](https://img.shields.io/hexpm/v/pinky.svg?style=flat-square)](https://hex.pm/packages/pinky)

A promise library for Elixir.

Pinky promises are composable, even though their underlying machinery uses
Elixir processes. Let's see an example:

```elixir
Pinky.promise(fn -> expensive_computation() end)
|> Pinky.map(fn result -> result + 5 end)
|> Pinky.flatmap(fn result ->
     if result > 10 do
       Pinky.promise(fn -> nested_computation(result) end)
     else
       Pinky.rejected("result too low")
     end
   end)
|> Pinky.extract # <- this call blocks until the whole promise is realized
# => {:ok, <some_result>}
```

Have a look at [the API documentation](https://hexdocs.pm/pinky/Pinky.html) to see detailed
examples of each of the primitives.

## Installation

The package can be installed by adding `pinky` to your list of dependencies in
`mix.exs`:

```elixir
def deps do
  [{:pinky, "~> 0.1.0"}]
end
```

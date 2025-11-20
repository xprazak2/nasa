defmodule Nasa.Constants do
  defmacro __using__(_) do
    quote do
      @earth "earth"
      @moon "moon"
      @mars "mars"

      @planets [@earth, @moon, @mars]

      @gravity %{
        @earth => 9.807,
        @moon => 1.62,
        @mars => 3.711
      }
    end
  end
end

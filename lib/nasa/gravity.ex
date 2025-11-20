defmodule Nasa.Gravity do
  use Nasa.Constants

  def earth() do
    @gravity[@earth]
  end

  def mars() do
    @gravity[@mars]
  end

  def moon() do
    @gravity[@moon]
  end

  def for_planet(planet) do
    @gravity[planet]
  end
end

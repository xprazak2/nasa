defmodule Nasa.Voyages.Voyage do
  @behaviour Nasa.Voyages.DefaultVoyageBehaviour

  alias Nasa.Voyages.Segment

  import Ecto.Changeset
  use Ecto.Schema

  schema "voyages" do
    field :weight, :integer
    field :fuel, :integer
    embeds_many :segments, Segment, on_replace: :delete
  end

  def changeset(voyage, attrs \\ %{}) do
    voyage
    |> cast(attrs, [:weight, :fuel])
    |> validate_number(:weight, greater_than_or_equal_to: 0)
    |> cast_embed(:segments, with: &Segment.changeset/2)
  end

  @impl true
  def default_changeset do
    default_voyage = default()

    changeset(default_voyage, %{})
  end

  def default() do
    %__MODULE__{
      weight: 0,
      fuel: 0,
      segments: [
        Segment.default()
      ]
    }
  end
end

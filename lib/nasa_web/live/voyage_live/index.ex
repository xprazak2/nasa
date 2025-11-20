defmodule NasaWeb.VoyageLive.Index do
  use NasaWeb, :live_view

  use Nasa.Constants

  alias Nasa.Voyages
  alias Nasa.Voyages.Voyage

  @default_voyage_provider Application.compile_env(:nasa, :default_voyage_provider)

  @impl true
  def mount(_params, _session, socket) do
    voyage = @default_voyage_provider.default_changeset()
    {:ok, socket |> assign(:form, to_form(voyage)) |> assign(:voyage, voyage)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"voyage" => voyage_params}, socket) do
    voyage = socket.assigns.voyage |> Voyage.changeset(voyage_params)

    new_voyage = voyage |> Voyages.calculate()

    socket |> apply_and_assign(new_voyage, voyage, :update)
  end

  @impl true
  def handle_event("add", _params, socket) do
    voyage = socket.assigns.voyage
    new_voyage = voyage |> Voyages.add()
    socket |> apply_and_assign(new_voyage, voyage, :insert)
  end

  @impl true
  def handle_event("remove", %{"id" => id}, socket) do
    voyage = socket.assigns.voyage

    new_voyage = voyage |> Voyages.remove(id)
    socket |> apply_and_assign(new_voyage, voyage, :replace)
  end

  defp apply_and_assign(socket, new_voyage, voyage, action) do
    if new_voyage.valid? do
      {:ok, data} = Ecto.Changeset.apply_action(new_voyage, action)

      {:noreply, socket |> assign_voyage(Voyage.changeset(data, %{}))}
    else
      {:noreply, socket |> assign_voyage(voyage)}
    end
  end

  defp assign_voyage(socket, voyage) do
    socket |> assign(:form, to_form(voyage, action: :validate)) |> assign(:voyage, voyage)
  end

  defp planet_options() do
    @planets |> Enum.map(fn val -> {val, val} end)
  end
end

defmodule NasaWeb.PageController do
  use NasaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

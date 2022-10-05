defmodule LeifWeb.PageController do
  use LeifWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

defmodule PhoenixRoyaleWeb.RoyaleLive do
  use Phoenix.LiveView
  alias PhoenixRoyale.GameServer

  def render(assigns) do
    # IO.inspect(assigns.game_state, label: "game state")
    case assigns.game_state do
      nil ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "join.html", assigns)

      %{server_status: :need_players} ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "lobby.html", assigns)

      %{server_status: :full} ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "game.html", assigns)

      %{server_status: :countdown} ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "game.html", assigns)

      %{server_status: :playing} ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "game.html", assigns)

      %{dead: true} ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "dead.html", assigns)
    end
  end

  def mount(_session, socket) do
    {:ok, assign(socket, game_state: nil, player_number: nil)}
  end

  def handle_info(:update, socket) do
    new_game_state = GameServer.state()

    player = Map.get(new_game_state.players, socket.assigns.player_number)

    if player.alive do
      {:noreply, assign(socket, game_state: new_game_state)}
    else
      {:noreply, assign(socket, game_state: Map.put(new_game_state, :dead, true))}
    end
  end

  def handle_event("jump", _arg, socket) do
    player_number = socket.assigns.player_number
    GameServer.jump(player_number)
    {:noreply, socket}
  end

  def handle_event("join_game", %{"join" => %{"name" => name}}, socket) do
    ## Game server finder stuff would go here.. For now let's just make a GenServer
    GameServer.start_link("Hello World")

    GameServer.join(name)

    game_state = GameServer.state()

    :timer.send_interval(20, self(), :update)

    {:noreply, assign(socket, player_number: game_state.player_count, game_state: game_state)}
  end
end

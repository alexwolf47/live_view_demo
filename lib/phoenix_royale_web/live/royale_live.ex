defmodule PhoenixRoyaleWeb.RoyaleLive do
  use Phoenix.LiveView
  alias PhoenixRoyale.{GameServer, GameCoordinator, GameInstance}

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

      %{server_status: :game_over} ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "dead.html", assigns)

      %{dead: true} ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "dead.html", assigns)
    end
  end

  def mount(_session, socket) do
    {:ok, assign(socket, game_state: nil, player_number: nil, dev: false)}
  end

  def handle_info(:update, socket) do
    # IO.inspect(socket, label: "update socket")
    new_game_state = GameInstance.state(socket.assigns.game_uuid)

    player = Map.get(new_game_state.players, socket.assigns.player_number)

    if player.alive || socket.assigns.game_state.server_status != :game_over do
      :timer.send_after(33, self(), :update)
      {:noreply, assign(socket, game_state: new_game_state)}
    else
      {:noreply, assign(socket, game_state: Map.put(new_game_state, :dead, true))}
    end
  end

  def handle_event("jump", _arg, socket) do
    player_number = socket.assigns.player_number
    GameInstance.jump(player_number, socket.assigns.game_uuid)
    {:noreply, socket}
  end

  def handle_event("join_game", %{"join" => %{"name" => name}}, socket) do
    ## Game server finder stuff would go here.. For now let's just make a GenServer

    {serverod, gameid} = GameCoordinator.find_game(name)
    # IO.inspect(game, label: "p1 game id")

    :timer.sleep(10)
    game_state = GameInstance.state(gameid)
    # IO.inspect(game_state)

    :timer.send_after(25, self(), :update)

    {:noreply,
     assign(socket,
       player_number: game_state.player_count,
       game_state: game_state,
       game_uuid: gameid
     )}
  end
end

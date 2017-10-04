defmodule GossipSimulator.Node do
    use GenServer

    ## Client API

    @doc """
    Starts the node.
    """
    def start_link() do
        GenServer.start_link(__MODULE__, :ok, [])
    end

    ## Server Callbacks
    def init(:ok) do
        {:ok, %{"self_pid" => nil, "neighbors" => []}}
    end

    def send_msg(self_pid, msg) do
        GenServer.cast(self_pid, {:init_send, msg})
    end

    def handle_call() do
        
    end

    def handle_cast({:set_neighbor, neighbor_list}, state) do
        Map.update!(state, "neighbors", &(neighbor_list ++ &1))
        {:noreply, state}
    end

    def handle_cast({:send, msg}, state) do
        neighbor_list = Map.get(state, "neighbors")
        random_number = :rand.uniform(length(neighbor_list))
        target_pid = Enum.at(neighbor_list, random_number-1)
        GenServer.cast(target_pid, {:receive, msg})
    end

    def handl_cast({:receive, msg}, state) do
        send_msg(Map.get(state, "self_pid"), "asd")
    end

end
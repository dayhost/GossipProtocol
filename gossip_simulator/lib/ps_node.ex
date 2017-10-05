defmodule GossipSimulator.PSNode do
    use GenServer, restart: :transient


    @doc """
    Starts the node.
    """
    def start_link() do
        GenServer.start_link(__MODULE__, :ok, [])
    end

    def send_msg(self_pid, msg) do
        GenServer.cast(self_pid, {:send, msg})
    end
    ## Client API
    def set_neighbor(pid, self_pid, pidList) do
        GenServer.cast(pid, {:set_neighbor, self_pid, pidList})
    end

    ## Server Callbacks
    def init(:ok) do
        {:ok, %{"self_pid" => nil, "neighbors" => []}}
    end

    def handle_call() do
        
    end

    def handle_cast({:set_neighbor, self_pid, neighbor_list}, state) do
        new_state = Map.update!(state, "neighbors", &(neighbor_list ++ &1))
        new_state = Map.update!(new_state, "self_pid", &(&1=self_pid))
        {:noreply, new_state}
    end

    def handle_cast({:send, msg}, state) do
        neighbor_list = Map.get(state, "neighbors")
        #IO.puts "#{Kernel.inspect(state["neighbors"])}"
        random_number = :rand.uniform(length(neighbor_list))
        target_pid = Enum.at(neighbor_list, random_number-1)
        IO.puts "#{Kernel.inspect(state["self_pid"])} sends #{msg} to #{Kernel.inspect(target_pid)}."
        GenServer.cast(target_pid, {:receive, msg})    
        {:noreply, state}
    end

    def handle_cast({:receive, msg}, state) do
        IO.puts "#{Kernel.inspect(state["self_pid"])} receives #{msg}."
        # :timer.sleep(300)
        GenServer.cast(Map.get(state, "self_pid"), {:send, msg})
        {:noreply, state}
    end

end
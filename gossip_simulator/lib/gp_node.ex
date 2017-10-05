defmodule GossipSimulator.GPNode do
    use GenServer, restart: :transient


    @doc """
    Starts the node.
    """
    def start_link(node_id) do
        GenServer.start_link(__MODULE__, [:ok, node_id], [])
    end

    def send_msg(self_pid, msg) do
        GenServer.cast(self_pid, {:send, msg})
    end
    ## Client API
    def set_neighbor(pid, pidList) do
        GenServer.cast(pid, {:set_neighbor, pidList})
    end

    ## Server Callbacks
    def init([:ok, node_id]) do
        {:ok, %{"s" => node_id, "neighbors" => [], "counter" => 0}}
    end

    def terminate(reason, state) do
        IO.puts "#{inspect self()} stops because #{inspect reason}."
        :ok 
    end

    def handle_call() do
        
    end

    def handle_cast({:set_neighbor, neighbor_list}, state) do
        new_state = Map.update!(state, "neighbors", &(neighbor_list ++ &1))
        {:noreply, new_state}
    end

    def handle_cast({:send, msg}, state) do
        neighbor_list = Map.get(state, "neighbors")
        #IO.puts "#{Kernel.inspect(state["neighbors"])}"
        random_number = :rand.uniform(length(neighbor_list))
        target_pid = Enum.at(neighbor_list, random_number-1)
        IO.puts "#{inspect(self())} sends #{msg} to #{inspect(target_pid)}."
        GenServer.cast(target_pid, {:receive, msg})   
        :timer.sleep(1000)   
        {:noreply, state}
    end

    def handle_cast({:receive, msg}, state) do
        IO.puts "#{inspect(self())} receives #{msg}."
        # :timer.sleep(300)
        new_state = Map.update!(state, "counter", &(&1+1))
        if is_converge(new_state["counter"]) do
            GenServer.cast(self(), {:stop})
        else
            GenServer.cast(self(), {:send, msg})
        end     
        {:noreply, new_state}
    end

    def is_converge(counter) do
        counter == 5
    end

    def handle_cast({:stop}, state) do
        {:stop, :normal, state}
    end
end
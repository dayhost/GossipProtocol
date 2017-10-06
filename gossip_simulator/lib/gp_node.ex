defmodule GossipSimulator.GPNode do
    use GenServer, restart: :transient


    @doc """
    Starts the node.
    """
    def start_link(node_id) do
        GenServer.start_link(__MODULE__, [:ok, node_id], [])
    end

    def send_msg(self_pid, msg) do
        GenServer.cast(self_pid, {:receive, msg})
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
        IO.puts "======="
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
        if is_converge(state["counter"]) do
            GenServer.cast(self(), {:stop})
        end
        neighbor_list = Map.get(state, "neighbors")
        if length(neighbor_list) != 0 do
            #IO.puts "#{Kernel.inspect(state["neighbors"])}"
            random_number = :rand.uniform(length(neighbor_list))
            target_pid = Enum.at(neighbor_list, random_number-1)
            IO.puts "#{inspect(self())} sends #{msg} to #{inspect(target_pid)}, counter: #{inspect(state["counter"])}."
            GenServer.cast(target_pid, {:receive, msg})   
            # :timer.sleep(2000) 
            GenServer.cast(self(), {:send, msg})  
        else
            GenServer.cast(self(), {:stop})
        end
        {:noreply, state}
    end

    def handle_cast({:receive, msg}, state) do
        IO.puts "#{inspect(self())} receives #{msg}."
        new_state = Map.update!(state, "counter", &(&1+1))
        IO.puts "#{inspect(self())} current counter is #{inspect(new_state["counter"])}"
        if is_converge(new_state["counter"]) do
            # The node is converge, stop sending process and the genserver. 
            GenServer.cast(self(), {:stop})
        end    
        if new_state["counter"] == 1 do
           # First time receive, then send msg continuously
           GenServer.cast(self(), {:send, msg}) 
        end    
        {:noreply, new_state}
    end

    def handle_cast({:send_stop, stopped_pid}, state) do
        new_state = Map.update!(state, "neighbors", &(List.delete(&1, stopped_pid)))
        # If the node is isolated, stop it
        if is_isolate(new_state["neighbors"]) do
            GenServer.cast(self(), {:stop})
        end
        {:noreply, new_state}
    end

    def is_converge(counter) do
        counter >= 10
    end

    def is_isolate(neighbor_list) do
        length(neighbor_list) == 0
    end

    def handle_cast({:stop}, state) do
        neighbors = state["neighbors"]
        Enum.map(neighbors, fn(x) -> GenServer.cast(x, {:send_stop, self()}) end)
        {:stop, :normal, state}
        # {:stop, :shutdown, state}
    end
end
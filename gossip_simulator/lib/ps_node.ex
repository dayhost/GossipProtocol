defmodule GossipSimulator.PSNode do
    use GenServer, restart: :transient


    @doc """
    Starts the node.
    """
    def start_link(node_id) do
        GenServer.start_link(__MODULE__, [:ok, node_id], [])
    end

    def send_msg(self_pid) do
        GenServer.cast(self_pid, {:send})
    end
    ## Client API
    def set_neighbor(pid, pidList) do
        GenServer.cast(pid, {:set_neighbor, pidList})
    end

    ## Server Callbacks
    def init([:ok, node_id]) do
        {:ok, %{"s" => node_id, "w" => 1, "neighbors" => [], "ratios" => [-3, -2, -1], "start_send" => false}}
    end

    def terminate(reason, state) do
        # IO.puts "======="
        # IO.puts "#{inspect self()} stops because #{inspect reason}."
        :ok 
    end

    def handle_cast({:set_neighbor, neighbor_list}, state) do
        new_state = Map.update!(state, "neighbors", &(neighbor_list ++ &1))
        {:noreply, new_state}
    end

    def handle_cast({:send}, state) do
        if !is_nil(state) do
            if is_converge(state["ratios"]) do
                GenServer.cast(self(), {:stop})
            end
    
            neighbor_list = Map.get(state, "neighbors")
            if length(neighbor_list) != 0 do
                # Random pick one neighbor from its neightbor list
                neighbor_list = Map.get(state, "neighbors")
                # IO.puts "#{inspect state}"
                random_number = :rand.uniform(length(neighbor_list))
                target_pid = Enum.at(neighbor_list, random_number-1)
                if Process.alive?(target_pid) do
                    s = adjust_precision(state["s"])
                    w = adjust_precision(state["w"])
                    msg = {Float.round(s/2, 15), Float.round(w/2, 15)}
                    state = Map.update!(state, "s", &(&1=Float.round(s/2, 15)))
                    state = Map.update!(state, "w", &(&1=Float.round(w/2, 15)))
                    state = Map.update!(state, "start_send", &(&1=true)) 
                    # IO.puts "#{inspect(self())} sends #{inspect(msg)} to #{inspect(target_pid)}."
                    # :timer.sleep(1000) 
                    GenServer.cast(target_pid, {:receive, msg}) 
                else
                    state = Map.update!(state, "neighbors", &(List.delete(&1, target_pid)))
                end
                GenServer.cast(self(), {:send})
            else
                GenServer.cast(self(), {:stop})
            end 
        end
        {:noreply, state}
    end

    def handle_cast({:send_stop, stopped_pid}, state) do
        if !is_nil(state) do
            new_state = Map.update!(state, "neighbors", &(List.delete(&1, stopped_pid)))
            # If the node is isolated, stop it
            if is_isolate(new_state["neighbors"]) do
                GenServer.cast(self(), {:stop})
            end
            {:noreply, new_state}
        else
            GenServer.cast(self(), {:stop})
        end
    end

    def handle_cast({:receive, msg}, state) do
        # After receiving, update self state, then call the send callback. 
        if !is_nil(state) do
            # IO.puts "#{inspect(self())} receives #{inspect(msg)}."
            {rcv_s, rcv_w} = msg
            new_state = Map.update!(state, "s", &(&1 + rcv_s))
            new_state = Map.update!(new_state, "w", &(&1 + rcv_w))
            
            # update ratio list
            new_ratio = new_state["s"] / new_state["w"]
            {previous_ratio, new_ratio_list} = List.pop_at([new_ratio | new_state["ratios"]], -1)
            new_state = Map.update!(new_state, "ratios", &(&1=new_ratio_list))
            
            # check whether converge, if so, send  terminate, otherwise continue loop.
            if is_converge(new_ratio_list) do
                GenServer.cast(self(), {:stop})
            end
    
            # check whether it is first received, if so start the send loop, otherwise ignore.
            # IO.puts "#{inspect(self())} starts to send? #{inspect state["start_send"]}"
            if !state["start_send"] do
                GenServer.cast(self(), {:send})
            end 
            {:noreply, new_state}
        else
            GenServer.cast(self(), {:stop})
        end
        # :timer.sleep(1000)
    end

    defp is_converge(ratio_list) do
        [first_r, second_r, third_r] = ratio_list
        diff_1 = abs(second_r - first_r)
        diff_2 = abs(third_r - second_r)
        thread_hold = :math.pow(10, -10)
        # IO.puts "converge? #{inspect diff_1 <= thread_hold and diff_2 <= thread_hold}"
        diff_1 <= thread_hold and diff_2 <= thread_hold
    end

    def is_isolate(neighbor_list) do
        length(neighbor_list) == 0
    end

    def handle_cast({:stop}, state) do
        if !is_nil(state) do
            neighbors = state["neighbors"]
            if length(neighbors) != 0 do
                Enum.map(neighbors, fn(x) -> GenServer.cast(x, {:send_stop, self()}) end)
            end       
        end       
        {:stop, :normal, state}
    end

    def adjust_precision(input) do
        if input <= :math.pow(10, -10) do
            Float.round(:math.pow(10, -9), 15)
        end
        input
    end
end
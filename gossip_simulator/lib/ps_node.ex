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
        IO.puts "======="
        IO.puts "#{inspect self()} stops because #{inspect reason}."
        :ok 
    end

    def handle_cast({:set_neighbor, neighbor_list}, state) do
        new_state = Map.update!(state, "neighbors", &(neighbor_list ++ &1))
        {:noreply, new_state}
    end

    def handle_cast({:send}, state) do
        if is_converge(state["ratios"]) do
            GenServer.cast(self(), {:stop})
        end

        neighbor_list = Map.get(state, "neighbors")
        if length(neighbor_list) != 0 do
            # Random pick one neighbor from its neightbor list
            neighbor_list = Map.get(state, "neighbors")
            IO.puts "#{inspect state}"
            random_number = :rand.uniform(length(neighbor_list))
            target_pid = Enum.at(neighbor_list, random_number-1)
            s = state["s"]
            w = state["w"]
            msg = {s/2, w/2}
            new_state = Map.update!(state, "s", &(&1=s/2))
            new_state = Map.update!(new_state, "w", &(&1=w/2))
            new_state = Map.update!(new_state, "start_send", &(&1=true)) 
            IO.puts "#{inspect(self())} sends #{inspect(msg)} to #{inspect(target_pid)}."
            # :timer.sleep(1000) 
            GenServer.cast(target_pid, {:receive, msg}) 
            GenServer.cast(self(), {:send})
        else
            GenServer.cast(self(), {:stop})
        end
 
        {:noreply, new_state}
    end

    def handle_cast({:receive, msg}, state) do
        # After receiving, update self state, then call the send callback. 
        IO.puts "#{inspect(self())} receives #{inspect(msg)}."
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
        IO.puts "#{inspect(self())} starts to send? #{inspect state["start_send"]}"
        if !state["start_send"] do
            GenServer.cast(self(), {:send})
        end
        # :timer.sleep(1000) 
        {:noreply, new_state}
    end

    defp is_converge(ratio_list) do
        [first_r, second_r, third_r] = ratio_list
        diff_1 = abs(second_r - first_r)
        diff_2 = abs(third_r - second_r)
        thread_hold = :math.pow(10, -10)
        IO.puts "converge? #{inspect diff_1 <= thread_hold and diff_2 <= thread_hold}"
        diff_1 <= thread_hold and diff_2 <= thread_hold
    end

    def handle_cast({:stop}, state) do
        {:stop, :normal, state}
    end
end
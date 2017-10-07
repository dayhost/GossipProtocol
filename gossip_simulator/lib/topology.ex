defmodule GossipSimulator.Topology do
    # client API interface
    def get_topology_line(pidList) do
        get_neighbor_in_line(pidList, 0, %{})
    end
    def get_topology_all(pidList) do
        get_neighbor_for_all(pidList, 0, %{})
    end

    def get_topology_2d(pidList) do
        row = round(:math.sqrt(length(pidList)))
        # IO.puts "the row for 2d is #{row}"
        get_neighbor_for_2d(pidList, 0, %{}, row)
    end

    def get_topology_inp_2d(pidList) do
        result = get_topology_2d(pidList)
        keys = Map.keys(result)
        put_random_neighbor_into_map(result, pidList, keys, 0)
    end

    defp get_neighbor_in_line(pidList, index, result) do
        case (index==(length(pidList))) do
            true->
                result
            false->
                {pid, neighbor} = put_line_neighbor_into_map(pidList, index)
                result = Map.put_new(result, pid, neighbor)
                get_neighbor_in_line(pidList, index+1, result)
        end
    end

    defp put_line_neighbor_into_map(pidList, index) do
        {self_pid, pidList} = List.pop_at(pidList, index)
        pidList = List.insert_at(pidList, index, self_pid)
        total_length = length(pidList)
        neighbor = 
            case (index==0||index==total_length-1) do
                true ->
                    case (index==0) do
                        true->
                            {after_neighbor, pidList} = List.pop_at(pidList, index+1)
                            pidList = List.insert_at(pidList, index+1, after_neighbor)
                            [after_neighbor]
                        false->
                            {before_neighbor, pidList} = List.pop_at(pidList, index-1)
                            pidList = List.insert_at(pidList, index-1, before_neighbor)
                            [before_neighbor]
                    end
                false ->
                    {after_neighbor, pidList} = List.pop_at(pidList, index+1)
                    pidList = List.insert_at(pidList, index+1, after_neighbor)
                    {before_neighbor, pidList} = List.pop_at(pidList, index-1)
                    pidList = List.insert_at(pidList, index-1, before_neighbor)
                    [before_neighbor, after_neighbor]
            end
        {self_pid, neighbor}
    end

    defp get_neighbor_for_all(pidList, index, result) do
        case (index==length(pidList)) do
            true ->
                result
            false ->
                {pid, neighbor} = put_all_neighbor_into_map(pidList, index)
                result = Map.put_new(result, pid, neighbor)
                get_neighbor_for_all(pidList, index+1, result)
        end
    end

    defp put_all_neighbor_into_map(pidList, index) do
        {self_pid, neighbor} = List.pop_at(pidList, index)
    end

    defp get_neighbor_for_2d(pidList, index, result, row) do
        total_length = length(pidList)
        case (index==total_length) do
            true ->
                result
            false ->
                {pid, neighbor} = put_2d_neighbor_into_map(pidList, index, row)
                result = Map.put_new(result, pid, neighbor)
                #IO.puts "result is #{Kernel.inspect(result)}"
                get_neighbor_for_2d(pidList, index+1, result, row)
        end
    end

    defp put_2d_neighbor_into_map(pidList, index, row) do
        {self_pid, pidList} = List.pop_at(pidList, index)
        pidList = List.insert_at(pidList, index, self_pid)
        row_index = :math.fmod(index, row)
        column_index = (index-row_index)/row
        total_length = length(pidList)
        total_column = 
            case total_length/row > round(total_length/row) do
                true->
                    round(total_length/row)+1
                false->
                    round(total_length/row)
            end
        #IO.puts "total column is #{total_column}"
        #IO.puts "self pid is #{self_pid} and row is #{row_index} and columns is #{column_index}"
        neighbor = 
            case (row_index-1>=0||(row_index+1<row && index+1<total_length)||column_index-1>=0||(column_index+1<total_column && index+row<total_length)) do
                true ->
                    neighbor = 
                        case row_index-1>=0 do
                            true -> 
                                {left, pidList} = List.pop_at(pidList, index-1)
                                pidList = List.insert_at(pidList, index-1, left)
                                neighbor = List.insert_at([], -1, left)
                            false ->
                                []
                        end
                    neighbor = 
                        case (row_index+1<row && index+1<total_length) do
                            true -> 
                                {right, pidList} = List.pop_at(pidList, index+1)
                                pidList = List.insert_at(pidList, index+1, right)
                                neighbor = List.insert_at(neighbor, -1, right)
                            false ->
                                neighbor
                        end
                    neighbor = 
                        case column_index-1>=0 do
                            true -> 
                                {up, pidList} = List.pop_at(pidList, index-row)
                                pidList = List.insert_at(pidList, index-row, up)
                                neighbor = List.insert_at(neighbor, -1, up)
                            false ->
                                neighbor
                        end
                    neighbor = 
                        case (column_index+1<total_column && index+row<total_length) do
                            true -> 
                                {down, pidList} = List.pop_at(pidList, index+row)
                                pidList = List.insert_at(pidList, index+row, down)
                                neighbor = List.insert_at(neighbor, -1, down)
                            false ->
                                neighbor
                        end
                false ->
                    []
            end
        {self_pid, neighbor}
    end


    defp put_random_neighbor_into_map(result, pidList, keys, index) do
        case index==length(pidList) do
            true ->
                result
            false->
                {key, keys} = List.pop_at(keys, index)
                keys = List.insert_at(keys, index, key)
                {neighbors, result} = Map.pop(result, key)
                #IO.puts Kernel.inspect({neighbors, result})
                neighbors = get_random_neighbor(neighbors, pidList, index)
                result = Map.put_new(result, key, neighbors)
                put_random_neighbor_into_map(result, pidList, keys, index+1)
        end
    end

    defp get_random_neighbor(neighbors, pidList, index) do
        row = round(:math.sqrt(length(pidList)))
        row_index = :math.fmod(index, row)
        column_index = (index-row_index)/row
        total_length = length(pidList)
        total_column = 
            case total_length/row > round(total_length/row) do
                true->
                    round(total_length/row)+1
                false->
                    round(total_length/row)
            end 
        neighbors_num = length(neighbors)
        case length(neighbors) == neighbors_num do
            true ->
                case (index-row-1>=0&&row_index>0&&column_index>0) do
                    true->
                        {node, pidList} = List.pop_at(pidList, index-row-1)
                        pidList = List.insert_at(pidList, index-row-1, node)
                        neighbors = List.insert_at(neighbors, -1, node)
                    false->
                        neighbors
                end
            false ->
                neighbors
        end 
        case length(neighbors) == neighbors_num do
            true ->
                case (index-row+1>=0&&row_index<row-1&&column_index>0) do
                    true->
                        {node, pidList} = List.pop_at(pidList, index-row+1)
                        pidList = List.insert_at(pidList, index-row+1, node)
                        neighbors = List.insert_at(neighbors, -1, node)
                    false->
                        neighbors
                end
            false ->
                neighbors
        end 
        case length(neighbors) == neighbors_num do
            true ->
                case (index+row-1<total_length&&row_index>0&&column_index<total_column-1) do
                    true->
                        {node, pidList} = List.pop_at(pidList, index+row-1)
                        pidList = List.insert_at(pidList, index+row-1, node)
                        neighbors = List.insert_at(neighbors, -1, node)
                    false->
                        neighbors
                end
            false ->
                neighbors
        end 
        case length(neighbors) == neighbors_num do
            true ->
                case (index+row+1<total_length&&row_index<row-1&&column_index<total_column-1) do
                    true->
                        {node, pidList} = List.pop_at(pidList, index+row+1)
                        pidList = List.insert_at(pidList, index+row+1, node)
                        neighbors = List.insert_at(neighbors, -1, node)
                    false->
                        neighbors
                end
            false ->
                neighbors
        end 
    end
end
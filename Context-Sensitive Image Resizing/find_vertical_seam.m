function verticalSeam = find_vertical_seam(cumulativeEnergyMap)
    % Init return array to be full of zeros and proper size
    verticalSeam = zeros(1, size(cumulativeEnergyMap,1));
    
    % Loop over all columns
        for r = size(cumulativeEnergyMap,1):-1:1 
            
            % Find last pixel from which to begin traceback
            if r == size(cumulativeEnergyMap,1)
                [~,verticalSeam(r)] = min(cumulativeEnergyMap(r,:));
                
            % Find current pixel by seeing which one led to next
            else
                % Next pixel is in first row
                if verticalSeam(r + 1) == 1
                    first = 1;
                    last = first + 1;
                    
                    [~,i] = min(cumulativeEnergyMap(r,first:last));
                    i = i - 1;
                    
                % Next pixel is in last row
                elseif verticalSeam(r + 1) == size(cumulativeEnergyMap,2)
                    first = size(cumulativeEnergyMap,2) - 1;
                    last = first + 1;
                    
                    [~,i] = min(cumulativeEnergyMap(r,first:last));
                    i = i - 2;
                
                % Next pixel is in middle of img
                else
                    first = verticalSeam(r + 1) - 1;
                    last = first + 2;
                    
                    [~,i] = min(cumulativeEnergyMap(r,first:last));
                    i = i - 2;
                end
                
                verticalSeam(r) = verticalSeam(r + 1) + i;
            end
        end
end
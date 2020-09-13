function horizontalSeam = find_horizontal_seam(cumulativeEnergyMap)
    % Init return array to be full of zeros and proper size
    horizontalSeam = zeros(1, size(cumulativeEnergyMap,2));
    
    % Loop over all columns
        for c = size(cumulativeEnergyMap,2):-1:1 
            
            % Find last pixel from which to begin traceback
            if c == size(cumulativeEnergyMap,2)
                [~,horizontalSeam(c)] = min(cumulativeEnergyMap(:,c));
                
            % Find current pixel by seeing which one led to next
            else
                % Next pixel is in first row
                if horizontalSeam(c + 1) == 1
                    first = 1;
                    last = first + 1;
                    
                    [~,i] = min(cumulativeEnergyMap(first:last,c));
                    i = i - 1;
                    
                % Next pixel is in last row
                elseif horizontalSeam(c + 1) == size(cumulativeEnergyMap,1)
                    first = size(cumulativeEnergyMap,1) - 1;
                    last = first + 1;
                    
                    [~,i] = min(cumulativeEnergyMap(first:last,c));
                    i = i - 2;
                
                % Next pixel is in middle of img
                else
                    first = horizontalSeam(c + 1) - 1;
                    last = first + 2;
                    
                    [~,i] = min(cumulativeEnergyMap(first:last,c));
                    i = i - 2;
                end
                
                horizontalSeam(c) = horizontalSeam(c + 1) + i;
            end
        end
end
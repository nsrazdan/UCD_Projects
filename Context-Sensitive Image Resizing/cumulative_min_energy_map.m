function cumulativeEnergyMap = cumulative_min_energy_map(energyImg,seamDirection)
    cumulativeEnergyMap = zeros(size(energyImg));
    
    % Create horizontal cumulative energy map
    if seamDirection == "HORIZONTAL"
        % loop over all pixels
        for c = 1:size(energyImg,2)
            for r = 1:size(energyImg,1) 
                  if c == 1
                      cumulativeEnergyMap(r,c) = energyImg(r,c);
                  elseif r == 1
                      min_pixel = min([cumulativeEnergyMap(r, c - 1), cumulativeEnergyMap(r + 1, c - 1)]);
                      cumulativeEnergyMap(r,c) = min_pixel + energyImg(r,c);
                  elseif r == size(energyImg,1)
                      min_pixel = min([cumulativeEnergyMap(r - 1, c - 1),cumulativeEnergyMap(r, c - 1)]);
                      cumulativeEnergyMap(r,c) = min_pixel + energyImg(r,c);
                  else
                      min_pixel = min([cumulativeEnergyMap(r - 1, c - 1), cumulativeEnergyMap(r, c - 1), cumulativeEnergyMap(r + 1, c - 1)]);
                      cumulativeEnergyMap(r,c) = min_pixel + energyImg(r,c);
                  end 
            end
        end
    
    % Create vertical cumulative energy map
    elseif seamDirection == "VERTICAL"
        % loop over all pixels
        for r = 1:size(energyImg,1)
            for c = 1:size(energyImg,2) 
                  if r == 1
                      cumulativeEnergyMap(r,c) = energyImg(r,c);
                  elseif c == 1
                      min_pixel = min([cumulativeEnergyMap(r - 1, c), cumulativeEnergyMap(r - 1, c + 1)]);
                      cumulativeEnergyMap(r,c) = min_pixel + energyImg(r,c);
                  elseif c == size(energyImg,2)
                      min_pixel = min([cumulativeEnergyMap(r - 1, c),cumulativeEnergyMap(r - 1, c - 1)]);
                      cumulativeEnergyMap(r,c) = min_pixel + energyImg(r,c);
                  else
                      min_pixel = min([cumulativeEnergyMap(r - 1, c - 1), cumulativeEnergyMap(r - 1, c), cumulativeEnergyMap(r - 1, c + 1)]);
                      cumulativeEnergyMap(r,c) = min_pixel + energyImg(r,c);
                  end 
            end
        end
        
    % Display error, as invalid direction given
    else
        disp("ERROR: Invalid seamDirection given in cumulative_min_energy_map");
    end
end

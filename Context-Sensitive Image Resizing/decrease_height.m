function [reducedColorImg,reducedEnergyImg] = decrease_height(im, energyImg)
    % Create cumulative energy map and find horizontal seam
    im = im2double(im);
    cumulativeEnergyMap = cumulative_min_energy_map(energyImg, "HORIZONTAL");
    horizontalSeam = find_horizontal_seam(cumulativeEnergyMap);
    
    % Set output images to correct sizes
    reducedColorImg = zeros(size(im, 1) - 1, size(im, 2), size(im,3));
    reducedEnergyImg = zeros(size(energyImg, 1) - 1, size(energyImg, 2));
    
    % Set output images to same as input images, but without the pixels at
    % the horizontal seam, effectively removing those pixels
    for c = 1:size(im,2)
        for r = 1:size(im,1)
            if r < horizontalSeam(c)
                reducedColorImg(r,c,:) = im(r,c,:);
                reducedEnergyImg(r,c) = energyImg(r,c);
            elseif r > horizontalSeam(c)
                reducedColorImg(r - 1,c,:) = im(r,c,:);
                reducedEnergyImg(r - 1,c) = energyImg(r,c);
            end
        end
    end
    
    % Set output image to correct type
    reducedColorImg = im2uint8(reducedColorImg);
end
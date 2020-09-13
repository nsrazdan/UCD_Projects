function [reducedColorImg,reducedEnergyImg] = decrease_width(im, energyImg)
    % Create cumulative energy map and find vertical seam
    im = im2double(im);
    cumulativeEnergyMap = cumulative_min_energy_map(energyImg, "VERTICAL");
    verticalSeam = find_vertical_seam(cumulativeEnergyMap);
    
    % Set output images to correct sizes
    reducedColorImg = zeros(size(im, 1), size(im, 2) - 1, size(im,3));
    reducedEnergyImg = zeros(size(energyImg, 1), size(energyImg, 2) - 1);
    
    % Set output images to same as input images, but without the pixels at
    % the vertical seam, effectively removing those pixels
    for r = 1:size(im,1)
        for c = 1:size(im,2)
            if c < verticalSeam(r)
                reducedColorImg(r,c,:) = im(r,c,:);
                reducedEnergyImg(r,c) = energyImg(r,c);
            elseif c > verticalSeam(r)
                reducedColorImg(r,c - 1,:) = im(r,c,:);
                reducedEnergyImg(r,c - 1) = energyImg(r,c);
            end
        end
    end
    
    % Set output image to correct type
    reducedColorImg = im2uint8(reducedColorImg);
end
function ps1_q5()   
    % Read in image and get energy maps
    pragueImg = imread("inputSeamCarvingPrague.jpg");
    pragueEnergyImg = energy_im(pragueImg);
    horizontalEnergyImg = cumulative_min_energy_map(pragueEnergyImg, "HORIZONTAL");
    verticalEnergyImg = cumulative_min_energy_map(pragueEnergyImg, "VERTICAL");
    
    % Get seams
    verticalSeam = find_vertical_seam(verticalEnergyImg);
    horizontalSeam = find_horizontal_seam(horizontalEnergyImg);
    
    % View seams
    view_seam(pragueImg,horizontalSeam,"HORIZONTAL");
    view_seam(pragueImg,verticalSeam,"VERTICAL");
end
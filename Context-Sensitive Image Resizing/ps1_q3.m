function ps1_q3()
    % Read in image and get energy maps
    pragueImg = imread("inputSeamCarvingPrague.jpg");
    pragueEnergyImg = energy_im(pragueImg);
    horizontalEnergyImg = cumulative_min_energy_map(pragueEnergyImg, "HORIZONTAL");
    verticalEnergyImg = cumulative_min_energy_map(pragueEnergyImg, "VERTICAL");
    
    % save output images
    imwrite(pragueEnergyImg, "PS1_Q3_1.png");
    imwrite(ind2rgb(im2uint8(mat2gray(horizontalEnergyImg)), parula(256)), "PS1_Q3_2.png");
    imwrite(ind2rgb(im2uint8(mat2gray(verticalEnergyImg)), parula(256)), "PS1_Q3_3.png");
end
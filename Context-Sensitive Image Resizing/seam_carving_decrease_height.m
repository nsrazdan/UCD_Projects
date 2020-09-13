function seam_carving_decrease_height()
    % Read in images and get energy images
    pragueImg = imread("inputSeamCarvingPrague.jpg");
    mallImg = imread("inputSeamCarvingMall.jpg");
    pragueEnergyImg = energy_im(pragueImg);
    mallEnergyImg = energy_im(mallImg);
    
    % Decrease height by 50 pixels using seam carving
    for i = 1:50
        disp("Decreasing height #" + i);
        if i == 1
            [pragueReducedColorImg,pragueReducedEnergyImg] = decrease_height(pragueImg, pragueEnergyImg);
            [mallReducedColorImg,mallReducedEnergyImg] = decrease_height(mallImg, mallEnergyImg);
        else
            [pragueReducedColorImg,pragueReducedEnergyImg] = decrease_height(pragueReducedColorImg, pragueReducedEnergyImg);
            [mallReducedColorImg,mallReducedEnergyImg] = decrease_height(mallReducedColorImg, mallReducedEnergyImg);
        end
    end
    
    % Display original images and new images and save
    subplot(2, 2, 1);
    imshow(pragueImg);
    title("a) Prague Original");
    
    subplot(2, 2, 2);
    imshow(pragueReducedColorImg);
    title("b) Prague Reduced Height by 50 Pixels");
    
    subplot(2, 2, 3);
    imshow(mallImg);
    title("c) Mall Original");
    
    imgs = subplot(2, 2, 4);
    imshow(mallReducedColorImg);
    title("d) Mall Reduced Height by 50 Pixels");
    
    saveas(imgs, "PS1_Q2.png");
    imwrite(pragueReducedColorImg, "outputReduceHeightPrague.png");
    imwrite(mallReducedColorImg, "outputReduceHeightMall.png");
end
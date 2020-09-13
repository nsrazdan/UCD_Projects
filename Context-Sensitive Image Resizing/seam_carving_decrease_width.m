function seam_carving_decrease_width()
    % Read in images and get energy images
    pragueImg = imread("inputSeamCarvingPrague.jpg");
    mallImg = imread("inputSeamCarvingMall.jpg");
    pragueEnergyImg = energy_im(pragueImg);
    mallEnergyImg = energy_im(mallImg);
    
    % Decrease width by 100 pixels using seam carving
    for i = 1:100
        disp("Decreasing width #" + i);
        if i == 1
            [pragueReducedColorImg,pragueReducedEnergyImg] = decrease_width(pragueImg, pragueEnergyImg);
            [mallReducedColorImg,mallReducedEnergyImg] = decrease_width(mallImg, mallEnergyImg);
        else
            [pragueReducedColorImg,pragueReducedEnergyImg] = decrease_width(pragueReducedColorImg, pragueReducedEnergyImg);
            [mallReducedColorImg,mallReducedEnergyImg] = decrease_width(mallReducedColorImg, mallReducedEnergyImg);
        end
    end
    
    % Display original images and new images and save
    subplot(2, 2, 1);
    imshow(pragueImg);
    title("a) Prague Original");
    
    subplot(2, 2, 2);
    imshow(pragueReducedColorImg);
    title("b) Prague Reduced Width by 100 Pixels");
    
    subplot(2, 2, 3);
    imshow(mallImg);
    title("c) Mall Original");
    
    imgs = subplot(2, 2, 4);
    imshow(mallReducedColorImg);
    title("d) Mall Reduced Width by 100 Pixels");
    
    saveas(imgs, "PS1_Q1.png");
    imwrite(pragueReducedColorImg, "outputReduceWidthPrague.png");
    imwrite(mallReducedColorImg, "outputReduceWidthMall.png");
end
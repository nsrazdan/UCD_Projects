function energyImg = energy_im(im)
    img = rgb2gray(im);
    dxMask = [1 -1];
    dyMask = [1; -1];
    dxEnergyImg = imfilter(img, dxMask);
    dyEnergyImg = imfilter(img, dyMask);
    energyImg = dxEnergyImg + dyEnergyImg;
    energyImg = im2double(energyImg);
end
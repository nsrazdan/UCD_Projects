function ps1_q6()
    % Read in images and get energy images
    testImg1 = imread("test_1.jpg");
    testImg2 = imread("test_2.jpg");
    testImg3 = imread("test_3.jpg");
    test1EnergyImg = energy_im(testImg1);
    test2EnergyImg = energy_im(testImg2);
    test3EnergyImg = energy_im(testImg3);
    
    %testImg1 Resizing
    for i = 1:20
        disp("Test 1" + " #" + i);
        if i == 1
            [test1SeamCarvingResize,test1ReducedEnergyImg] = decrease_width(testImg1, test1EnergyImg);
        else
            [test1SeamCarvingResize,test1ReducedEnergyImg] = decrease_width(test1SeamCarvingResize, test1ReducedEnergyImg);
        end
    end
    for i = 1:40
        disp("Test 1" + " #" + i)
        [test1SeamCarvingResize,test1ReducedEnergyImg] = decrease_height(test1SeamCarvingResize, test1ReducedEnergyImg);
    end
    test1BasicResize = imresize(testImg1, [size(testImg1,1), size(testImg1,2) - 20]);
    
    
    %testImg2 Resizing
    for i = 1:60
        disp("Test 2" + " #" + i);
        if i == 1
            [test2SeamCarvingResize,test2ReducedEnergyImg] = decrease_width(testImg2, test2EnergyImg);
        else
            [test2SeamCarvingResize,test2ReducedEnergyImg] = decrease_width(test2SeamCarvingResize, test2ReducedEnergyImg);
            [test2SeamCarvingResize,test2ReducedEnergyImg] = decrease_height(test2SeamCarvingResize, test2ReducedEnergyImg);
        end
    end
    test2BasicResize = imresize(testImg2, [size(testImg2,1) - 59, size(testImg2,2) - 60]);
    
    %testImg3 Resizing
    for i = 1:100
        disp("Test 3" + " #" + i);
        if i == 1
            [test3SeamCarvingResize,test3ReducedEnergyImg] = decrease_height(testImg3, test3EnergyImg);
        else
            [test3SeamCarvingResize,test3ReducedEnergyImg] = decrease_height(test3SeamCarvingResize, test3ReducedEnergyImg);
        end
    end
    test3BasicResize = imresize(testImg3, [size(testImg3,1) - 100, size(testImg3,2)]);
    
    % Display and save test1
    subplot(3, 1, 1);
    imshow(testImg1);
    title("a) Test 1 Original");
    subplot(3, 1, 2);
    imshow(test1SeamCarvingResize);
    title("b) Test 1 Seam Carving Resize");
    test1Output = subplot(3, 1, 3);
    imshow(test1BasicResize);
    title("c) Test 1 Basic Resize");
    saveas(test1Output, "PS1_Q6_1.png");
    
    % Display and save test1
    subplot(3, 1, 1);
    imshow(testImg2);
    title("a) Test 2 Original");
    subplot(3, 1, 2);
    imshow(test2SeamCarvingResize);
    title("b) Test 2 Seam Carving Resize");
    test2Output = subplot(3, 1, 3);
    imshow(test2BasicResize);
    title("c) Test 2 Basic Resize");
    saveas(test2Output, "PS1_Q6_2.png");
    
    % Display and save test1
    subplot(3, 1, 1);
    imshow(testImg3);
    title("a) Test 3 Original");
    subplot(3, 1, 2);
    imshow(test3SeamCarvingResize);
    title("b) Test 3 Seam Carving Resize");
    test3Output = subplot(3, 1, 3);
    imshow(test3BasicResize);
    title("c) Test 3 Basic Resize");
    saveas(test3Output, "PS1_Q6_3.png");
end
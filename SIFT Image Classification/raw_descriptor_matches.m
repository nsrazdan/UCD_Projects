function raw_descriptor_matches()
    % Load Matrix
    mat = load("twoFrameData.mat");
    
    % Get region to match SIFT features from user
    sift_im1 = selectRegion(mat.im1, mat.positions1);
    pause(10);
    
    % Calculate distance between all SIFT features in im1 and im2
    dist = dist2(mat.descriptors1, mat.descriptors2);
    
    % For all SIFT features found in region in im1,
    % find the SIFT feaure in im2 the minimum distance away
    sift_im2 = zeros(length(sift_im1), 1);
    for i = 1:length(sift_im1)
        dist_i = dist(sift_im1(i),:);
        [~, sift_im2(i)] = min(dist_i);
    end
    
    % Display all the SIFT features in im2 the mimimum distance away from
    % the features from im1
    imshow(mat.im2);
    displaySIFTPatches(mat.positions2(sift_im2,:), mat.scales2(sift_im2,:), mat.orients2(sift_im2,:), mat.im2);
end
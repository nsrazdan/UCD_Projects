function visualize_vocabulary()
    % Hyperparameters
    k = 1500;
    feature_sample_size = 25;
    image_sample_size = 6500;
    words_image_sample_size = 100;
    words_feature_sample_size = 1000;
    words_features_per_word = 25;
    
    % Uncomment the line below to create a new vocabulary
    % words = createVocabulary(k, feature_sample_size, image_sample_size);
    
    % Loading in vocabulary
    kmeans = load('kMeans.mat');
    words = kmeans.words;
    
    % Get words_image_sample_size number of random images from database
    [imgs, sifts] = getRandomImgsSifts(words_image_sample_size);

    % Get words_feature_sample_size features from each image in order
    features = zeros(128, (size(sifts, 2) * words_feature_sample_size));
    for i = 1:size(sifts,2)
        descriptors_i = sifts{i}.descriptors;
        descriptor_indices = randperm(sifts{i}.numfeats, min([words_feature_sample_size sifts{i}.numfeats]));
        for j = 1:size(descriptor_indices, 2)
            features_ij = descriptors_i(descriptor_indices(j),:);
            features(:, words_feature_sample_size * (i - 1) + j) = features_ij(:);
        end
    end
    features = features';
    
    % Get words from vocabulary
    word1 = words(1,:);
    word2 = words(2,:);
    
    % Find distance between word and all of our features
    dist_word1 = dist2(word1, features);
    dist_word2 = dist2(word2, features);
    
    % Find the words_features_per_word features with the minimum SIFT distance for each word
    sorted_word1 = sort(dist_word1(:));
    sorted_word2 = sort(dist_word2(:));
    min_word1 = sorted_word1(1:words_features_per_word);
    min_word2 = sorted_word2(1:words_features_per_word);
    
    % Find the corresponding indices in the features matrix for the
    % features with the minimum SIFT distance
    min_index_word1 = zeros(1, words_features_per_word);
    min_index_word2 = zeros(1, words_features_per_word);
    for i = 1:words_features_per_word
        min_index_word1(i) = find(dist_word1==min_word1(i));    
        min_index_word2(i) = find(dist_word2==min_word2(i));    
    end
    
    % Turn the linear indices into img index and feature index
    img_index_word1 = zeros(1, words_features_per_word);
    img_index_word2 = zeros(1, words_features_per_word);
    feature_index_word1 = zeros(1, words_features_per_word);
    feature_index_word2 = zeros(1, words_features_per_word);
    for i = 1:words_features_per_word
        img_index_word1(i) = floor(min_index_word1(i) / words_feature_sample_size);
        img_index_word2(i) = floor(min_index_word2(i) / words_feature_sample_size);
        feature_index_word1(i) = mod(min_index_word1(i),words_feature_sample_size);
        feature_index_word2(i) = mod(min_index_word2(i),words_feature_sample_size); 
    end
    
    % Get all the feature info
    word1_positions = cell(1, words_features_per_word);
    word1_scales = cell(1, words_features_per_word);
    word1_orients = cell(1, words_features_per_word);
    word1_imgs = cell(1, words_features_per_word);
    word2_positions = cell(1, words_features_per_word);
    word2_scales = cell(1, words_features_per_word);
    word2_orients = cell(1, words_features_per_word);
    word2_imgs = cell(1, words_features_per_word);
    for i = 1:words_features_per_word
        word1_img = sifts{img_index_word1(i)};
        word2_img = sifts{img_index_word2(i)};
        t_word1 = min(feature_index_word1(i), word1_img.numfeats - 1);
        t_word2 = min(feature_index_word2(i), word2_img.numfeats - 1);
        
        word1_positions{i} = word1_img.positions(t_word1, :);
        word1_scales{i} = word1_img.scales(t_word1, :);
        word1_orients{i} = word1_img.orients(t_word1, :);
        word1_imgs{i} = rgb2gray(imgs{img_index_word1(i)});
        word2_positions{i} = word2_img.positions(t_word2, :);
        word2_scales{i} = word2_img.scales(t_word2, :);
        word2_orients{i} = word2_img.orients(t_word2, :);
        word2_imgs{i} = rgb2gray(imgs{img_index_word2(i)});
    end
    
    % Get all the patches
    word1_patches = cell(1, words_features_per_word);
    word2_patches = cell(1, words_features_per_word);
    for i = 1:words_features_per_word
        word1_patches{i} = getPatchFromSIFTParameters(word1_positions{i}, word1_scales{i}, word1_orients{i}, word1_imgs{i});
        word2_patches{i} = getPatchFromSIFTParameters(word2_positions{i}, word2_scales{i}, word2_orients{i}, word2_imgs{i});
    end
    
    % Display all the patches
    word1_display = imtile(word1_patches);
    word2_display = imtile(word2_patches);
    imshow(word1_display);
    imshow(word2_display);
    
    % Save patches
    % imwrite(word1_display, "Q2_1.png");
    % imwrite(word2_display, "Q2_2.png");
end

% Create new vocabulary
function words = createVocabulary(k, feature_sample_size, image_sample_size)
    % DISPLAY
    disp("Creating vocabulary");
    
    % Get image_sample_size number of random images from database
    [imgs, sifts] = getRandomImgsSifts(image_sample_size);
    
    % From each image, get feature_sample_size number of random features
    % Store these all in features, which will be used to create vocabulary
    features = getRandomFeatures(sifts, feature_sample_size);
    
    % Trim all 0 features from matrix
    features = features(:,any(features,1));
    
    % Find k clusters from features
    [membership,means,rms] = kmeansML(k,features);
    
    % Put words in proper orientation and save
    disp("Saving words to kMeans.mat");
    words = means';
    save('kMeans.mat', 'words');
end

% Get feature_sample_size number of random features from each SIFT mat and
% return them in one dxn matrix
function features = getRandomFeatures(sifts, feature_sample_size)
    % DISPLAY
    disp("Getting random features from each SIFT matrix");

    features = zeros(128, (size(sifts, 2) * feature_sample_size));
    for i = 1:size(sifts,2)
        descriptors_i = sifts{i}.descriptors;
        descriptor_indices = randperm(sifts{i}.numfeats, min([feature_sample_size sifts{i}.numfeats]));
        for j = 1:size(descriptor_indices, 2)
            features_ij = descriptors_i(descriptor_indices(j),:);
            features(:, feature_sample_size * (i - 1) + j) = features_ij(:);
        end
    end
end

% Helper function to get image_sample_size number of random image indicies in our range
function [imgs, sifts] = getRandomImgsSifts(image_sample_size)
    % DISPLAY
    disp("Getting random image indices");
    
    min_image_index = 60;
    max_image_index = 6671;
    image_indices = randperm(max_image_index - min_image_index, image_sample_size) + 60;
    [imgs, sifts] = getImgsSifts(image_indices);
end

% Helper function to return images and sift matrices from image indices
% Used to get actual data from our randomly generated image indices
function [imgs,sifts] = getImgsSifts(image_indices)
    % DISPLAY
    disp("Reading in files");
    
    % Get filenames of frame image and sift matrix that correspond with the
    % given image indices
    imgs_filenames = cell(size(image_indices));
    sift_filenames = cell(size(image_indices));
    for i = 1:length(image_indices)
        imgs_filenames{i} = strcat(sprintf('frames/friends_%010d', image_indices(i)), '.jpeg');
        sift_filenames{i} = strcat(sprintf('sift/friends_%010d', image_indices(i)), '.jpeg.mat');
    end
    
    % Actually load the data of the files and return in vectors
    imgs = cell(size(image_indices));
    sifts = cell(size(image_indices));
    for i = 1:length(image_indices)
        imgs{i} = imread(char(imgs_filenames(i)));
        sifts{i} = load(char(sift_filenames(i)));
    end
end
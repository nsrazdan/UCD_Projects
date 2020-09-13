function region_queries()
mat1 = load('sift\friends_0000003818.jpeg.mat');
img1 = selectRegion('frames\friends_0000003818.jpeg', mat1.positions);
mat2 = load('sift\friends_0000001535.jpeg.mat');
img2 = selectRegion('frames\friends_0000001535.jpeg', mat2.positions);
mat3 = load('sift\friends_0000000284.jpeg.mat');
img3 = selectRegion('frames\friends_0000000284.jpeg', mat3.positions);


kmeans = load('kMeans.mat');
kmeans = kmeans.words;

img1disc = load('sift\friends_0000003818.jpeg.mat', 'descriptors');
img1disc = img1disc.descriptors(img1,:);
img2disc = load('sift\friends_0000001535.jpeg.mat', 'descriptors');
img2disc = img2disc.descriptors(img2,:);
img3disc = load('sift\friends_0000000284.jpeg.mat', 'descriptors');
img3disc = img3disc.descriptors(img3,:);

hist1 = dist2(img1disc, kmeans);
[valshis1, indhis1] = min(hist1, [], 2);
s = size(indhis1);
hist1 = histcounts(indhis1, 1500);

hist2 = dist2(img2disc, kmeans);
[valshis2, indhis2] = min(hist2, [], 2);
s = size(indhis2);
hist2 = histcounts(indhis2, 1500);

hist3 = dist2(img3disc, kmeans);
[valshis3, indhis3] = min(hist3, [], 2);
s = size(indhis3);
hist3 = histcounts(indhis3, 1500);

siftfiles = dir(fullfile('sift', '*.mat'));
his1Sim = [];
his1SimName = [];
his2Sim = [];
his2SimName = [];
his3Sim = [];
his3SimName = [];
for x = 1:length(siftfiles)
    if (~strcmp(siftfiles(x).name, 'friends_0000000063.jpeg.mat') & ~strcmp(siftfiles(x).name, 'friends_0000001535.jpeg.mat') & ~strcmp(siftfiles(x).name, 'friends_0000003818.jpeg.mat')) 
        stringCom = "sift\" + siftfiles(x).name;
        des = load(stringCom);
        des = des.descriptors;
        histo = dist2(des, kmeans);
        [useless, histo] = min(histo, [], 2);
        s = size(histo);
        histo = histcounts(histo, 1500);
        his1Sim = [his1Sim, sim(histo, hist1)];
        his1SimName = [his1SimName, stringCom];
        his2Sim = [his2Sim, sim(histo, hist2)];
        his2SimName = [his2SimName , stringCom];
        his3Sim = [his3Sim , sim(histo, hist3)];
        his3SimName = [his3SimName , stringCom];
    end
end

[highest1, high1Ind] = maxk(his1Sim , 5);
[highest2, high2Ind] = maxk(his2Sim , 5); 
[highest3, high3Ind] = maxk(his3Sim , 5); 

% FIRST PICTURE %
tophis1 = his1SimName(high1Ind);
figure(1)
subplot(3,2,1);
imshow('frames\friends_0000003818.jpeg');

his1zero = convertStringsToChars(tophis1(1));
subplot(3,2,2);
his1zero = ['frames' , his1zero(5:end-4)];
imshow(his1zero);

his2zero = convertStringsToChars(tophis1(2));
subplot(3,2,3);
his2zero = ['frames' , his2zero(5:end-4)];
imshow(his2zero);

his3zero = convertStringsToChars(tophis1(3));
subplot(3,2,4);
his3zero = ['frames' , his3zero(5:end-4)];
imshow(his3zero);

his4zero = convertStringsToChars(tophis1(4));
subplot(3,2,5);
his4zero = ['frames' , his4zero(5:end-4)];
imshow(his4zero);

his5zero = convertStringsToChars(tophis1(5));
subplot(3,2,6);
his5zero = ['frames' , his5zero(5:end-4)];
imshow(his5zero);

% SECOND PICTURE %
tophis2 = his2SimName(high2Ind);
figure(2)
subplot(3,2,1);
imshow('frames\friends_0000001535.jpeg');

his1zero = convertStringsToChars(tophis2(1));
subplot(3,2,2);
his1zero = ['frames' , his1zero(5:end-4)];
imshow(his1zero);

his2zero = convertStringsToChars(tophis2(2));
subplot(3,2,3);
his2zero = ['frames' , his2zero(5:end-4)];
imshow(his2zero);

his3zero = convertStringsToChars(tophis2(3));
subplot(3,2,4);
his3zero = ['frames' , his3zero(5:end-4)];
imshow(his3zero);

his4zero = convertStringsToChars(tophis2(4));
subplot(3,2,5);
his4zero = ['frames' , his4zero(5:end-4)];
imshow(his4zero);

his5zero = convertStringsToChars(tophis2(5));
subplot(3,2,6);
his5zero = ['frames' , his5zero(5:end-4)];
imshow(his5zero);

% THIRD PICTURE %
tophis3 = his3SimName(high3Ind);
figure(3)
subplot(3,2,1);
imshow('frames\friends_0000000284.jpeg');

his1zero = convertStringsToChars(tophis3(1));
subplot(3,2,2);
his1zero = ['frames' , his1zero(5:end-4)];
imshow(his1zero);

his2zero = convertStringsToChars(tophis3(2));
subplot(3,2,3);
his2zero = ['frames' , his2zero(5:end-4)];
imshow(his2zero);

his3zero = convertStringsToChars(tophis3(3));
subplot(3,2,4);
his3zero = ['frames' , his3zero(5:end-4)];
imshow(his3zero);

his4zero = convertStringsToChars(tophis3(4));
subplot(3,2,5);
his4zero = ['frames' , his4zero(5:end-4)];
imshow(his4zero);

his5zero = convertStringsToChars(tophis3(5));
subplot(3,2,6);
his5zero = ['frames' , his5zero(5:end-4)];
imshow(his5zero);
end


function res = sim(x, y)
    xnorm = norm(x);
    ynorm = norm(y);
    sumval = x .* y;
    sumval = sum(sum(sumval));
    res = sumval / (xnorm*ynorm);
end

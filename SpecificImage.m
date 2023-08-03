clear; close all; clc;

imageSize = [168, 192];
n = prod(imageSize);

imageFolder = 'YaleB';
imageFiles = dir(fullfile(imageFolder, '*.pgm'));

m = numel(imageFiles); % Number of images in the folder

F = zeros(n, m);

for i = 1:m
    imagePath = fullfile(imageFolder, imageFiles(i).name);
    img = im2gray(imread(imagePath));
    imgVector = double(reshape(img, [], 1)); 

    % Normalize the image vector
    imgVector = (imgVector - min(imgVector)) / (max(imgVector) - min(imgVector));

    F(:, i) = imgVector;
end

N = 38; 

%% Calculate MeanFace
meanFace = mean(F, 2);
centeredF = F - meanFace;

%% SVD
[U, S, ~] = svd(centeredF, 'econ');

%% EigenFaces
totalEnergy = sum(diag(S).^2);
cumulativeEnergy = cumsum(diag(S).^2);
thresholdIndex = find(cumulativeEnergy >= 0.95 * totalEnergy, 1);
eigenfaces = U(:, 1:thresholdIndex);

%% Face Recognition

numTestImages = 1;
guessedLabels = zeros(1, numTestImages);
trueLabels = zeros(1, numTestImages);

testImagePath = 'testImage.jpg';
testImage = im2gray(imread(testImagePath));
desiredSize = fliplr(imageSize);
testImage = imresize(testImage, desiredSize, 'nearest');
testImageVector = double(reshape(testImage, [], 1));
testImageNormalized = testImageVector - meanFace;

for i = 1:numTestImages

    trainIndices = setdiff(1:m, i);
    trainF = F(:, trainIndices);

    centeredTrainF = trainF - meanFace;
    projectedTrainImages = eigenfaces' * centeredTrainF;

    projectedTestImage = eigenfaces' * testImageNormalized;
    distances = pdist2(projectedTrainImages', projectedTestImage', 'mahalanobis')';

    [~, minIndex] = min(distances);

    guessedLabels(i) = ceil(trainIndices(minIndex) / (m / N));
    trueLabels(i) = ceil(i / (m / N));

end


%% Face Recognition

testDistanceToMean = vecnorm(testImageNormalized - meanFace);

fprintf('Distance to mean: %f\n', testDistanceToMean);



%% Display

guessedSubjectIndex = guessedLabels(1); 

guessedSubjectImageFiles = imageFiles((guessedSubjectIndex - 1) * (m / N) + 1 : guessedSubjectIndex * (m / N));
guessedSubjectImagePath = fullfile(imageFolder, guessedSubjectImageFiles(1).name);

guessedSubjectImage = im2gray(imread(guessedSubjectImagePath));

figure;
colormap(gray); 

subplot(1, 2, 1);
imagesc(reshape(testImageVector, fliplr(imageSize)));
axis off;
title('Test Image');

subplot(1, 2, 2);
imagesc(guessedSubjectImage);
axis off;
title('First Image of Guessed Subject');

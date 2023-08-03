clear; close all; clc;

imageSize = [168 192];
n = prod(imageSize); 

imageFolder = 'YaleB';
imageFiles = dir(fullfile(imageFolder, '*.pgm'));

m = numel(imageFiles); % Number of images in the folder

F = zeros(n, m); 

for i = 1:m
    imagePath = fullfile(imageFolder, imageFiles(i).name);  
    imgVector = double(reshape(im2gray(imread(imagePath)), [], 1));

    imgVector = (imgVector - min(imgVector)) / (max(imgVector) - min(imgVector));

    F(:, i) = imgVector; 
end

N = 38; 

thresholdValues = [0.1, 0.5, 0.75, 0.85, 0.9, 0.95, 0.99, 0.999, 0.9999];
testSizeValues = [0.1, 0.15, 0.2, 0.25, 0.3, 0.5, 0.75, 1];

for testSizePercentage = testSizeValues
    for threshold = thresholdValues
    
        %% Train Size / MeanFace
        testSize = round(m * testSizePercentage);
        trainSize = m - testSize;
        meanFace = mean(F, 2);
        centeredF = F - meanFace;

        %% SVD
        [U, S, ~] = svd(centeredF, 'econ');

        %% EigenFaces
        totalEnergy = sum(diag(S).^2);
        cumulativeEnergy = cumsum(diag(S).^2);
        thresholdIndex = find(cumulativeEnergy >= threshold * totalEnergy, 1);
        eigenfaces = U(:, 1:thresholdIndex);

        projectedImages = eigenfaces' * centeredF;

        %% Face Recognition 

        numTestImages = testSize;
        guessedLabels = zeros(1, numTestImages);
        trueLabels = zeros(1, numTestImages);

        for i = 1:numTestImages

            testImageIndex = randi(m);
            testImage = F(:, testImageIndex);
            testImageNormalized = testImage - meanFace; 

            trainIndices = setdiff(1:m, testImageIndex);
            trainF = F(:, trainIndices);

            centeredTrainF = trainF - meanFace;
            projectedTrainImages = eigenfaces' * centeredTrainF;
            projectedTestImage = eigenfaces' * testImageNormalized;
            distances = pdist2(projectedTrainImages', projectedTestImage', 'mahalanobis')';

            [~, minIndex] = min(distances);

            guessedLabels(i) = ceil(trainIndices(minIndex) / (m / N));
            trueLabels(i) = ceil(testImageIndex / (m / N));
        end

        accuracy = sum(guessedLabels == trueLabels) / numTestImages * 100;

        fprintf('Threshold: %.4f, Test Size Percentage: %.2f\n', threshold, testSizePercentage);
        fprintf('Face recognition accuracy: %.2f%%.\n', accuracy);
    end
end

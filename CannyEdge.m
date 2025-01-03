function cannyEdgeImage = CannyEdge(image)
image = rgb2gray(image);


% 1- smooth the image with gaussian filter, to reduce the noise from the image
%intensity function, with sigma = 0.25 (the less the sigme, the less blur
%we'll have)
smoothed_img = imgaussfilt(image,0.25);

% 2- compute the image gradient using sobel operator (which is based on the
% 1st derivative)
sobel_karnelx = [-1, 0, 1; -2, 0, 2; -1, 0, 1];
sobel_karnely = [1, 2, 1; 0, 0, 0; -1, -2, -1];

% convolute the 2-d image horizontally and vertically with sobel mask
filtered_image_x = conv2(smoothed_img,sobel_karnelx,'same');
filtered_image_y = conv2(smoothed_img,sobel_karnely,'same');


% 3- calculate the magnitude and direction/orientation of the image

% 3.1- magnitude (The higher the Gradient magnitude, the stronger the
% change in the image intensity)
magnitude = sqrt((filtered_image_x.^2) + (filtered_image_y.^2));

% 3.2.1 - direction/orientation of pixels
angle = atan2(filtered_image_y, filtered_image_x);
angle = angle*(180/pi);

% 3.2.2 - the gradient directions must be positive
rows = size(smoothed_img, 1);
columns = size(smoothed_img, 2);

for i = 1:rows
    for j = 1:columns
        if (angle(i, j) < 0)
            angle(i, j) = angle(i, j) + 360;
        end
    end
end


% 3.2.3 - the gradient directions must be perpendicular to the edges; thus, 
% we'll try to round the angles elements in the angle matrix to the one of 
% 4 angles representing vertical, horizontal, and two diagonal directions.
% which are (0, 45, 90, and 135), and add the rounded angles to a new
% matrix to use it in the step of Non-Max Suppression (step 4 later)

% the new matrix that will have the rounded angles will be filled with
% zeros, in order to save ONLY angles that seem to represent edges 
angle2 = zeros(rows, columns);

for i = 1 : rows
    for j = 1 : columns
        if ((angle(i, j) >= 0 ) && (angle(i, j) < 22.5) || (angle(i, j) >= 157.5) && (angle(i, j) < 202.5) || (angle(i, j) >= 337.5) && (angle(i, j) <= 360))
            angle2(i, j) = 0;
        elseif (angle(i, j) >= 22.5) && (angle(i, j) < 67.5) || (angle(i, j) >= 202.5) && (angle(i, j) < 247.5)
            angle2(i, j) = 45;
        elseif ((angle(i, j) >= 67.5 && angle(i, j) < 112.5) || (angle(i, j) >= 247.5 && angle(i, j) < 292.5))
            angle2(i, j) = 90;
        elseif ((angle(i, j) >= 112.5 && angle(i, j) < 157.5) || (angle(i, j) >= 292.5 && angle(i, j) < 337.5))
            angle2(i, j) = 135;
        end
    end
end


% 4- Non-Max Suppression; where we'll remove all the unwanted pixels which may not constitute an edge.

% create a new matrix of zeros to replace some values to 1 to indicate an
% edge; where 0 and 1 mean black and white.
BlackWhite = zeros(rows, columns);


for i=2:rows-1
    for j=2:columns-1
        if (angle2(i,j)==0)
            BlackWhite(i,j) = magnitude(i,j) == max([magnitude(i,j), magnitude(i,j+1), magnitude(i,j-1)]);

        elseif (angle2(i,j)==45)
            BlackWhite(i,j) = magnitude(i,j) == max([magnitude(i,j), magnitude(i+1,j-1), magnitude(i-1,j+1)]);

        elseif (angle2(i,j)==90)
            BlackWhite(i,j) = magnitude(i,j) == max([magnitude(i,j), magnitude(i+1,j), magnitude(i-1,j)]);

        elseif (angle2(i,j)==135)
            BlackWhite(i,j) = magnitude(i,j) == max([magnitude(i,j), magnitude(i+1,j+1), magnitude(i-1,j-1)]);

        end
    end
end


BlackWhite = BlackWhite.*magnitude;

% 5- Double Threshold; Pixels due to noise and color variation would persist
% in the image. So, to remove this, we'll use two thresholds values
upperVal = 0.15*max(max(BlackWhite));
lowerVal = 0.05*max(max(BlackWhite));
threshold = zeros(rows,columns);

for i = 1 : rows
    for j = 1 : columns
        % if the thinned edge magnitude for candidate edge is...
        % less than the lower value of threshold, then it is not edge;
        % hence, the threshold element in i and j will be 0
        if (BlackWhite(i, j) < lowerVal)
            threshold(i, j) = 0;
        
        % greater than the upper value of threshold, then it is an edge;
        % hence, the threshold element in i and j will be 1
        elseif (BlackWhite(i, j) > upperVal)
            threshold(i, j) = 1;

        % between the upper value and lower value of threshold then it'll
        % be an edge; hence, the threshold element in i and j will be 1
        elseif ( BlackWhite(i+1,j)>upperVal || BlackWhite(i-1,j)>upperVal || BlackWhite(i,j+1)>upperVal || BlackWhite(i,j-1)>upperVal || BlackWhite(i-1, j-1)>upperVal || BlackWhite(i-1, j+1)>upperVal || BlackWhite(i+1, j+1)>upperVal || BlackWhite(i+1, j-1)>upperVal)
            threshold(i,j) = 1;

        end
    end
end

cannyEdgeImage = uint8(threshold.*255);
imshow(cannyEdgeImage)



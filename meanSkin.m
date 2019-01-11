function [meanSkinPixel] = meanSkin(faceImg)
    %MEANSKIN Summary of this function goes here
    %The function accepts a cropped image consisting only of the facial region
    %of interest and processes it to find the skin pixels in the image and
    %then returns the mean value of all the pixels classified as skin.
    %   Detailed explanation goes here



        
    %Use k-means segmentation for skin pixel classification(k=3)
    [L,Centers] = imsegkmeans(faceImg,3);
      
    % The center with highest red value will be the one identifying skin pixels  
    red = Centers(:,1);
        
    %Select the Label with highest red value
    [~, skinL] = max(red);
        
    [rows,cols] = size(L);

    %Iterate over all pixels to find the ones classified as skin
    for col = 1:cols
        for row = 1:rows
            if(L(row,col) == skinL)
                pix = faceImg(row,col,:);
                skinPixels = [ skinPixels pix];
            end
        end
    end
    
    %Mean value of all pixels identified as skin in the current frame.
    meanSkinPixel = mean(skinPixels);
end


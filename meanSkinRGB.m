function [R,G,B] = meanSkinRGB(faceImg)

    meanSkinPixel = meanSkin(faceImg);
    
    R = meanSkinPixel(:,:,1);
    G = meanSkinPixel(:,:,2);
    B = meanSkinPixel(:,:,3);

end


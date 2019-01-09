function video_ppg()

    % create bandpass filter between 40-220-HZ
    % create only once
    %[b_BPF40220, a_BPF40220] = butter(9, ([40 220] /60)/(Fs/2),  'bandpass'); 
    
    % Display rPPG bmp settings
    position = [10 10];
    box_color = {'blue'};
    bpm_str = ['BMP: 0'];
    


    %% INIT VIDEO dir
 

    
    fileDir = "VHMDataset\stationary\bmp\";


    % INIT Face detection with Viola-Jones algorithm
    % Create a cascade detector object.
    faceDetector  = vision.CascadeObjectDetector();
    eyeDetector   = vision.CascadeObjectDetector('EyePairBig', 'UseROI', true);
    noseDetector = vision.CascadeObjectDetector('Nose', 'UseROI', true);
    % bad performance, so dont use
    %mouthDetector = vision.CascadeObjectDetector('Mouth', 'UseROI', true); 

    %% INIT face tracking fucntion
    face_found = false;
    n = 1;
    while face_found == false
        % get first frame to get face and make init ROI for the tracker
        filename = fileDir + n +".bmp";
        img = imread(filename);
        n = n+1;

        img = imresize(img, 0.5);

        % get first ROI to init tracker
        rect_prev = step(faceDetector, img);

        % Visualize bounding box in the frame
        img_ann = insertObjectAnnotation(img,'rectangle',rect_prev,'ROI'); 

        if isempty(rect_prev)
            % if no face found add message
            text_str = ['No face found'];
            position = [0 0];
            box_color = {'red'};
        else
            % face is found, start with tracking
            face_found = true;
            text_str = ['Face found!, going to start measurment'];
            position = [rect_prev(1) (rect_prev(2)-(60/0.5))];
            box_color = {'green'};
        end

        % show img with warning msg
        img_text = insertText(img_ann, position, text_str, 'FontSize', 18, 'BoxColor', box_color, 'BoxOpacity', 0.4, 'TextColor', 'white');
        imshow(img_text)

    end


    % init tacker
    TrackInitFlag = false;

    if TrackInitFlag == false
        % Initialize tracker
        TrackFirstRun = true;
        trackermodel.model_alphaf = 0;
        trackermodel.model_xf = 0;

        [TrackerInit, TrackInitFlag] = InitTracker; % TrackInitFlag set to true 
        [rect, trackermodel] = tracker(img, TrackerInit, rect_prev, trackermodel, TrackFirstRun); 
        TrackFirstRun = false;
    end

    % TrackInitFlag; flag to indicate if tracker is initialized
    % TrackerInit; struct with tracker parameters
    % rect; bounding box coordinates current frame
    % img; RGB input image
    % rect_prev; bounding box coordinates previous frame
    % trackermodel; struct of tracker model, updated at each iteration
    % TrackFirstRun; flag to indicate if the tracker is executed for the first time, necessary for the trackermodel


    %% Do here the detection loop

    %Array of mean value of skin pixels in each frame
    skinPixArray = [];
    
    while true
        %File to read        
        filename = fileDir + n +".bmp";
        
        %Break Loop if file not found
        if (~isfile(filename))
            break;
        end
        img = imread(filename);
        n = n+1;
        % get video frame
        img = imresize(img, 0.5);
        [rect,trackermodel] = tracker(img, TrackerInit, rect_prev, trackermodel, TrackFirstRun); 

        img_ann = insertObjectAnnotation(img,'rectangle',rect,'Face found');

        BB_eye  = eyeDetector(img, rect);
        %BB_nose = noseDetector(img, rect);

        % Visualize bounding box in the frame
        img_ann = insertObjectAnnotation(img_ann,'rectangle',BB_eye,'Eyes found');
        %img_ann = insertObjectAnnotation(img_ann,'rectangle',BB_nose,'Nose found');
        
        
        % show bpm in img
        img_bmp = insertText(img_ann, position, bpm_str, 'FontSize',24, 'BoxColor', box_color, 'BoxOpacity' ,0.4 ,'TextColor','white');
    
      
        if ~(isempty(BB_eye))
            x = floor(BB_eye(1) + BB_eye(3)/2);
            y1 = floor(BB_eye(2) - (BB_eye(4)/1.5));
            y2 = floor(BB_eye(2) + (BB_eye(4)*1.5));
            img_bmp = insertShape(img_bmp,'Line',[x y1 x y2],'LineWidth',2,'Color','blue');
        
            img_bmp = insertObjectAnnotation(img_bmp,'rectangle',[x-30 y1-30 60 30],'meas', 'LineWidth',2,'Color','green');
        end
        
        %List of skin pixels in the current frame
        skinPixels = [];
        
        %Crop the face ROI from the complete image
        faceImg = imcrop(img,rect);
        
        %Use k-means segmentation for skin pixel classification(k=3)
        [L,Centers] = imsegkmeans(faceImg,3);
        
        % The center with highest red value will be the one identifying skin pixels  
        red = Centers(:,1);
        
        %Select the Label with highest red value
        [value, skinL] = max(red);
        
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
        meanSkin = mean(skinPixels);        
        
        %Append the mean skin value
        skinPixArray = [skinPixArray meanSkin];  

        imshow(img_bmp)


    end
    
    fs_video=20;
    R=skinPixArray(1,:,1);
    G=skinPixArray(1,:,2);
    B=skinPixArray(1,:,3);
    
    t=[0:length(R)-1]/fs_video;
    figure
    plot(t,G,'g')
    hold on
    plot(t,R,'r')
    hold on
    plot(t,B,'b')



end
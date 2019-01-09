function webcam_ppg()

    % create bandpass filter between 40-220-HZ
    % create only once
    %[b_BPF40220, a_BPF40220] = butter(9, ([40 220] /60)/(Fs/2),  'bandpass'); 
    
    % Display rPPG bmp settings
    position = [10 10];
    box_color = {'blue'};
    
    first_window = 15;
    first_run = true;
    
    % create queary ploints for interpolation
    % only once
    xq = 0:pi/16:2*pi;

    %% Webcam get picture data

    %% INIT WEBCAM stuff
    % Identifying Available Webcams
    camList = webcamlist;

    % Connect to the webcam.
    cam = webcam(1);

    % webcam settings
    %cam.Resolution = '320x240';
    %cam.Exposure = -4;
    %cam.Gain = 253;
    %cam.Saturation = 32;
    %cam.WhiteBalance = 8240;
    %cam.WhiteBalanceMode = 'manual';
    %cam.ExposureMode = 'manual'; 
    %cam.Sharpness = 48;
    %cam.Brightness = 128;
    %cam.BacklightCompensation = 1;
    %cam.Contrast = 32;
    %preview(cam)

    % INIT Face detection with Viola-Jones algorithm
    % Create a cascade detector object.
    faceDetector  = vision.CascadeObjectDetector();
    eyeDetector   = vision.CascadeObjectDetector('EyePairBig', 'UseROI', true);
    noseDetector = vision.CascadeObjectDetector('Nose', 'UseROI', true);
    % bad performance, so dont use
    %mouthDetector = vision.CascadeObjectDetector('Mouth', 'UseROI', true); 

    %% INIT face tracking fucntion
    face_found = false;
    while face_found == false
        % get first shot to get face and make init ROI for the tracker
        [img, ~] = snapshot(cam);

        img = imresize(img, 0.5);

        % get first ROI to init tracker
        rect_prev = step(faceDetector, img);

        % Visualize bounding box in the frame
        img_ann = insertObjectAnnotation(img,'rectangle',rect_prev,'ROI'); 

        if isempty(rect_prev)
            % if no face found add message
            text_str = ['No face found, please allign on webcam, or add more light!'];
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

    cnt = 1;
    start = cnt;
    while true
        % get camera frame
        [img, w_timestamp(cnt)] = snapshot(cam);
        img = imresize(img, 0.5);
        [rect,trackermodel] = tracker(img, TrackerInit, rect_prev, trackermodel, TrackFirstRun); 

        img_ann = insertObjectAnnotation(img,'rectangle',rect,'Face found');

        BB_eye  = eyeDetector(img, rect);
        %BB_nose = noseDetector(img, rect);

        % Visualize bounding box in the frame
        img_ann = insertObjectAnnotation(img_ann,'rectangle',BB_eye,'Eyes found');
        %img_ann = insertObjectAnnotation(img_ann,'rectangle',BB_nose,'Nose found');

        if ~(isempty(BB_eye))
            x = BB_eye(1) + BB_eye(3)/2;
            y1 = BB_eye(2) - (BB_eye(4)/1.5);
            y2 = BB_eye(2) + (BB_eye(4)*1.5);
            img_bmp = insertShape(img_bmp,'Line',[x y1 x y2],'LineWidth',2,'Color','blue');

            img_bmp = insertObjectAnnotation(img_bmp,'rectangle',[x-30 y1-30 60 30],'meas', 'LineWidth',2,'Color','green');
        
            
            % window capture
            if  first_run == true % first run
                if (w_timestap(cnt) >= first_window) % XXs captured first time calc ppg

                    % resample webcam data      
                    [Rc, Gc, Bc] = webcam_interpl(Rc, Gc, Bc, w_timestap, start, cnt, w_timestap);
                    s_ppg = update_ppg(Rc, Gc, Bc, w_timestap(1), w_timestap(cnt), w_timestap);
    
                    % update sliding window
                    start = start + wind_slide;
                    first_run = false; % switch to sliding window
                end
                
            % else update sliding window    
            elseif (w_timestap(cnt) >= first_window)
                % resample webcam data       
                [R_rs, G_rs, B_rs] = webcam_interpl(R_clean(start:cnt), G_clean(start:cnt), B_clean(start:cnt), w_timestap(1), w_timestap(cnt), w_timestap);
                % update ppg
                s_ppg = update_ppg(R_rs(start:cnt), G_rs(start:cnt), B_rs(start:cnt), w_timestap(start:cnt), w_timestap(cnt), w_timestap);
                
                start = start + wind_slide;
            end

            % insert bpm in img
            img_bpm = insertText(img_ann, position, num2str(s_ppg), 'FontSize', 24, 'BoxColor', box_color, 'BoxOpacity' ,0.4 ,'TextColor','white');
            % update img
            imshow(img_bpm)
            cnt = cnt +1;

        end
    end
    
    % evaluation of the framework
    fw_evaluation(P_F);

    % Clean Up
    clear cam

end
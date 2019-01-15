function s_ppg = webcam_ppg(Fs)

    crop_mac = true;
    crop_size = 0.25;
    res_windows = '320x240';
    
    max_run = 30;       % define maximal runtime before quit
    max_run = max_run - 15;
     
    % ppg Sliding window settings 
    window_size = 15;   % size in frames
    Fs = 20;            % in Hz
    update_Fs = 1/Fs;   % in time
    Fs_time = 1;
    min_run = 15;       % max runtime for allocation
     
    % Display rPPG bpm settings
    bpm_front_size = 18;         
    bpm_position = [10 10];     % position of bpm print
    bpm_box_color = {'blue'};   % color of box
    bpm_text_color = {'white'};
         
    fps_position = [10 140];     % position of bpm print
    fps_box_color = {'green'};   % color of box
    fps = 0;
     
    % create bandpass filter between 40-220-HZ
    % create only once
    [b_BPF40220, a_BPF40220] = butter(9, ([40 220] /60)/(Fs/2),  'bandpass'); 
    
    s_ppg = 0;
 
    %% Webcam get picture data
 
    %% Select webcam input
    % Identifying Available Webcams
    camList = webcamlist;
    
    % If more than one webcam provide a choise
    if length(camList) > 1
        prompt = 'Select webcam: webcam1[1]/ webcam2[2]/ quit: ';
        choise = input(prompt,'s');
        
        while ((choise~='1') && (choise~='2') && (choise~='q'))
            disp('Wrong input selected, please slelect correct:')
            prompt = 'Select webcam: webcam1[1]/ webcam2[2]/ quit: ';
            choise = input(prompt,'s');
        end
        
        disp(' ')
        disp('You selected the correct input:')
        if choise == '1'
            disp('- Webcam1')
            % Select correct webcam from list
            cam = webcam(1);
        elseif choise == '2'
            disp('- Webcam2')
            cam = webcam(2);
        else
            disp('- Quit framework')
            return
        end
        
    else
        % Connect to the webcam.
        cam = webcam(1);
    end
 
    % webcam settings
    %cam.Resolution = res_windows;
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
 
    % INIT Face detection with Viola-Jones algorithm
    % Create a cascade detector object.
    faceDetector  = vision.CascadeObjectDetector();
    %eyeDetector   = vision.CascadeObjectDetector('EyePairBig', 'UseROI', true);
    %noseDetector = vision.CascadeObjectDetector('Nose', 'UseROI', true);
    % bad performance, so dont use
    %mouthDetector = vision.CascadeObjectDetector('Mouth', 'UseROI', true); 
   
    %% INIT face tracking fucntion
    face_found = false;
    while face_found == false
        % get first shot to get face and make init ROI for the tracker
        [img, ~] = snapshot(cam);
        
        % only crop picture if you want, on windows use other resolution
        if crop_mac == true
            img = imresize(img, crop_size);
        end
 
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
            text_str = ['Face found!, start measurment'];
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
    
    % pre allocate array for realtime speed
    w_timestamp = zeros(1, 20*60*min_run, 'double');
    Rm = zeros(1, 20*60*min_run, 'double');
    Gm = zeros(1, 20*60*min_run, 'double');
    Bm = zeros(1, 20*60*min_run, 'double');
    
    Ri = zeros(1, 20*60*min_run, 'double');
    Gi = zeros(1, 20*60*min_run, 'double');
    Bi = zeros(1, 20*60*min_run, 'double');
    
    s_ppg = zeros(1, 60*min_run);
 
    last = 1;
    first = 1;
    f_first = 1;
    f_last = 300;
    sec = 4;
    
    test = 281;
    
    bpm ='0';
    w_timestamp(last) = 0;
    
    while w_timestamp(first) < max_run
        w_timestamp(first)
        % get camera frame
        [img, w_timestamp(last)] = snapshot(cam);
        
        % resize
        if crop_mac == true
            img = imresize(img, crop_size);
        end
        % track face
        [rect, trackermodel] = tracker(img, TrackerInit, rect_prev, trackermodel, TrackFirstRun); 
        img_ann = insertObjectAnnotation(img,'rectangle',rect,'Face found');
        
        rect2 = [rect(1)+floor(0.2*rect(3)) rect(2) floor(0.6*rect(3)) rect(4)];
        
        % calc mean pix value
        [Rm(last), Gm(last), Bm(last)] = meanSkinRGB(imcrop(img,rect2));

        if last > 1
            fps = 1/(w_timestamp(last) - w_timestamp((last-1)));
        end
        %BB_eye  = eyeDetector(img, rect);
        %BB_nose = noseDetector(img, rect);
 
        % Visualize bounding box in the frame
        %img_ann = insertObjectAnnotation(img_ann,'rectangle',BB_eye,'Eyes found');
        %img_ann = insertObjectAnnotation(img_ann,'rectangle',BB_nose,'Nose found');
 
        %if ~(isempty(BB_eye))
        %    x = BB_eye(1) + BB_eye(3)/2;
        %    y1 = BB_eye(2) - (BB_eye(4)/1.5);
        %    y2 = BB_eye(2) + (BB_eye(4)*1.5);
        %    img_bmp = insertShape(img_bmp,'Line',[x y1 x y2],'LineWidth',2,'Color','blue');
 
        %    img_bmp = insertObjectAnnotation(img_bmp,'rectangle',[x-30 y1-30 60 30],'meas', 'LineWidth',2,'Color','green');
             
        % window capture, update sliding window    
        if (w_timestamp(last) - w_timestamp(first) >= window_size)
            % resample webcam data    
            
            if window_size == 1
                [Ri(test:f_last), Gi(test:f_last), Bi(test:f_last)] = webcam_interpl(Rm, Gm, Bm, w_timestamp, first, last, update_Fs, 20);
            else
                [Ri(f_first:f_last), Gi(f_first:f_last), Bi(f_first:f_last)] = webcam_interpl(Rm, Gm, Bm, w_timestamp, first, last, update_Fs, 300);
                window_size = 1;
            end
            % update ppg
            s_ppg(sec) = update_ppg(Ri, Gi, Bi, f_first, f_last, b_BPF40220, a_BPF40220);
            
            w_timestamp(first) = w_timestamp(first) + Fs_time;
            f_first = f_first + Fs;
            f_last = f_last + Fs;
            test = test + Fs;
            
            bpm = num2str(s_ppg(sec));
            
            sec = sec +1;
        end
 
        % insert pulse rate in img
        img_pulse = insertText(img_ann, bpm_position, bpm, 'FontSize', bpm_front_size, 'BoxColor', bpm_box_color, 'BoxOpacity' ,0.4 ,'TextColor', bpm_text_color);
        img_pulse = insertText(img_pulse, fps_position, fps, 'FontSize', bpm_front_size, 'BoxColor', fps_box_color, 'BoxOpacity' ,0.4 ,'TextColor', bpm_text_color);
        % update img
        imshow(img_pulse)
        last = last +1;
    end
 
 % Clean Up
 clear cam
 end
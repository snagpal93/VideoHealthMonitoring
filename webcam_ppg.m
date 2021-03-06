function [ppg, chrom] = webcam_ppg(Fs)

    %% Webcam framework Settings.
    crop_mac = true;            % choose if mac is used
    crop_size = 0.5;            % choose crop size on mac
    res_windows = '320x240';    % on windows dont crop but use resolution
    max_run = 1;                % define maximal runtime in min before quit

    % ppg Sliding window settings .
    window_size = 4;   % size in frames
    Fs = 20;            % in Hz
    update_Fs = 1/Fs;   % in time
    Fs_time = 1;
    min_run = 15;       % max runtime for allocation in min

    % Display rPPG bpm settings.
    bpm_front_size = 18;         
    bpm_position = [10 10];     % position of bpm print.
    bpm_box_color = {'blue'};   % color of box.
    bpm_text_color = {'white'}; % text color.
    % Face detected msg.
    face_str = ['Face detected!'];
    no_face_str = ['No face found, please allign on webcam, or add more light!'];
    
    %% Allocate arrays and filters.

    % create bandpass filter between 40-220-HZ
    [b_BPF40220, a_BPF40220] = butter(9, ([40 220] /60)/(Fs/2),  'bandpass');
    [b_LPF30, a_LPF30] = butter(6, ([30]/60)/(Fs/2), 'low');

    % pre allocate array for realtime speed
    w_timestamp = zeros(1, 20*60*min_run, 'double');
    Rm = zeros(1, 20*60*min_run, 'double');
    Gm = zeros(1, 20*60*min_run, 'double');
    Bm = zeros(1, 20*60*min_run, 'double');

    Ri = zeros(1, 20*60*min_run, 'double');
    Gi = zeros(1, 20*60*min_run, 'double');
    Bi = zeros(1, 20*60*min_run, 'double');

    s_chrom = zeros(1, 20*60*min_run, 'double');
    s_ppg = zeros(1, 60*min_run);

    %% Select webcam input
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
            disp(strcat('You have choosen: ',camList(1)))
            % Select correct webcam from list
            cam = webcam(1);
        elseif choise == '2'
            disp(strcat('You have choosen: ',camList(2)))
            cam = webcam(2);
        else
            disp('- Quit framework')
            return
        end

    else
        % Connect to the webcam.
        disp(strcat('This webcam will be used: ',camList(1)))
        cam = webcam(1);
    end
    
    % Real-time pluse rate plotting?
    prompt = 'Plot real-time pluse rate graph?[y/n]: ';
    plot = input(prompt,'s');

    while ((plot~='y') && (plot~='n'))
        disp('Wrong input selected, please slelect correct:')
        prompt = 'Plot real-time pluse rate graph?[y/n]: ';
        plot = input(prompt,'s');
    end

    disp(' ')
    if plot == 'y'
        disp('Real-time plot is showed.');
        figure;
    else plot == 'n'
        disp('No real-time plot is showed.');
    end

    
    %% Init Setting

    % webcam resolution settings
    if crop_mac == false
        cam.Resolution = res_windows;
    end

    % INIT Face detection with Viola-Jones algorithm
    faceDetector  = vision.CascadeObjectDetector();

    % Create the point tracker object.
    pointTracker = vision.PointTracker('MaxBidirectionalError', 2);

    % Capture one frame to get its size.
    videoFrame = snapshot(cam);
    
    % only crop picture if you want, on windows use other resolution
    if crop_mac == true
        videoFrame = imresize(videoFrame, crop_size);
    end
    frameSize = size(videoFrame);
    
    % Create the video player object. 
    videoPlayer = vision.VideoPlayer('Position', [100 100 [frameSize(2), frameSize(1)]+30]);

    % Calc face detection msg pos based on video size
    face_pos = [((frameSize(2)/2)-45) 10];
    no_face_pos = [((frameSize(2)/2)-140) 10];
    
    % Calc FPS msg pos based on video size
    fps_position = [10 (frameSize(1)- 40)];     % position of bpm print
    fps_box_color = {'green'};   % color of box
    fps = 0;

    % Detetion loop setting
    last = 1;
    first = 1;
    f_first = 1;
    f_last = 80;
    sec = 4;
    test = 61;
    bpm ='0';
    
    max_run = max_run*60; % convert runtime to seconds
    runLoop = true;         % check for
    numPts = 0;
    
    %% Detection and Tracking
    while runLoop && w_timestamp(first) < max_run

        % Get the next frame.
        [videoFrame, w_timestamp(last)] = snapshot(cam);
        
        % only crop picture if resolution is not supported
        if crop_mac == true
            videoFrame = imresize(videoFrame, crop_size);
        end
        
        videoFrameGray = rgb2gray(videoFrame);

        if numPts < 10 % if less than XX tracking points search for face
            % Detection mode.
            bbox = faceDetector.step(videoFrameGray);

            if ~isempty(bbox)
                % Find corner points inside the detected region.
                points = detectMinEigenFeatures(videoFrameGray, 'ROI', bbox(1, :));

                % Re-initialize the point tracker.
                xyPoints = points.Location;
                numPts = size(xyPoints,1);
                release(pointTracker);
                initialize(pointTracker, xyPoints, videoFrameGray);

                % Save a copy of the points.
                oldPoints = xyPoints;

                % Convert the rectangle represented as [x, y, w, h] into an
                % M-by-2 matrix of [x,y] coordinates of the four corners. This
                % is needed to be able to transform the bounding box to display
                % the orientation of the face.
                bboxPoints = bbox2points(bbox(1, :));

                % Convert the box corners into the [x1 y1 x2 y2 x3 y3 x4 y4]
                % format required by insertShape.
                bboxPolygon = reshape(bboxPoints', 1, []);
            end

        else
            % Tracking mode, track points with track, speedup!
            [xyPoints, isFound] = step(pointTracker, videoFrameGray);
            visiblePoints = xyPoints(isFound, :);
            oldInliers = oldPoints(isFound, :);

            numPts = size(visiblePoints, 1);

            if numPts >= 10
                % Estimate the geometric transformation between the old points
                % and the new points.
                [xform, oldInliers, visiblePoints] = estimateGeometricTransform(...
                    oldInliers, visiblePoints, 'similarity', 'MaxDistance', 4);

                % Apply the transformation to the bounding box.
                bboxPoints = transformPointsForward(xform, bboxPoints);

                % Convert the box corners into the [x1 y1 x2 y2 x3 y3 x4 y4]
                % format required by insertShape.
                bboxPolygon = reshape(bboxPoints', 1, []);

                % Reset the points.
                oldPoints = visiblePoints;
                setPoints(pointTracker, oldPoints);
            end

        end

        % If face is detected or tracked calc pulse rate
        if ~isempty(bbox) 
            
            % Visualize bounding box in the frame
            if bboxPoints(1,2) < bboxPoints(2,2)
                % Crop face to eliminate extra surounding noise
                rect = [(bboxPoints(1,1)+ 0.15*(bboxPoints(3,1)-bboxPoints(1,1))) bboxPoints(2,2) ((bboxPoints(3,1)-bboxPoints(1,1))- 0.3*(bboxPoints(3,1)-bboxPoints(1,1))) (bboxPoints(4,2)-bboxPoints(2,2))];
            else
                rect = [(bboxPoints(4,1)+ 0.15*(bboxPoints(2,1)-bboxPoints(4,1))) bboxPoints(1,2) ((bboxPoints(2,1)-bboxPoints(4,1))- 0.3*(bboxPoints(2,1)-bboxPoints(4,1))) (bboxPoints(3,2)-bboxPoints(1,2))];
            end
            
            % Skin classification and mean skin color calc
            [Rm(last), Gm(last), Bm(last)] = meanSkinRGB(imcrop(videoFrame, rect));
            
            % Display a bounding box around the detected face.
            %videoFrame = insertObjectAnnotation(videoFrame,'rectangle',rect ,'Face'); 
            videoFrame = insertShape(videoFrame, 'Polygon', bboxPolygon, 'LineWidth', 3);

            % Calc FPS
            if last > 1
                fps = 1/(w_timestamp(last) - w_timestamp((last-1)));
            end
            
            % Slinding window 
            if (w_timestamp(last) - w_timestamp(first) >= window_size)
                
                % resample webcam data                
                if window_size == 1
                    [Ri(test:f_last), Gi(test:f_last), Bi(test:f_last)] = webcam_interpl(Rm, Gm, Bm, w_timestamp, first, last, update_Fs, 20);
                else

                    [Ri(f_first:f_last), Gi(f_first:f_last), Bi(f_first:f_last)] = webcam_interpl(Rm, Gm, Bm, w_timestamp, first, last, update_Fs, 80);
                    window_size = 1;
                end
                
                s_chrom(f_first:f_last) = chrom_method(Ri(f_first:f_last), Gi(f_first:f_last), Bi(f_first:f_last), a_BPF40220, b_BPF40220);
                % update ppg
                s_ppg(sec) = update_ppg(s_chrom(f_first:f_last));
                
                % Round pulse rate to nearest int and convert 2 string
                bpm = num2str(round(s_ppg(sec)));  

                w_timestamp(first) = w_timestamp(first) + Fs_time;
                f_first = f_first + Fs;
                f_last = f_last + Fs;
                test = test + Fs;
                first = first + (last-first) +1; 
                sec = sec +1;
            end
            % Insert face found msg
            videoFrame = insertText(videoFrame, face_pos, face_str, 'FontSize', 10, 'BoxColor', 'green', 'BoxOpacity', 0.4, 'TextColor', 'white');
        else
            % Insert no face found msg
            videoFrame = insertText(videoFrame, no_face_pos, no_face_str, 'FontSize', 12, 'BoxColor', 'red', 'BoxOpacity', 0.4, 'TextColor', 'white');
        end

        % Insert pulse rate in img.
        videoFrame = insertText(videoFrame, bpm_position, strcat(bpm,'/bmp'), 'FontSize', bpm_front_size, 'BoxColor', bpm_box_color, 'BoxOpacity' ,0.4 ,'TextColor', bpm_text_color);
        % Insert FPS in img.
        videoFrame = insertText(videoFrame, fps_position, round(fps), 'FontSize', bpm_front_size, 'BoxColor', fps_box_color, 'BoxOpacity' ,0.4 ,'TextColor', bpm_text_color);
        
        if plot == 'y'
            plot_realtime_ppg(s_ppg, sec);
        end

        % Display the annotated video frame using the video player object.
        step(videoPlayer, videoFrame);

        % Check whether the video player window has been closed.
        runLoop = isOpen(videoPlayer);

        last = last +1;
    end

    % Clean up.
    clear cam;
    release(videoPlayer);
    release(pointTracker);
    release(faceDetector);
    
    ppg = s_ppg(1:sec-1);
    chrom = s_chrom(1:f_last-Fs);
end

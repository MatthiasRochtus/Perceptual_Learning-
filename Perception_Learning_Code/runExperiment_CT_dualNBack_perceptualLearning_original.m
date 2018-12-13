function runExperiment_CT_dualNBack( subjectName, debug )
%cognitive training for young healthy subjects
addpath('EOG');
addpath('LPT');
addpath('Util');

%% Initialization
nbStimuliPerSequence = 100;
nbImageTargetsPerSequence = 25;
% nbSoundTargetsPerSequence = 10;
nbArrowTargetsPerSequence = 10;
maxNbImages = 42;
% maxNbSounds = 26;
maxNbArrow = 1;
stimulusDuration = 1; % in seconds
interstimulusInterval = 2; % in seconds

% Size of the stimulus
stimulusSize = 250;
% N-back tasks per iteration (for both)
tasks = [1 2 3];
% Nb of times the N-back tasks (above) are repeated
nbSessions = 1;

%Load Arrow image
arrow = imread("Resources/BlackArrow.png");
% Load pictures
pictureNames = dir('Pictures/Pictures/*.png');
% Remove unwanted ones
mask = zeros(1, numel(pictureNames));
for i = 1 : numel(pictureNames)
    if ~isempty(regexp(pictureNames(i).name, '._\w*', 'once'))
        mask(i) = 1;
    end
end
pictureNames = pictureNames(mask==0);


% soundNames = soundNames(mask==0);

% Load sounds
% soundNames   = dir('Sounds/*.wav');
% Remove unwanted ones
% mask = zeros(1, numel(soundNames));
% for i = 1 : numel(soundNames)
% if ~isempty(regexp(soundNames(i).name, '._\w*', 'once'))
% mask(i) = 1;
%         end
% end
% soundNames = soundNames(mask==0);

% Check if the folder where we will store the results exists.
% If not, make the folder
resultFolder = sprintf('Logfiles/%s', subjectName);
if ~exist(resultFolder, 'dir')
    mkdir(resultFolder);
end

% Prepare for sending markers
if debug
    ArrowImage = 0;
    %    lptIoPort = 0;
else
    %    lptIoPort = getLPTportIOAddress();
    ArrowImage = 1;
end


%Prepare for audio stimuli
% if debug
%    ioPort = -1;
% else
%    ioPort = getLPTportIOAddress();
% end


% Prepare for psychtoolbox
AssertOpenGL;
defaultPriority = Priority();

try
    Screen( 'Preference', 'Verbosity', 0 );
    Screen( 'Preference', 'SkipSyncTests', 0 );
    Screen( 'Preference', 'VisualDebugLevel', 0 );
    
    % Init
    screen_number = max(Screen('Screens'));
    
    %EOG calibration
    %         if debug
    %             eog_calibration(30, [], screen_number, 'en');
    %         else
    %             eog_calibration(30, 'LPT1', screen_number, 'en');
    %         end
    
    % Open a window
    [window, screenRect] = Screen('OpenWindow', screen_number,1);
    % Get the index for a white color
    white = WhiteIndex(window);
    
    % Set the font and size to use for the text
    Screen( 'TextFont', window, 'Helvetica');
    Screen( 'TextSize', window, 40);
    
    % Find the center of the screen
    centerX = (screenRect(1) + screenRect(3)) / 2;
    centerY = (screenRect(2) + screenRect(4)) / 2;
    
    % Open the audio
    % InitializePsychSound;
    % audio = PsychPortAudio('Open', [], [], 3, 8000);
    
    % Define the response keys
    imageKey = KbName('l');
    arrowKey = KbName('a');
    validKeys = zeros(1,256);
    validKeys([imageKey, arrowKey]) = 1;
    
    % Define the rectangle in which all pictures will be shown
    stimulusRect1 = [centerX-stimulusSize/2, ...
        centerY-stimulusSize/2, ...
        centerX+stimulusSize/2, ...
        centerY+stimulusSize/2];
    
    stimulusRect2 = [centerX-stimulusSize/2, ...
            centerY-stimulusSize, ...
            centerX+stimulusSize/2, ...
            centerY+stimulusSize];
        
    % initialize logger for conditions
    first_digit = 0; %represents N-back task (should be 1 for 1-back task, 2 for 2-back task, and so on)
    second_digit = 0; %represents target/non-target (should be 1 for target, 2 for non-target)
    third_digit = 0; %represents the conditions with target and arrow (can be from 1 to 4, representing each condition)
    
    % Load the images in memory
    textures = cell(1,numel(pictureNames));
    for i = 1 : maxNbImages
        filename = sprintf('Pictures/Pictures/%s',pictureNames(i).name);

        %%
        % add arrow images
        random_number = randi(100); %initialize random number
        %condition 1
        if random_number<=10 %condition 1: target with the arrow (10%)
            original_image = imread(filename); %read image from Pictures folder
            resized_arrow_image = imresize(arrow,[size(original_image,1) size(original_image,2)]); %resize arrow image to the size of orig_Picture
            combined_image = [original_image; resized_arrow_image]; %picture and arrow displaying at the same time
            second_digit = 1; %target
            third_digit = 1; %condition 1

        %condition 2
        elseif random_number>10 && random_number<=20 %condition 2: target with no arrow (10%)
            original_image = imread(filename); %read image from Pictures folder
            combined_image = original_image; %just return image without arrow
            second_digit = 1; %target
            third_digit = 2; %condition 2
            
        %condition 3
        elseif random_number>20 && random_number<=60 %condition 3: non target with the arrow (40%)
            original_image = imread(filename); %read image from Pictures folder
            resized_arrow_image = imresize(arrow,[size(original_image,1) size(original_image,2)]); %resize arrow image to the size of orig_Picture
            combined_image = [original_image; resized_arrow_image]; %picture and arrow displaying at the same time
            second_digit = 2; %non-target
            third_digit = 3; %condition 2
            
        %condition 4
        elseif random_number>60 && random_number<=100 %condition 4: non target with no arrow (40%)
            original_image = imread(filename); %read image from Pictures folder
            combined_image = original_image; %just return image without arrow
            second_digit = 2; %non-target
            third_digit = 4; %condition 2
            
        end
        %%  
%         texture = Screen('MakeTexture', window, imread(filename));
        texture = Screen('MakeTexture', window, combined_image);
        textures{i}.data = texture;
        textures{i}.name = pictureNames(i).name;
        textures{i}.info = [second_digit, third_digit];
    end
    crossTexture = Screen('MakeTexture', window, imread('Resources/BlackCross.png'));
    
    %         Load the sounds in memory
    %         sounds = cell(1, numel(soundNames));
    %         for i = 1 : maxNbSounds
    %            filename = sprintf('Sounds/%s',soundNames(i).name);
    %            [y,~] = audioread(filename);
    %            wavedata = y';
    %            nrchannels = size(wavedata,1);
    %            if nrchannels < 2
    %                wavedata = [wavedata ; wavedata];
    %            end
    %           sounds{i}.data = wavedata;
    %           sounds{i}.name = soundNames(i).name;
    %         end
    
    % Loop over the iterations (for both tasks)
    for it = 2 : nbSessions+1
        %             if it ~= 1
        %                 text = 'Break... \n\n Press a key to continue';
        %                 DrawFormattedText(window, text, 'center', 'center', white);
        %                 Screen('Flip', window);
        %
        %                 % Wait until the subject presses a key
        %                 KbPressWait();
        %             end
        
        % Randomize the tasks (if needed)
        backs = [1 1 2 2 3 3];
        
        % Loop over the N-back tasks (for both tasks)
        for whichBack = 1 : numel(backs)
            %% Preparation of the trial
            
            % Get the current N
            N = backs(whichBack);
            first_digit = N; %representing the N-back task
            
            % Initialize the log file
            Log = Logger(sprintf('%s/%d-back_%d.txt', resultFolder, N, it-1), false, true);
            
            %                 if it == 1
            %                     % If first iteration (i.e., training sequences), use the
            %                     % sequences defined below
            %                     if N == 1
            %                         sequenceIdc = [1 5 5 2 3 3 6 5 4 4];
            %                     elseif N == 2
            %                         sequenceIdc = [4 5 4 2 3 2 3 1 2 2];
            %                     elseif N == 3
            %                         sequenceIdc = [2 3 1 4 3 6 4 1 3 4];
            %                     end
            %                     sequence = textures(sequenceIdc);
            %                 else
            sequencePictures = calculateSequence(N, nbStimuliPerSequence, nbImageTargetsPerSequence, textures);
            %                   sequenceAudio = calculateSequence(N, nbStimuliPerSequence, nbSoundTargetsPerSequence, sounds);
%             sequenceArrow = calculateSequence(N, nbStimuliPerSequence, nbArrowTargetsPerSequence, sounds);
            %                 end
            
            %% Displaying the sequence
            
            % Draw the instruction and Flip the window
            text = sprintf('Press the spacebar if the current image is the same as \n %d \n image(s) ago.\n\nPress a key to start the trial...', N);
            DrawFormattedText(window, text, 'center', 'center', white);
            Screen('Flip', window);
            
            % Wait until the subject presses a key
            KbPressWait();
            
            % Draw the cross & Flip the window
            Screen('DrawTexture', window, crossTexture, [], stimulusRect1);
            Screen('Flip', window);
            
            % Wait 2 seconds
            WaitSecs(2);
            
            for i = 1 : numel(sequencePictures)
                % Check if the image that will be displayed is should have been pressed
                if i <= N
                    shouldPressImage = false;
                    shouldPressArrow = false;
                    %  shouldPressSound = false;
                    marker = 4+10*N;
                else
                    shouldPressImage = isequaln(sequencePictures{i}, sequencePictures{i-N});
                    shouldPressArrow = true;
%                     shouldPressArrow = isequaln(sequenceArrow{i}, sequenceArrow{i-N});
%                     shouldPressArrow = isequaln(sequenceArrow{i}, sequenceArrow{i-N});
                    %  shouldPressSound = isequaln(sequenceAudio{i}, sequenceAudio{i-N});
                    %  if shouldPressImage && shouldPressSound
                    if shouldPressImage && shouldPressArrow
                        marker = 3+10*N;
                    elseif shouldPressImage
                        marker = 1+10*N;
                    % elseif shouldPressSound
                    elseif shouldPressArrow
                        marker = 2+10*N;
                    else
                        marker = 4+10*N;
                    end
                end
                
                onset = GetSecs() + 0.5;
                
                % Play the sound (perhaps)
                %                     play_sound = false;
                %                     sound_chance = 0.33; % 33% chance of playing the sound
                %                     if marker == 11 || marker == 21 || marker == 31  % check label if this is the target stimulus
                %                       random_draw = rand(); % takes random number from 0 to 1
                %                       if random_draw < sound_chance
                %                           play_sound = true;
                %                         end
                %                     end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % RUN THIS IF YOU NEED THREE OPTIONS: silence, low
                % tone, high tone
                %                     which_sound_to_play = 0; % 0 - silence, 1 - high tone, 2 - low tone
                %                     silence_chance = 0.33;
                %                     high_tone_chance = 0.5;
                %                     if marker == 11 || marker == 21 || marker == 31
                %                         random_draw = rand();
                %                         if random_draw < silence_chance
                %                             which_sound_to_play = 0;
                %                         elseif random_draw < (silence_chance + high_tone_chance)
                %                             which_sound_to_play = 1;
                %                         else
                %                             which_sound_to_play = 2;
                %                         end
                %                     end
                %
                %                     if which_sound_to_play == 1
                %                         PsychPortAudio('FillBuffer', audio, filename_of_high_sound);
                %                         PsychPortAudio('Start', audio, 1, onset, 1);
                %                     elseif which_sound_to_play == 2
                %                         PsychPortAudio('FillBuffer', audio, filename_of_low_sound);
                %                         PsychPortAudio('Start', audio, 1, onset, 1);
                %                     end
                
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                % if play_sound == true
                %     PsychPortAudio('FillBuffer', audio, sequenceAudio{i}.data);
                %     PsychPortAudio('Start', audio, 1, onset, 1);
                % end
                
                %get the second and the third digit for the marker sequence
                digits = sequencePictures{i}.info; %digits contains (target/non-target, condition for arrow)
                
                % Draw the stimulus & Flip the window
                if digits(2)==1 || digits(2)==3
                    Screen('DrawTexture', window, sequencePictures{i}.data, [], stimulusRect2);
                else
                    Screen('DrawTexture', window, sequencePictures{i}.data, [], stimulusRect1);
                end
                Screen('Flip', window, onset);
                
                % Send the marker and log the image
                % markEvent(lptIoPort, marker);
                markEvent (ArrowImage, marker);
                Log.log(sprintf('Showing image : %s', sequencePictures{i}.name));

                %log for the 3-digit marker
                Log.log(sprintf('Markers: %s', strcat(num2str(first_digit),num2str(digits(1)),num2str(digits(2)))));
                
                
                if digits(2)==1 || digits(2)==3
%                 if show_arrow == true
                    %   Log.log(sprintf('Playing sound : %s', sequenceAudio{i}.name));
                    Log.log(sprintf('Showing Arrow : Yes'));
                else
                    Log.log(sprintf('Showing Arrow : No'));
                end
                % Show it for two seconds
                WaitSecs(stimulusDuration);
                
                % Draw the cross & Flip the window
                Screen('DrawTexture', window, crossTexture, [], stimulusRect1);
                [~,~,crossTime] = Screen('Flip', window);
                
                %if play_sound == true
                %    PsychPortAudio('Stop', audio);
                %end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % IF I USE THE THREE OPTIONS
                %                     if  which_sound_to_play == 1 || which_sound_to_play == 2
                %                         PsychPortAudio('Stop', audio);
                %                     end
                %
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                % Define how long the ISI should be
                jitter = (rand()*0.2)-0.1;
                maxWaitTime = GetSecs() + interstimulusInterval + jitter;
                
                %didPressSound = false;
                didPressArrow = false;
                ArrowRT = 0;
                % soundRT = 0;
                didPressImage = false;
                imageRT = 0;
                % while ~(didPressSound && didPressImage) && (GetSecs() <= maxWaitTime)
                while ~(didPressArrow && didPressImage) && (GetSecs()<= maxWaitTime)
                    [~, sec, keycode] = KbCheck([], validKeys);
                    reactionTime = sec - crossTime;
                    %if ~didPressSound && keycode(arrowKey)
                    %didPressSound = true;
                    %soundRT = reactionTime;
                    
                    if ~didPressArrow && keycode(arrowKey)
                        didPressArrow = true;
                        ArrowRT = reactionTime;
                        
                    elseif ~didPressImage && keycode(imageKey)
                        didPressImage = true;
                        imageRT = reactionTime;
                    end
                    
                    % Draw feedback
                    %if didPressSound && didPressImage
                    if didPressArrow && didPressImage
                        Screen('DrawTexture', window, crossTexture, [], stimulusRect1,[],[],[],[65 131 215]);
                    elseif didPressImage
                        Screen('DrawTexture', window, crossTexture, [], stimulusRect1,[],[],[],[65 131 215]);
                    elseif didPressArrow
                        %elseif didPressSound
                        Screen('DrawTexture', window, crossTexture, [], stimulusRect1,[],[],[],[65 131 215]);
                    else
                        Screen('DrawTexture', window, crossTexture, [], stimulusRect1,[],[],[],[255 255 255]);
                    end
                    Screen('Flip', window);
                end
                
                % Log image response
                if didPressImage
                    Log.log(sprintf('Image key pressed? : Yes (ReactionTime : %.3f)', imageRT));
                else
                    Log.log('Image key pressed? : No');
                end
                if shouldPressImage && didPressImage || ~shouldPressImage && ~didPressImage
                    Log.log('Correct image response? : Yes');
                else
                    Log.log('Correct image response? : No');
                end
                % Log sound response
                %                     if didPressSound
                %                         Log.log(sprintf('Sounds key pressed? : Yes (ReactionTime : %.3f)', soundRT));
                %                     else
                %                         Log.log('Sound key pressed? : No');
                %                     end
                %                     if shouldPressSound && didPressSound || ~shouldPressSound && ~didPressSound
                %                         Log.log('Correct sound response? : Yes');
                %                     else
                %                         Log.log('Correct sound response? : No');
                %                     end
                %                     Log.log('--------------');
                %
                % Wait the rest of the isi
                WaitSecs(maxWaitTime - sec);
            end
            
            % Let the subject know the trial is over
            DrawFormattedText(window, 'This is the end of the current trial', 'center', 'center', white);
            Screen('Flip', window);
            
            % Wait 10 seconds
            WaitSecs(10);
        end
    end
    
    % All done!
catch Exception
    if exist('audio', 'var')
        PsychPortAudio('Close', audio);
    end
    Priority(defaultPriority);
    sca;
    rethrow(Exception);
end
if exist('audio', 'var')
    PsychPortAudio('Close', audio);
end
Priority(defaultPriority);
sca;
end

function sequence = calculateSequence(N, length, nbTargets, textures)
% Randomize the textures (pictures)
textures = textures(randperm(numel(textures)));
% First six will be used as target
targetTextures = textures(1:6);
% The rest as filler images
nonTargetTextures = textures(7:end);

% Initialize the sequence
sequence = cell(1, length);
for t = 1  : nbTargets
    idx = 0;
    while idx <= N || ~isempty(sequence{idx})
        idx = randi(length);
    end
    
    if isempty(sequence{idx-N})
        % Choose random target texture
        targetTexture = targetTextures{randi(6)};
        sequence{idx} = targetTexture;
        sequence{idx-N} = targetTexture;
    else
        sequence{idx} = sequence{idx-N};
    end
end

%% Fill in the empty slots with filler non-targets
for s = 1 : numel(sequence)
    if isempty(sequence{s})
        nontargetTexture = nonTargetTextures{randi(numel(nonTargetTextures))};
        while s > N && isequaln(sequence{s-N}, nontargetTexture)
            nontargetTexture = nonTargetTextures{randi(numel(nonTargetTextures))};
        end
        sequence{s} = nontargetTexture;
    end
end
end

function markEvent(lptIoPort, marker)
if ~lptIoPort
    fprintf('Marker sent : %d\n', marker);
else
    lptwriteNeuroscan(lptIoPort, marker);
end
end

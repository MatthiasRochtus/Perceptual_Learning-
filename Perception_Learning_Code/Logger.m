classdef Logger < handle
    %LOGGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        timestampFormat = '[%04g-%02g-%02g-%02g-%02g-%06.3f] ';
    end
    
    properties
        filename;
        logToScreen;
        logToFile;
    end
    
    methods
        function this = Logger(filename, logToScreen, logToFile)
            this.filename = filename;
            if nargin < 2
                this.logToScreen = true;
            else
                this.logToScreen = logToScreen;
            end
            
            if nargin < 3
                this.logToFile = true;
            else
                this.logToFile = logToFile;
            end
        end
        
        function log(this, message)
            timestampString = sprintf(this.timestampFormat, clock());
            logLine = sprintf('%s %s \n',timestampString, message);
        
            if this.logToFile,
                logFile = fopen(this.filename, 'A');
                fwrite(logFile, logLine);
                fclose(logFile);
            end

            if this.logToScreen,
                fwrite( 1, logLine );
            end
        end
    end
    
end


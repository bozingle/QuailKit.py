classdef JR_Data
    %UNTITLED3 Summary of this class goes here
    %To invoke the constructor:
    %   obj = JR_Data(fileDir+fileName+audio extension(i.e ".wav"))
    % To retrieve intervals of time from memory
    %   obj.get(first, last)
    %first and last are in seconds. Any interval works.
    %first - the start of the interval to load from memory.
    %last - the end of the interval to load from memory.
    
    properties
        scale
        progress
        audiofs
        spgramfs
        filepath
        finalTimeAudio
        finalTimeSpgram
    end
    
    methods
        function obj = JR_Data(filepath, recording)
            obj.filepath = filepath+erase(recording,".wav")+".h5";%Location where the processed file should be.
            if exist(obj.filepath)
                stuff = h5info(obj.filepath, '/spgram');
                attVals = h5readatt(obj.filepath, '/spgram', 'props');
                obj.spgramfs = attVals(1);
                obj.finalTimeSpgram = attVals(2);
                obj.scale = attVals(5);
                attVals = h5readatt(obj.filepath, '/audio', 'audiofs');
                obj.audiofs = attVals(1);
            else
                obj.finalTimeSpgram = 0;
                obj.scale = 0.8;
                [obj,raw]=obj.read(recording);
                audio = obj.process(raw);
                obj = obj.sp(audio, 40, [0:10:10000]);
                h5create(obj.filepath, '/raw', [length(raw(:,1)) length(raw(1,:))]);
                h5write(obj.filepath, '/raw', raw);
                obj = obj.formatAudio(audio);
            end
        end
        
        function [obj,raw]=read(obj,recording)
            filepath = "..\..\..\Quail Call - Recordings\"+recording; %"..\..\..\Quail Call - Recordings\"+
            [raw,obj.audiofs]=audioread(filepath);
        end
        
        function audio = process(obj,raw)
            audio(1:size(raw,1))=zscore(raw(:,1));
        end
        
        function obj = formatAudio(obj, audio)
            audio = audio';
            h5create(obj.filepath, '/audio', [length(audio(:,1)) length(audio(1,:))]);
            h5writeatt(obj.filepath, '/audio', "audiofs", obj.audiofs);
            h5write(obj.filepath, '/audio', audio);
        end
        
        function obj = sp(obj, audio, seconds, f)
            noverlap = (round(0.8*0.1*obj.scale*obj.audiofs));
            mult = seconds*obj.audiofs;%multiplier needed to get 40s intervals
            window = round(0.1*obj.scale*obj.audiofs);
            audioLength = length(audio);
            obj.progress = 0;
            disp("Processing spectrogram");
            tfinal = [];
            for i = mult:mult:audioLength
                [s,~,t] = spectrogram(audio((i-mult+1):i),window,...
                    noverlap,f,obj.audiofs);
                tother = (i-mult+1)/obj.audiofs:1/(obj.audiofs):i/obj.audiofs;
                tfinal = [tfinal; t' + obj.finalTimeSpgram];
                spgramA = db(abs(s'));
                if ~exist(obj.filepath)
                    obj.spgramfs = 1/abs(t(1) - t(2));
                    h5create(obj.filepath, '/spgram', [inf length(spgramA(1,:))], 'ChunkSize', [length(spgramA(:,1)) length(spgramA(1,:))]);
                    Size = h5info(obj.filepath, '/spgram');
                    Size = Size.Dataspace.Size;
                end
                h5write(obj.filepath, '/spgram', spgramA,[Size(1)+1 1], [length(spgramA(:,1)) length(spgramA(1,:))]);
                Size(1) = Size(1) + length(spgramA(:,1));
                disp("Progress: " + obj.progress + "%");
                obj.progress = round((i/audioLength)*10000)/100;
                obj.finalTimeSpgram = t(end);
            end
            h5writeatt(obj.filepath, '/spgram', 'props', [obj.spgramfs obj.finalTimeSpgram f(1) f(end) obj.scale]);
            disp("Complete!");
        end
        
        function [s,t] = get(obj, first, last, propertyType)
            startIn = 0;
            endIn = 0;
            s = [];
            t = [];
            if propertyType == "spgram"
                Size = h5info(obj.filepath, '/spgram');
                Size = Size.Dataspace.Size;
                startIn = first*obj.spgramfs + 1;
                endIn = last*obj.spgramfs-startIn+1;
                spgram = h5read(obj.filepath, '/spgram', [startIn 1], [endIn Size(2)]);
                t = (first:1/obj.spgramfs:last)';
                t = t(1:length(spgram(:,1)));
                s = spgram;
            elseif propertyType == "audio"
                Size = h5info(obj.filepath, '/audio');
                Size = Size.Dataspace.Size;
                startIn = first*obj.audiofs + 1;
                endIn = last*obj.audiofs-startIn+1;
                audio = h5read(obj.filepath, '/audio', [startIn 1], [endIn Size(2)]);
                t = (first:1/obj.audiofs:last)';
                t = t(1:length(audio(:,1)));
                s = audio;
            else
                error("Incorrect propertyType:"+newline+char(9)+"The propertyType "+propertyType+" does not correspond with the existing ones: spgram and audio.");
            end
        end
        
        function display(obj,graphics,interval)
           % set(graphics.axis_audio,...
           %     'XData', obj.audio.,...
           %     'YData', obj.audio.)
           % set(graphics.axis_spectrogram,...
           %     'XData', obj.spectrogram.,...
           %     'YData', obj.spectrogram.,...
           %     'ZData', obj.spectrogram.)
        end
    end
end

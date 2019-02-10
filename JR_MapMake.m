classdef JR_MapMake
    %JR_MAPMAKE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        results
        window
        filepath
        distance
        lonlim
        latlim
    end
    
    methods
        
        function obj = JR_MapMake(date)
            obj.filepath = ""+"MapMakeObj_"+replace(date, "/", "_");%Location where the processed file should be.
            if exist(obj.filepath)
                fileObj = load(obj.filepath+"/mapDet_"+replace(date, "/", "_")+".mat");
                obj = fileObj.obj;
            else
                addpath("C:\Users\jreznick\Texas Tech University\Quail Call - Joel\QuailKit\HT_QuailKit");
                mkdir(obj.filepath);
                obj.results = HT_DataAccess([],'query',...
                "SELECT [Activity(s)].[DateTime], [Activity(s)].[Seconds], [Activity(s)].[Latitude], [Activity(s)].[Longitude]"+...
                "FROM [Activity(s)]"+...
                "WHERE ((([Activity(s)].[DateTime])>#"+date+"#));", 'numeric');

                save(obj.filepath+"/mapDet_"+replace(date, "/", "_")+".mat", "obj");
            end
        end
        
        function obj = mapMake(obj, distance, unit, key)
            obj.distance = distance;%5 mile radius
            R = 1;
            if unit == 'miles'
                R = 3959;
            elseif unit == 'meters'
                R = 6.3781*(10.^6);
            elseif unit == 'kilometers'
                R = 6.3781*(10.^3);
            end
            
            %Find max long min long
            meanLong =  mean(obj.results(:,4));
            obj.lonlim = [meanLong - rad2deg(obj.distance/R) meanLong + rad2deg(obj.distance/R)];
            
            %Find max lat min lat
            meanLat = mean(obj.results(:,3));
            obj.latlim = [meanLat - rad2deg(obj.distance/R) meanLat + rad2deg(obj.distance/R)];
            
            hold on;
            Figure('Name', 'Display Data: lon('+obj.lonlim(1) +', '+obj.lonlim(2)+') lat('+obj.latlim(1) + ', '+obj.latlim(2)+")");
            plot(obj.results(:,4)', obj.results(:,3)' , '.r', 'MarkerSize', 20);
            
            %Zohar Bar-Yehuda's Static Google Maps API
            plot_google_map('MapScale', 1, 'maptype', 'satellite', 'showLabels', 0, 'APIKey', key, 'AutoAxis', 1);
            hold off;
        end
        
        function obj = newmapMake(obj,distance,unit)
            
            obj.distance = distance;
            R = 1;
            if unit == 'miles'
                R = 3959;%Radius of the earth in miles
            elseif unit == 'meters'
                R = 6.3781*(10.^6);
            elseif unit == 'kilometers'
                R = 6.3781*(10.^3);
            end
            
            
            %Find max long min long
            meanLong =  mean(obj.results(:,4));
            obj.lonlim = [meanLong - rad2deg(obj.distance/R) meanLong + rad2deg(obj.distance/R)];
            
            %Find max lat min lat
            meanLat = mean(obj.results(:,3));
            obj.latlim = [meanLat - rad2deg(obj.distance/R) meanLat + rad2deg(obj.distance/R)];
            
            webmap('World Imagery', 'WrapAround', true);
            %Display results
            wmmarker(obj.results(:,3), obj.results(:,4));
            wmlimits(obj.latlim, obj.lonlim);
            
            %geoshow(obj.results(:,3), obj.results(:,4), 'DisplayType', 'multipoint', 'Marker', '.', 'Color', 'red');
         
        end
    end
end

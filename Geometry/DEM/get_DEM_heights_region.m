function [lats,lons,elevations,meta] = get_DEM_heights_region(LL, UR, varargin)
% GET_DEM_HEIGHTS_REGION Loads DEM data covering the specified region.
%
% The input region is indicated via the lower -left (LL) and upper-right
% (UR) points.
%
% Inputs:
%       LL  A two-vector of latitude, longitude (in degrees) of the
%           lower-left corner of the region to load.
%       UR  A two-vector of latitude, longitude (in degrees) of the
%           upper-right corner of the region to load.
%
% Returns:
%       lats       Vector of grid latitude values (in degrees) at which 
%                  DEM data is available.
%       lons       Vector of grid longitude values (in degrees) at which 
%                  DEM data is available.
%       elevations The elevation grid giving the elevation (MSL if
%                  correctUndulation is false, HAE if correctUndulation is
%                  true) at the corresponding lat,lon point.
%       meta       Supporting meta data extracted from the DTED file(s).
%
% Allowed properties:
%       Property name         Description
%       -----------------------------------------------------------------
%        defaultDEMDirectory  The directory root in which DEM (DTED) files
%                             reside.
%        correctUndulation    A boolean indicating if the DEM data should
%                             have the geoid unduilation correction
%                             applied.
%        useHiRes             If a file name is not provided via the
%                             undulationFilename parameter a default will be
%                             used.  The default is the "low resolution"
%                             2.5x2.5 minute grid.  If the useHiRes parameter
%                             is set to true, however, the higher-resolution
%                             1x1 minute grid will be used.
%
% Written by: Tom Krauss, NGA/IDT
%
% //////////////////////////////////////////
% /// CLASSIFICATION: UNCLASSIFIED       ///
% //////////////////////////////////////////

%% Set up a few default values and/or use the values passed in by the caller.
if exist('defaultDEMDirectory', 'file')
  DEMBaseDir = defaultDEMDirectory;
else
  DEMBaseDir = '';
end
p = inputParser;
p.KeepUnmatched = true;
p.addParamValue('defaultDEMDirectory', DEMBaseDir);
p.addParamValue('correctUndulation', false);
p.addParamValue('useHiRes', false);
p.parse(varargin{:});

%PJC 2014-05-21 fixed input bug
DEMBaseDir = p.Results.defaultDEMDirectory;

%% If area spans multiple DEM files, setup array to describe each file
lat_steps=floor(LL(1)):floor(UR(1));
lon_steps=floor(LL(2)):floor(UR(2));
DEMfilename=cell(length(lon_steps),length(lat_steps));
elevations=cell(size(DEMfilename));
lats=cell(size(DEMfilename));
lons=cell(size(DEMfilename));
meta=cell(size(DEMfilename));
for lat_index=1:length(lat_steps)
    for lon_index=1:length(lon_steps)
        % Predict DEM filename in keeping with NGA standard naming convention
        if lat_steps(lat_index) < 0, lat_dir = 's';
        else                         lat_dir = 'n';
        end
        if lon_steps(lon_index) < 0, lon_dir = 'w';
        else                         lon_dir = 'e';
        end
        DEMfilename{lon_index,lat_index} = ...
            sprintf('%s/dted/%c%03d/%c%02d.dt2', DEMBaseDir, ...
                    lon_dir, abs(floor(lon_steps(lon_index))), ...
                    lat_dir, abs(floor(lat_steps(lat_index))) );
        if ~exist(DEMfilename{lon_index,lat_index},'file')
            % The DTED file doesn't exist.
            error('GET_DEM_HEIGHT:DEM_FILE_NOT_FOUND',...
                'DTED file not found in DEMBaseDir.  Pass base directory explicitly with the ''DEMBaseDir'' input parameter, or create a function ''defaultDEMDirectory'' to return the desired path.');
        end
        % Read DTED file
        local_LL=max(LL,[lat_steps(lat_index) lon_steps(lon_index)]);
        local_UR=min(UR,[lat_steps(lat_index) lon_steps(lon_index)]+1-eps(180)); % Eps avoids integer lat/lons which could occur in multiple DEM files
        [elevations{lon_index,lat_index}, lats{lon_index,lat_index}, lons{lon_index,lat_index}, meta{lon_index,lat_index}] =...
            read_DTED(DEMfilename{lon_index,lat_index}, local_LL, local_UR);
    end
end
elevations=cell2mat(elevations);
lats=[lats{1,:}];
lons=[lons{:,1}];
if length(meta)==1, meta=meta{1}; end; % Remove cell array wrapper for single file

%% Compensate for geoid undulation
if (p.Results.correctUndulation)
    for iii=1:length(lons)
        for jjj=1:length(lats)
            undulation = geoid_undulation(lats(jjj), ...
                                          lons(iii), ...
                                          'useHiRes', p.Results.useHiRes);
            elevations(iii,jjj) = elevations(iii,jjj) + undulation;
        end
    end
end

end
% //////////////////////////////////////////
% /// CLASSIFICATION: UNCLASSIFIED       ///
% //////////////////////////////////////////
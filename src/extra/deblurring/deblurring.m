
%{
output_folder = '/Users/rodrigo/Documents/tfg/cities/data/raw/NTL/deblurred_ntl_lights';
light_files = dir('/Users/rodrigo/Documents/tfg/cities/data/raw/NTL/nlt_lights/*.tif');
pct_files   = dir('/Users/rodrigo/Documents/tfg/cities/data/raw/NTL/avg_lights_x_pct/*.tif'); % change this to pct files

nfiles = length(light_files); % same as pct_files in theory


for i=1:1
   blurred_image_pathname = fullfile(light_files(i).folder, light_files(i).name);
   blurred_image_perc_pathname = fullfile(pct_files(i).folder, pct_files(i).name);
   name = strcat('deblurred_' , light_files(i).name(2:7), '.tif');
   deblurred_image_pathname = fullfile(output_folder, name);
    
   %deblur_ntl_image(output_folder, 7, 0, blurred_image_pathname, blurred_image_perc_pathname, deblurred_image_pathname);
end


%}

deblur_ntl_image('/Users/rodrigo/Documents/tfg/cities/data/raw/NTL/', 6, 0, '/Users/rodrigo/Documents/tfg/cities/data/raw/NTL/spain.tif', '/Users/rodrigo/Documents/tfg/cities/data/raw/NTL/spain_pct.tif', '/Users/rodrigo/Documents/tfg/cities/data/raw/NTL/deblurred_spain.tif');



%%read in geometry of SD7003 airfoil with cordLength = 1.0
geo = fullfile('SD7003',...
    'geo','SD7003.dat');

load(geo,'-ascii');

mat.x=SD7003(:,1);
mat.y=SD7003(:,2);
%%
sortcolumn = 2;

UQSD7003_Mean = GenericloadPWC_Research('NumerData','UQSD7003_Mean','csv',sortcolumn);


fn_UQSD7003_Mean = fieldnames(UQSD7003_Mean);
disp(newline);

fn_count = cell(1,length(fn_UQSD7003_Mean));
for pp = 1:length(fn_UQSD7003_Mean)
    fn_count{pp} =  pp;
    fn_count = fn_count(:);%must be the same shape as "fn_UQSD7003_cfcp"
    
end
%%

%       User needs to properly set 
%       show_UQ_ranges = on/off     to turn on/off UQ evenlopes
%       Manual_repeat = on/off      to deal with single-position or multiple
%                                   multiple-position curves

%           Baseline_manual_on  = [n1 n2 n3 ...]; Baseline profile indices
%           Baseline_manual_off = n;    Baseline profile index 
%       
%       split                       to deal with particular geometry like 
%                                   airfoils


%Note "NumOfdataSets" is an important user-defined parameter! It means the
%number of profiles per case, e.g. cf or cp has only one curve each case
%(different cases: DNS, Exp, RANS). Not # of cases! If "NumOfdataSets = 1"
%it means single-curve cases, e.g. cf and cp. For velocity profiles, always
%multiple-curve cases are encountered, e.g. 5 positions on the geometry
%each case. In that way, "NumOfdataSets = 5".
%NumOfdataSets MUST be > 1. Cannot be = 0 or negative!!

%*************** May 15th 2021 ********************************************



%*****Wall shear stress data read in
%The order that the velocities appear should follow the order of expression
%e.g. 5.4 corresponds to Tu33, 5.18 corresponds to Tu42.


%AoA = 8;
%AoArad = AoA*pi/180;

%Flow properites
Den              = 1.17637;
DynamicVis       = 1.83e-5;

Ufree_DNS        = 0.2;
Ufree_UQSD7003   = 4.5;

%Geometry
CFD_cordLength   = 0.2; % cord length of CFD geometry
DNS_cordLength   = 1.0; %cord length of DNS geometry
Ref_cordLength   = DNS_cordLength;%Ref_cordLength might be LES or exp

%************ Jun 12 2021 by Minghan Chu Obsolete version left for purpose of learning coding
%style*******
% %********** User inputs **********
% %Note both multipliers below are additional to
% %CFD_geo_factor/Ref_geo_factor! For example you can set those multipliers
% %to unity if you do not put additional effort on the outlook of your plots.
% %But if you feel that your plots need to be enlarged or reduced, then set
% %multipliers > 1 or < 1 respectively!
% 
% hori_multiplier  = 1;%to correct the distance between profiles if they cluster together, i.e. 0.8
% %NorCordLength = cordLength./cordLength;
% verti_multiplier = 1;
% %**********************************
% 
% Ref_cordLength   = DNS_cordLength;%Ref_cordLength might be LES or exp
% geo_ratio        = CFD_cordLength/Ref_cordLength;
% 
% 
% lowercase_hold_geo = 'default';
% 
% if geo_ratio ~= 1.0
% 
%     while isempty (lowercase_hold_geo) == 1 || (strcmp('cfd', lowercase_hold_geo)~=1 && strcmp('ref', lowercase_hold_geo)~=1) 
%         prompt = ['CFD_cordLength: ', num2str(CFD_cordLength), '; Ref_cordLength: ', num2str(Ref_cordLength), '; geo_ratio: ', num2str(geo_ratio)];
%         disp(prompt)
% 
%         prompt = ' Your reference data and CFD data are based on different geometry size, hold CFD geometry unchanged type "cfd" or Reference geometry unchanged "ref":  ';
% 
%         hold_geo = input(prompt, 's');
%         lowercase_hold_geo = lower(hold_geo);
% 
%         switch lowercase_hold_geo
%             case 'cfd'
%                 CFD_geo_factor = 1.0;
%                 Ref_geo_factor = CFD_cordLength/Ref_cordLength;
%                 prompt= ['CFD_geo_factor: ', num2str(CFD_geo_factor), '; Ref_geo_factor: ', num2str(Ref_geo_factor)];
%                 disp(prompt)
%                 break
%             case 'ref'
%                 Ref_geo_factor = 1.0;
%                 CFD_geo_factor = Ref_cordLength/CFD_cordLength;
%                 prompt= ['CFD_geo_factor: ', num2str(CFD_geo_factor), '; Ref_geo_factor: ', num2str(Ref_geo_factor)];
%                 disp(prompt)
%                 break
%         end
% 
%     end
% end
%**********************************************************************




%%

%%%%%%%%%%%%%%%%%%%%% Taking user inputs in this block %%%%%%%%%%%%%%%%%%%%

warning('on')%ensure warning is initially on
fn_index_store = cellfun(@print_fn, fn_count, fn_UQSD7003_Mean,'UniformOutput',false);%fn_count and fn_UQSD7003_cfcp are the first and second inputs respectively, and must be in same size and shape

%Split is used ('yes') when indexing is needed to split two zones, e.g.
%SD7003 has its upper and lower sides and people always want to distinguish
%between them. Most of times only results on the upper side get interested.
Split = 'yes';%or 'yes'



%Manual means if manual manipulations to move positions of the same set of
%data are required. For example, velocity profiles obtained using RANS are
%so packed close to each other, e.g. intersecting with each other, if
%their real positions (usually along streamwise direction) are used. Then
%the user needs to adjust their positions manually to make it clear.

%Note the key word "repeat" indicates a repeating pattern is always
%accompanied by the "Manual" option, e.g. several positions of U or <uv>
%profiles chosen per case. And always manual manipulations are needed. 
%If "show_UQ_ranges = 'on' ", UQ ranges will be shown.
show_UQ_ranges  = 'off';
UQ_CFD_capture  = 'CFD'; %all names of CFD/RANS files share the common part as 'A_CFDwallshear'
                                   %Remember UQ ranges always compare
                                   %perturbed RANS with baseline RANS,
                                   %without any high fidelity data involved
                                   %in comparision. This piece of code is
                                   %added to focus on only RANS comparison
                                   %in plotting UQ ranges.
Manual_repeat   = 'on';

backgroud_plots = true;%true or false (boolean not string!!!): true if only grey-color plots as backgroud are needed! (usually used for marker study to contrast with its fitted curves)

disp(newline)

%%%%%%%%%%%%%%%%%%%%%%%% If user wants to dim/lighten the color of all curves (usually for Marker study), use "backgroud_plots = true" %%%%%%%%%%%%%%%%%%%%%%%%%% 
if backgroud_plots == true
    
     prompt = 'You have chosen "backgroud_plots == true" (Usually backgroud color comes with Marker study). Do you want gray[g] or white[w] for your plots? e.g. type "g" or "w": '; %for now Marker will only be considered when Meanual_repeat = 'off' and
     gray_white = input(prompt, 's');
     lowercase_gray_white = lower(gray_white);

     while isempty(lowercase_gray_white) == 1 || (strcmp('g', lowercase_gray_white) ~=1 && strcmp('w', lowercase_gray_white) ~=1)
         prompt = 'Please type in a valid word: "g/w": ';
         gray_white = input(prompt, 's');
         lowercase_gray_white = lower(gray_white);

     end
     
     if strcmp(lowercase_gray_white,'g')
        backgroud_color_plotting = [0 0 0]+0.6;
     elseif strcmp(lowercase_gray_white,'w')
        backgroud_color_plotting = 'w';
     end

elseif backgroud_plots == false
    warning('You have chosen "backgroud_plots = false " Data will be normally plotted! (No gray or white color will be applied to plotting!)')
    
end


%%%%%%%%%%%%%%%%%%%% manual = 'on' and 'off' %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                  
Multiplier_x_manual_on      = 0.0;%large value means more apart distance between two profiles, often 0.04 or 0.0 for fitting study


shift_y_manual_on           = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];%for no geometry include only and 0s ensure real y positions are used!(usually you do NOT need to change this!) 



disp(newline)

%%%%%%%%%%%%%%%%%%%% manual = 'off' %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%XcaleFactor = 0 on default! for manual = 'off'
YscaleFactor_manual_off_value = zeros(1, length(fn_UQSD7003_Mean)); %New version

for z = 1:length(fn_UQSD7003_Mean)
    YscaleFactor_manual_off_value(z) = 0.0;%zero is used to ensure real y positions are used!
end 


%%%%%%%%%%%%%%%%%%%% manual = 'on' %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!!!!!!! For manual = 'on' the baseline data position indices MUST
%correspond to its name expressions, e.g. [7 6] corresponds to ['\w*25'
%`\w*06`], NOT [7 6] to ['\w*06 \w*25']!!!!!! It does not matter which one
%goes first, but you MUST put them in the correct order! Otherwise you will
%get wrong plots.

% XscaleFactor value is always 0 for manual = 'on'
XcaleFactor_manual_on_value = Multiplier_x_manual_on;%for no geometry-included and "Manual_repeat = on" only, and 1.0*count for each increment, NOT real positions!
YscaleFactor_manual_on_value = shift_y_manual_on;%for no geometry-included only and 0s ensure real y positions are used



 %%%%%%%%%%%%%%%%%%%% manual = 'on' or 'off' with Marker %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 prompt = 'Do you want curve fitting/interpolation for Marker study? e.g. type "yes" or "no": '; %for now Marker will only be considered when Meanual_repeat = 'off' and
 Marker = input(prompt, 's');
 lowercase_Marker = lower(Marker);

 while isempty(lowercase_Marker) == 1 || (strcmp('yes', lowercase_Marker) ~=1 && strcmp('no', lowercase_Marker) ~=1)
     prompt = 'Please type in a valid word: "yes/no": ';
     Marker = input(prompt, 's');
     lowercase_Marker = lower(Marker);

 end

 if strcmp(lowercase_Marker, 'no')
         warning_Info = { 'You have chosen NOT to study Marker, lowercase_Marker = "';
                  lowercase_Marker;
                  '"';
                  newline};
    prompt = 'Do you want to shift profiles down to origin (y/y_c = 0)? Then type [o](o NOT 0!), or type [geo] to let profiles sit on geometry: '; 
    location = input(prompt, 's');
    lowercase_location = lower(location);

    while isempty(lowercase_location) == 1 || (strcmp('o', lowercase_location) ~=1 && strcmp('geo', lowercase_location) ~=1)
        prompt = 'Please type in a valid word: "o/geo": ';
        location = input(prompt, 's');
        lowercase_location = lower(location);

    end

         warning('%s%s%s%s', warning_Info{:});
 elseif strcmp(lowercase_Marker, 'yes')%only need to adjust the shift in y (wall normal)

    prompt = 'Do you want to shift profiles down to origin (y/y_c = 0)? Then type [o](o NOT 0!), or type [geo] to let profiles sit on geometry: '; 
    location = input(prompt, 's');
    lowercase_location = lower(location);

    while isempty(lowercase_location) == 1 || (strcmp('o', lowercase_location) ~=1 && strcmp('geo', lowercase_location) ~=1)
        prompt = 'Please type in a valid word: "o/geo": ';
        location = input(prompt, 's');
        lowercase_location = lower(location);

    end

    %XcaleFactor_manual_on_value = Multiplier_x_manual_on;%for no geometry-included and "Manual_repeat = on" only, and 1.0*count for each increment, NOT real positions!
    %YscaleFactor_manual_off_value = Shift_y_manual_off_marker;%use needs to tune this distance accordingly to lower each individual profile down to zero of y
    %YscaleFactor_manual_on_value  = Shift_y_manual_off_marker;


 end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% For marker study user must give propriate y_wall and y_boundary values %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%later you will calculate 99%Ufree to approximate the function of boundary layer
%thickness. Use it to calculate corresponding thickness given x/c values.
%Defined "y_wall" and "y_boundary" below, real/physical values of y!!!!!!! Not normalized value of y_c!!!!!!!!!
if strcmp(lowercase_Marker,'yes')
    
    switch lowercase_location
        case 'o'
            y_wall_lowerlimit               = 0.0;%at x_c that gives the smallest value possible
            
            y_boundary_upperlimit           = 0.012;%at x_c that gives largest value possible, i.e. 0.012 for cd,0.01 for ab and ef (user MUST manually change to the correct upper limit to get correct fitted curve!!!)

        case 'geo'
            y_wall_lowerlimit               = 0.0;%at x_c that gives the smallest value possible
            y_boundary_upperlimit           = 0.024;%at x_c that gives largest value possible, i.e. 0.024，0.01806
    end
    
    if strcmp(lowercase_location,'geo') || strcmp(lowercase_location,'o')
            warning_Info = { 'You have chosen to study Marker, ';
                      newline;
                      '"lowercase_location = ';
                      lowercase_location;
                      '",';
                      newline;
                      'the physical value of y on geometry, i.e. y_wall = ';
                      num2str(y_wall_lowerlimit);
                      ',';
                      newline
                      'the physical value of boundary thickess, i.e. y_boundary = ';
                      num2str(y_boundary_upperlimit)};

             warning('%s%s%s%s%s%s%s%s%s%s%s%s', warning_Info{:});
             
             
    end
elseif strcmp(lowercase_Marker,'no')
    
            y_wall_lowerlimit               = 0.0;
            y_boundary_upperlimit           = 0.024;
            
            warning_Info = { 'You have chosen NOT to study Marker, ';
                      newline;
                      'the TRIVIAL initialization of the physical value of y on geometry, i.e. y_wall = ';
                      num2str(y_wall_lowerlimit);
                      ',';
                      newline;
                      'the TRIVIAL initialization of physical value of boundary thickess, i.e. y_boundary = ';
                      num2str(y_boundary_upperlimit)};

             warning('%s%s%s%s%s%s%s', warning_Info{:});
             
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% if strcmp(lowercase_location,'o') && y_wall_lowerlimit ~= 0.0
%     msg = ['You have chosen to have shifts in profiles down to y/y_c = 0, however the value of y_wall is NOT equal to 0, i.e. y_wall = ',num2str(y_wall_lowerlimit),'!!!'];
%     error(msg);
% elseif strcmp(lowercase_location,'geo') && y_wall_lowerlimit == 0.1
%     msg = ['You have chosen to have shifts to the geometry surface i.e. y/y_c > 0, however the value of y_wall is equal to 0, i.e. y_wall = ',num2str(y_wall_lowerlimit),'!!!'];
%     error(msg);
% end

ypls_wall            = y_wall_lowerlimit./CFD_cordLength;%y/c on the geometry surface (use the smallest value among a sets of data)
ypls_boundary        = y_boundary_upperlimit./CFD_cordLength;


fit_ypls_shiftOrigin             = ypls_wall;
fit_ypls_shiftOrigin_upper_limit = ypls_boundary;


varNames = {'y_c|shiftOrigin', 'y_c|shiftBoundary', 'y|shiftOrigin', 'y|shiftBoundary' };
T = table(fit_ypls_shiftOrigin, fit_ypls_shiftOrigin_upper_limit, y_wall_lowerlimit, y_boundary_upperlimit,'VariableNames',varNames);
disp(T)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




%The new version "Baseline_manual_on_PortionName" requires user only
%specifiy the indices of original/baseline result without worrying about
%specifying the common portion of file names as the older version used to need.
%However the user MUST give appropriate names since "\d*" only identifies
%the numbers portion in the file names, which correspond to the positions
%on the geometry, e.g. 06 means x = 0.6 and 25 means x = 2.5,etc.
switch Manual_repeat
    case 'on'
        disp(newline);
        
        prompt = 'Please specify the number of positions on the geometry surface (e.g. type "3" if three positions at x0.1, x0.2, x0.3): ';
        nu_pos = input(prompt);

        while length(nu_pos) ~= 1 || nu_pos == 0 %ensure user type in any ONE numeric value except 0 (remeber code will execute the FIRST condition if || is used and execute the content is it is true)
                                                                                                                                        
             prompt = ['Please specify only ONE NUMBER (smaller than ', num2str(length(fn_UQSD7003_Mean)), ') for number of positions on the geometry surface (e.g. type "3" if three positions at x0.1, x0.2, x0.3): '];
             nu_pos = input(prompt);
           
        end 
       
        disp(newline);
        
        prompt = ['You have selected "repeat = ', Manual_repeat, '", and please specify the position indices of "Baseline" data for UQ plots, e.g. [6 7 8]/[6:8]'...
                  '(type [Enter] if only normal plotting of lines are interested and No UQ plots are needed!): '];
        Baseline_manual_on = input(prompt); 
        
        if max(Baseline_manual_on) > length(fn_UQSD7003_Mean) 
                 prompt = ['Please specify all your position indices (smaller than ', num2str(length(fn_UQSD7003_Mean)), ') of "Baseline" data, e.g. [6 7 8]/[6:8]: '];
                 Baseline_manual_on = input(prompt);
        end
       
        while length(Baseline_manual_on)~=nu_pos 
            if isempty(Baseline_manual_on) %ensure empty Baseline_manual_on (in case user does not want to include any baseline data) will be dealt with
                break
            end
            

            prompt = ['You must give at least ',num2str(nu_pos), ' positions!, please re-type your positions, e.g [6 7 8]/[6:8]: '];
            Baseline_manual_on = input(prompt);
        end
        
        
        if length(Baseline_manual_on) == 1   %check if you have multiple positions to deal with
            msg = ['You have selected "Manual_repeat = ', Manual_repeat,'"', ' with # of positions: ', num2str(length(Baseline_manual_on)), ', HOWEVER the number of baseline positions must be larger or equal to 2.',...
            ' If only ONE position on the geometry is used, consider to switch to "Manual_repeat = off" instead!'];
             
            
            error(msg);
            
        elseif isempty(Baseline_manual_on) == 1 %in case user typed nothing
            
            Baseline_manual_on = zeros(1,nu_pos);
            Baseline_manual_on_PortionName = arrayfun(@(x) num2str(x), Baseline_manual_on, 'UniformOutput', false);
                                                            %only used by UQ plots, however when the user choose to ignore or exclude baseline data sets, UQ is forced "off": show_UQ_ranges = 'off'
                                                            %Therefore it does not matter what default values are set for "Baseline_manual_on" and "Baseline_manual_on_PortionName"
            Info1 = ["Baseline_manual_on= ", num2str(Baseline_manual_on)]; 
            Info2 = [" and Baseline_manual_on_PortionName= ", Baseline_manual_on_PortionName];
            disp(Info1)
            disp(Info2)
                                                            
            show_UQ_ranges = 'off';
            
            warning_Info = { 'You have not specified positions of baseline data! A default value of zeros are used! Note: You must need baseline data for UQ plots!!!';
                             newline;
                             'Therefore "show_UQ_ranges" = ';
                             show_UQ_ranges};
                     
            
            warning('%s%s%s%s', warning_Info{:});
            
        elseif isempty(Baseline_manual_on) ~= 1 %for user correctly typed in baseline position indices
                disp(newline);
                prompt = 'Do you want changing color of UQ ranges? e.g. type "yes" or "no": ';
                UQ_color_changing = input(prompt, 's');
                lowercase_UQ_color_changing = lower(UQ_color_changing);
                
                while isempty(lowercase_UQ_color_changing) == 1 || (strcmp('yes', lowercase_UQ_color_changing) ~=1 && strcmp('no', lowercase_UQ_color_changing) ~=1)
                    prompt = 'Please type in a valid word: "yes/no": ';
                    UQ_color_changing = input(prompt, 's');
                    lowercase_UQ_color_changing = lower(UQ_color_changing);
                    
                end

            Baseline_manual_on_PortionName = cell(1,length(Baseline_manual_on));%initializing the cell array
        
            for l = 1:length(Baseline_manual_on)

                Baseline_manual_on_PortionName(l) = regexpi(fn_UQSD7003_Mean{Baseline_manual_on(l)},'\d{2,5}','match');%from 2 - 5 consecutive digits

            end 

        end
        
      disp(newline);   
        
%****** Jul 10 2021 by Minghan The commented block of code below is no longer needed put left here
%for reference. The reason for be commentted is Marker is independent of
%anything, e.g. whether to include the geometry ****        
%         if strcmp(lowercase_Marker, 'no')%for now Marker study is limited to Manual_repeat = 'off' and no geometry is needed!
%**********************************************************************************        
            prompt = 'Do you want to include geometry, e.g. SD7003 airfoil, type "yes" for yes or "no" for no: ';

            geo_include = input(prompt, 's');
            lowercase_geo_include = lower(geo_include);
            while isempty(lowercase_geo_include) == 1 || (strcmp('yes', lowercase_geo_include) ~=1 && strcmp('no', lowercase_geo_include) ~=1)
                        prompt = 'Please type in a valid word: "yes/no": ';
                        geo_include = input(prompt, 's');
                        lowercase_geo_include = lower(geo_include);                   

            end

            switch lowercase_geo_include
                case 'yes'
    %                 ref_cordLength = DNS_cordLength; %the SD7003 cord has 1.0 cord distance
                    %hori_multiplier = hori_corrector;%to correct the distance between profiles if they cluster together
                    %CFD_geo_factor = ref_cordLength./CFD_cordLength;%however CFD simulation used a SD7003 of 0.2 cord length, and need to multiply by the geo_factor
                    %DNS_geo_factor = CFD_cordLength./ref_cordLength;

    %                  A2 = [' Ref_cordLength: ', num2str(Ref_cordLength), ';  CFD_cordLength: ', num2str(CFD_cordLength), ';  CFD_geo_factor: ', num2str(CFD_geo_factor),...
    %                       '; Ref_geo_factor: ',num2str(Ref_geo_factor), ';  hori_multiplier ', num2str(hori_multiplier), ';  verti_multiplier ', num2str(verti_multiplier)];
    %                 disp(A2);
    %                 warning('For either "Ref_geo_factor" or "CFD_geo_factor" equal to unity means that geometry size is held unchanged!') 
    %                 warning('verti_multiplier/hori_multiplier are additional factors ONLY added to enlarge/suppress the image! E.g. if set to unity, then only CFD_geo_factor/Ref_geo_factor is in effect!')
                       geo_visible = 'on';
                       geo_led     = 'off';
                       A2 = [' Ref_cordLength: ', num2str(Ref_cordLength), ';  CFD_cordLength: ', num2str(CFD_cordLength),' geo_visible = "', geo_visible, '" geo_led= "', geo_led,'"'];
                       disp(A2);
                otherwise
                    warning_Info = { 'Geometry is disabled!!!'};

                    warning('%s', warning_Info{:});

            end
%****** Jul 10 2021 by Minghan The commented block of code below is no longer needed put left here
%for reference. The reason for be commentted is Marker is independent of
%anything, e.g. whether to include the geometry ****

%         elseif strcmp(lowercase_Marker,'yes')
%                
%             YscaleFactor_manual_on_value = YscaleFactor_manual_on_value_Marker;
%             
%             lowercase_geo_include = 'no';
%             
%             warning_Info = { 'Since you have chosen to study Marker, geometry should NOT be included (Geometry is disabled!!!), lowercase_geo_include = "';
%                               lowercase_geo_include;
%                               '";';
%                               newline;
%                               ' YscaleFactor_manual_on_value = [';
%                               num2str(YscaleFactor_manual_on_value);
%                               ']';
%                               newline;
%                               ' if you MISS setting either values of YscaleFactor or gave inappropriate values, you will receive an error like "at least 4 points to fit..."!'};
%                                         
%             warning('%s%s%s%s%s%s%s%s%s', warning_Info{:});
%             
%         end 
%************************************************************************        
        disp(newline);
        
        if strcmp(lowercase_Marker, 'no')
              Info = ['****You have typed in ','[', num2str(Baseline_manual_on),'](total#: ',num2str(length(Baseline_manual_on)), ') for "Baseline_manual_on"****'];
              disp(Info);
           elseif strcmp(lowercase_Marker, 'yes')
             if length(Baseline_manual_on) ~= length(YscaleFactor_manual_on_value)
                 msg = ['You have ',num2str(length(Baseline_manual_on)),' positions', ' but only give "YscaleFactor_manual_on_value": ',num2str(length(YscaleFactor_manual_on_value)), ' in y!!'];
                 error(msg)
             elseif length(Baseline_manual_on) == length(YscaleFactor_manual_on_value)
                 warning_Info = { 'You have chosen to study Marker, lowercase_geo_include = "';
                          lowercase_geo_include;
                          '";';
                          newline;
                          ' YscaleFactor_manual_on_value = [';
                          num2str(YscaleFactor_manual_on_value);
                          ']';
                          newline};

                 warning('%s%s%s%s%s%s%s%s', warning_Info{:});

             end
         end
        
        
        prompt = 'Do you want to include any reference data for comparison, e.g. DNS data, type "yes" for yes or "no" for no: ';
        
        DNS_include = input(prompt, 's');
        lowercase_DNS_include = lower(DNS_include);
        
        while strcmp('yes', lowercase_DNS_include) ~=1 && strcmp('no', lowercase_DNS_include) ~=1
            prompt = 'You must type in either yes/no: ';
            DNS_include = input(prompt, 's');
            lowercase_DNS_include = lower(DNS_include);
        end
        
        switch lowercase_DNS_include
            case 'yes'
                
                
                prompt = ['You have selected "Manual_repeat= ', Manual_repeat, '" and please specify the position indices of the "DNS" data, e.g. [6 7 8]/[6:8]; Or type [Enter]'...
                          ' if only normal plotting of lines are interested and No UQsubplots are needed: '];
                DNS_manual_on = input(prompt); 
               
                    passkey = true;%set true on default 
                   
                    
                    while isempty(DNS_manual_on)  %length(DNS_manual_off) ~=1 covers the condition that DNS_manual_off = []

                        warning_Info = {'No subplots are needed, and DNS_manual_on = ';
                                        num2str(DNS_manual_on)};
                        warning('%s%s', warning_Info{:});

                        prompt = ['You have selected "Manual_repeat = ', Manual_repeat,'"', ' and please provide position indices of the DNS data, e.g. [19:23]: '];
                        DNS_manual_on = input(prompt);

                        if max(DNS_manual_on) > length(fn_UQSD7003_Mean) 
                            prompt = ['Please specify all your position indices (smaller than ', num2str(length(fn_UQSD7003_Mean)), ') of "DNS" data, e.g. [6 7 8]/[6:8]: '];
                            DNS_manual_on = input(prompt);
                        end
                        passkey = false;%set to false to skip the fllowing while statement

                    end

         
                    while length(DNS_manual_on)~=nu_pos && passkey
                        prompt = ['You must give at least ',num2str(nu_pos), ' positions!, please re-type your positions, e.g [6 7 8]/[6:8]: '];
                        DNS_manual_on = input(prompt); 
                    end

                    if max(DNS_manual_on) > length(fn_UQSD7003_Mean) 
                        prompt = ['Please specify all your position indices (smaller than ', num2str(length(fn_UQSD7003_Mean)), ') of "DNS" data, e.g. [6 7 8]/[6:8]: '];
                        DNS_manual_on = input(prompt);
                    end
 
           
                
              
            
            
                    DNS_manual_on_PortionName      = cell(1,length(DNS_manual_on));%Although "DNS_manual_on_PortionName" is executed here but not used yet! Just in case you want this function later!

                    for l = 1:length(DNS_manual_on)

                        DNS_manual_on_PortionName(l)      = regexpi(fn_UQSD7003_Mean{DNS_manual_on(l)},'\d{2,5}','match');%from 2 - 5 consecutive digits
                    end 
                    Info = ['****You have typed in ','[', num2str(DNS_manual_on),'](total#: ',num2str(length(DNS_manual_on)), ') for "DNS_manual_on"****'];
                    disp(Info);
                
                
                
            otherwise
                DNS_manual_on = zeros(1,nu_pos);
                DNS_manual_on_PortionName = arrayfun(@(x) num2str(x), Baseline_manual_on, 'UniformOutput', false);
                
                warning('You did not include any reference data for comparison!');
                
        end
        
    case 'off'
        disp(newline);
        
        
        
        prompt = ['You have selected "Manual_repeat = ', Manual_repeat,'"',' Please specify the position index of the "Baseline" data for UQ plots, e.g. type 5'...
                 ' (type [Enter] if only plotting of normal lines are interested and No UQ plots are needed!): '];
        Baseline_manual_off = input(prompt);
        
        while length(Baseline_manual_off) ~= 1 || Baseline_manual_off == 0 || Baseline_manual_off > length(fn_UQSD7003_Mean)  %ensure user gives the number within a reasonable range
             if isempty(Baseline_manual_off) == 1%Note: this line contained in the first condition "length(Baseline_manual_off)", which MUST be placed at the first argument! 
                 break
             end
            
             prompt = ['Please specify only ONE NUMBER (smaller than ', num2str(length(fn_UQSD7003_Mean)), ') for position index of the "Baseline" data, e.g. type 5: '];
             Baseline_manual_off = input(prompt);
        end 
        
        
        
        if length(Baseline_manual_off) >1 %ensure that user only deals with one position
            msg = ['You have selected "Manual_repeat = ', Manual_repeat,'"', ' with # of positions: ', num2str(length(Baseline_manual_off)), ', HOWEVER the number of baseline positions must be equal to 1.',...
            ' If MUTIPLE positions on the geometry are used, consider to switch to "Manual_repeat = on" instead!'];
             
            
            error(msg);
            
        elseif isempty(Baseline_manual_off) %in case user has typed in nothing
            Baseline_manual_off = zeros(1,length(YscaleFactor_manual_off_value));
            
            %Baseline_manual_off = zeros(1,Baseline_manual_off);
            Baseline_manual_off_PortionName = arrayfun(@(x) num2str(x), Baseline_manual_off, 'UniformOutput', false);
                                                            %only used by UQ plots, however when the user choose to ignore or exclude baseline data sets, UQ is forced "off": show_UQ_ranges = 'off'
                                                            %Therefore it does not matter what default values are set for "Baseline_manual_on" and "Baseline_manual_on_PortionName"
            
                                                            
            Info1 = ["Baseline_manual_off= ", num2str(Baseline_manual_off)]; 
            Info2 = [" and Baseline_manual_off_PortionName= ", Baseline_manual_off_PortionName];
            disp(Info1)
            disp(Info2)
            
%             Info = ["Baseline_manual_off= ", num2str(Baseline_manual_off), " and Baseline_manual_off_PortionName= ", Baseline_manual_off_PortionName];
%             disp(Info);                                                
                                                            
            show_UQ_ranges = 'off';
            
            warning_Info = { 'You have not specified positions of baseline data! Default zeros are used! Only curves will be plotted! Note: You must need baseline data for UQ plots!!!';
                             newline;
                             'Therefore show_UQ_ranges = "';
                             show_UQ_ranges;
                             '"'};
                     
            
            warning('%s%s%s%s%s', warning_Info{:});
            
         elseif ~isempty(Baseline_manual_off) %for user correctly typed in baseline position indices
               disp(newline);
                prompt = 'Do you want changing color of UQ ranges? e.g. type "yes" or "no": ';
                UQ_color_changing = input(prompt, 's');
                lowercase_UQ_color_changing = lower(UQ_color_changing);
                
            while isempty(lowercase_UQ_color_changing) || (strcmp('yes', lowercase_UQ_color_changing) ~=1 && strcmp('no', lowercase_UQ_color_changing) ~=1)
                prompt = 'Please type in a valid word: "yes/no": ';
                UQ_color_changing = input(prompt, 's');
                lowercase_UQ_color_changing = lower(UQ_color_changing);

            end

            Baseline_manual_off_PortionName = cell(1,length(Baseline_manual_off));%initializing the cell array
        
            for l = 1:length(Baseline_manual_off)

                Baseline_manual_off_PortionName(l) = regexpi(fn_UQSD7003_Mean{Baseline_manual_off(l)},'\d{2,5}','match');%consecutive digits with length from ONLY 2-5 considered

            end 
       
        end
        
 
       disp(newline)
%****** Jul 10 2021 by Minghan The commented block of code below is no longer needed put left here
%for reference. The reason for be commentted is Marker is independent of
%anything, e.g. whether to include the geometry ****        
%         if strcmp(lowercase_Marker, 'no')%for now Marker study is limited to Manual_repeat = 'off' and no geometry is needed!
%**********************************************************************************          
%         if strcmp(lowercase_Marker, 'no')%for now Marker study is limited to Manual_repeat = 'off' and no geometry is needed!
        
            prompt = 'Do you want to include geometry, e.g. SD7003 airfoil, type "yes" for yes or "no" for no: ';

            geo_include = input(prompt, 's');
            lowercase_geo_include = lower(geo_include);
            while isempty(lowercase_geo_include) == 1 || (strcmp('yes', lowercase_geo_include) ~=1 && strcmp('no', lowercase_geo_include) ~=1)
                        prompt = 'Please type in a valid word: "yes/no": ';
                        geo_include = input(prompt, 's');
                        lowercase_geo_include = lower(geo_include);                   

            end


            switch lowercase_geo_include
                case 'yes'
    %                 ref_cordLength = DNS_cordLength; %the SD7003 cord has 1.0 cord distance
    %                 hori_multiplier = hori_corrector;%to correct the distance between profiles if they cluster together
    %                 CFD_geo_factor = ref_cordLength./CFD_cordLength;%however CFD simulation used a SD7003 of 0.2 cord length, and need to multiply by the geo_factor

    %                 A2 = [' Ref_cordLength: ', num2str(Ref_cordLength), ';  CFD_cordLength:', num2str(CFD_cordLength), ';  CFD_geo_factor: ', num2str(CFD_geo_factor),...
    %                       ' Ref_geo_factor: ',num2str(Ref_geo_factor), ';  hori_multiplier ', num2str(hori_multiplier), ';  verti_multiplier ', num2str(verti_multiplier)];
    %                 disp(A2);
    %                 warning('For either "Ref_geo_factor" or "CFD_geo_factor" equal to unity means that geometry size is held unchanged!') 
    %                 warning('verti_multiplier/hori_multiplier are additional factors ONLY added to enlarge/suppress the image! E.g. if set to unity, then only CFD_geo_factor/Ref_geo_factor is in effect!')
                     
                       geo_visible = 'on';
                       geo_led     = 'off';
                       A2 = [' Ref_cordLength: ', num2str(Ref_cordLength), ';  CFD_cordLength: ', num2str(CFD_cordLength),' geo_visible = "', geo_visible, '" geo_led= "', geo_led,'"'];;
                       disp(A2);

                otherwise

                    warning_Info = { 'Geometry is disabled!!!'};

                    warning('%s', warning_Info{:});

            end
%****** Jul 10 2021 by Minghan The commented block of code below is no longer needed put left here
%for reference. The reason for be commentted is Marker is independent of
%anything, e.g. whether to include the geometry ****        
%         if strcmp(lowercase_Marker, 'no')%for now Marker study is limited to Manual_repeat = 'off' and no geometry is needed!
%**********************************************************************************              
%         elseif strcmp(lowercase_Marker,'yes')
%                
%             YscaleFactor_manual_off_value = YscaleFactor_manual_off_value_Marker;
%             
%             lowercase_geo_include = 'no';
%             
%             warning_Info = { 'Since you have chosen to study Marker, geometry should NOT be included (Geometry is disabled!!!), lowercase_geo_include = "';
%                               lowercase_geo_include;
%                               '";';
%                               newline;
%                               ' YscaleFactor_manual_off_value = [';
%                                num2str(YscaleFactor_manual_off_value);
%                               ']';
%                                newline;
%                               ' if you MISS setting either values of YscaleFactor or gave inappropriate values, you will receive an error like "at least 4 points to fit..."!'};
%                                         
%             warning('%s%s%s%s%s%s%s%s%s', warning_Info{:});
%             
%         end 
%***************************************************************************************     

     if strcmp(lowercase_Marker, 'no')
          Info = ['****You have typed in ','[', num2str(Baseline_manual_off),'](total#: ',num2str(length(Baseline_manual_off)), ') for "Baseline_manual_off"****'];
          disp(Info);
     elseif strcmp(lowercase_Marker, 'yes')
         if length(Baseline_manual_off) ~= length(YscaleFactor_manual_off_value)
             msg = ['You have ',num2str(length(Baseline_manual_off)),' positions', ' but give "YscaleFactor_manual_off_value": ',num2str(length(YscaleFactor_manual_off_value)), ' in y!!'];
             error(msg)
         elseif length(Baseline_manual_off) == length(YscaleFactor_manual_off_value)
             warning_Info = { 'You have chosen to study Marker, lowercase_geo_include = "';
                      lowercase_geo_include;
                      '";';
                      newline;
                      ' YscaleFactor_manual_off_value = [';
                      num2str(YscaleFactor_manual_off_value);
                      ']';
                      newline};

             warning('%s%s%s%s%s%s%s%s', warning_Info{:});

         end
     end
     
       
        
        prompt = 'Do you want to include any reference data for comparison, e.g. DNS data, type "yes" for yes or "no" for no: ';
        
        DNS_include = input(prompt, 's');
        lowercase_DNS_include = lower(DNS_include);
        
        while isempty(lowercase_DNS_include) == 1 || (strcmp('yes', lowercase_DNS_include) ~=1 && strcmp('no', lowercase_DNS_include) ~=1)
                    prompt = 'Please type in a valid word: "yes/no": ';
                    DNS_include = input(prompt, 's');
                    lowercase_DNS_include = lower(DNS_include);                   
                    
        end
        
        switch lowercase_DNS_include
            case 'yes'
                prompt = ['You have selected "Manual_repeat = ', Manual_repeat,'"', ' and please specify ONE position index of the DNS data for UQsubplots, e.g. type 6, Or type [Enter]'...
                          'if only normal plotting of lines are interested and No UQsubplots are needed: '];
                DNS_manual_off = input(prompt); 
                
                if isempty(DNS_manual_off) %in case user has typed in nothing
                    warning_Info = {'No subplots are needed, and DNS_manual_off = ';
                                    num2str(DNS_manual_off)};
                    warning('%s%s', warning_Info{:});
                    
                    prompt = ['You have selected "Manual_repeat = ', Manual_repeat,'"', ' and please position indices of the DNS data, e.g. [19:23]: '];
                    DNS_manual_off = input(prompt); 
                
                    
%                     DNS_manual_off = zeros(1,length(YscaleFactor_manual_off_value));
                
                else
                    while length(DNS_manual_off) ~=1 || max(DNS_manual_off) > length(fn_UQSD7003_Mean) %length(DNS_manual_off) ~=1 covers the condition that DNS_manual_off = []
                        prompt = ['Please specify ONE DNS position index (smaller than ', num2str(length(fn_UQSD7003_Mean)), ') of "DNS" data, e.g. type 6: '];
                        DNS_manual_off = input(prompt);
                    end
                end
                
                
                Info = ['****You have typed in ','"', num2str(DNS_manual_off),'"(total#: ',num2str(length(DNS_manual_off)), ') for "DNS_manual_off"****'];
                disp(Info);
                
                 DNS_manual_off_PortionName      = cell(1,length(DNS_manual_off));%Although "DNS_manual_on_PortionName" is executed here but not used yet! Just in case you want this function later!
                 for l = 1:length(DNS_manual_off)
                  
                    DNS_manual_off_PortionName(l)      = regexpi(fn_UQSD7003_Mean{DNS_manual_off(l)},'\d{2,5}','match');
                end 
                
            otherwise
                DNS_manual_off = zeros(1,length(Baseline_manual_off)); %always equal to 1, i.e. length(Baseline_manual_off), because only 1 baseline position is ued for manual_repeat=off
                DNS_manual_off_PortionName = arrayfun(@(x) num2str(x), DNS_manual_off, 'UniformOutput', false);
                 %arrayfun(@(x) disp(x), DNS_manual_off_PortionName, 'UniformOutput', false);
                warning('You did not include any reference data for comparison!');
                
        end
        
        %Baseline_manual_off = 5; %number of profiles per case, e.g. 1 for length(Baseline_manual_off)

        %DNS_manual_off = 6; %index of LES data in fn_UQSD7003_cfcp
        warning('Manual_repeat = "off" ');
end
%!!!!!This old version "Baseline_manual_on_PortionName" is written
%below!!!!!!

%Baseline_manual_on_PortionName = [ {'\w*x06'} {'\w*x25'}];%give resonable names to your data files!! E.g. 
                                                      %Name them based on positions(NOT full name!!), e.g. x25, x15,etc.
                                                      
%Note 'Baseline_manual_on_PortionName' should NOT be the full name of the
%baseline data, instead just need to correspond to its correct COMMON PART (e.g.
%x06 is the common part in three different file names). 

%Basically What this does is to group similar data based on their positions, i.e. x06 curves, x25
%curves, and ensure the perturbed result at x06 is compared to its baseline
%result at x06, perturbed at x25 compared to its baseline at x25, etc.
%Do NOT use the full name of the file, because you want to loop through all 
%data at,for example, x06, and Put full name of the baseline data will 
%neglect all rest data files!

%The new version "Baseline_manual_on_PortionName" requires user only
%specifiy the indices of original/baseline result without worrying about
%specifying the common portion of file names as the older version used to need.
%However the user MUST give appropriate names since "\d*" only identifies
%the numbers portion in the file names, which correspond to the positions
%on the geometry, e.g. 06 means x = 0.6 and 25 means x = 2.5,etc.
% switch Manual_repeat
%     case 'on'
%         Baseline_manual_on_PortionName = cell(1,length(Baseline_manual_on));%initializing the cell array
%         
%         for l = 1:length(Baseline_manual_on)
% 
%             Baseline_manual_on_PortionName(l) = regexpi(fn_UQSD7003_Mean{Baseline_manual_on(l)},'\d*','match');
%             
%         end 
%     case 'off'
%         disp(newline);
%         warning('Manual_repeat = "off" ');
% end 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




%%%%%%%%%%%%%%%%%%%%%%%%%%%% list of name portions for all cases %%%%%%%%%%%%%
%Note: User must specify the unique part of each different file name to
%distinguish different files, e.g. Tu33 means files that contain the 'Tu33'
%characters in their file name are going to be recognized during data
%processing.
%Note: '\w*' identifies a word. Any alphabetic, numeric, or underscore character.
%       '\W*' identifies a term that is not a word. Any character that is not alphabetic, numeric, or underscore. 
%In short, '\W*' is more specific while '\w*' is sticking more characters
%around it
expressionUQSD7003Mean = [{'\W*CFD'} {'\W*DNS'} {'\W*PIV'}];
%Treat the experimental and DNS data differently than other predicted data
%The control of these data are put in the following line of code. Always
%leave the names of these files unchanged, unless you change the names
%correspondingly in the following line of code
ExpDNSLES = [{'\W*DNS'} {'yExpT3A'} ];
%control is used to turn off any curves that you do not want to appear. The
%user can add more names within the control array.
%old control without corrected velocity profiles
% control = [{'A_fexp_05'} {'B_fDNS_05'} {'C_cfx_f50_GT'} {'Z_cfx_f50_G'}];

%The following 'control' is used to turn ON the LEGEND for the wanted data,
%as well as the data itself
%control = [{ 'B_velx0150'} {'H_Exp_0150'} {'M_DNS_0150'}];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%The following for loop: Added by Minghan April 3rd 2021, to extract field names%%%%
FieldNames = cell(1, length(fn_UQSD7003_Mean)-1);

for nn = 2: length(fn_UQSD7003_Mean)

            FieldNames{nn-1} = fieldnames(UQSD7003_Mean.(fn_UQSD7003_Mean{nn}));
    
end


%User needs to define field indices here, being used together with "FieldNames"
%Note try not to define indices in cell or matrix form, e.g.
%wallshear_indices = [4 5 6], as prone to errors. 
%Note the following 6 variable names should Never be changed (as long as
%you are calculating cf/cp in OpenFoam), only specifying their
%corresponding indices if need to.

RANS_x_index        = 1;
RANS_y_index        = 2;
RANS_z_index        = 3;

RANS_Mean_index     = 4;

DNS_norm_x_index    = 1;
DNS_norm_y_index    = 2;
DNS_norm_Mean_index = 3;
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%









%%%%%%%%%%%%%%%%%%%%%%%%%%%% settings for graph specifications %%%%%%%%%%%%%

LS_default = 1;%default line style
CS_default = 1; %default color style
Counter_default = 1; %default counter, i.e. number of data files

% control = [];
%specify the range of characters presented in Legend
% LchrRg = (1:1);



%YscaleFactor = [ 0 0 0 0 0 0 0 0 0 0 0 0 0]; %Obsolete: Number of entries must be > NumOfdataSets

%user needs to define a proper range that focus on the wanted results. note
%upper_bound : lower_bound represent the pointer indices to the actual data
%array. upper_index and lower_index represent the pointer indices to
%range_index.
%In other words, the pointer's pointer, i.e. range_index is the pointer to the 
%actual data, and upper_index/lower_index is the pointer to the pointer to the
%actual data.

upper_bound_split_off = 1;%specify here
lower_bound_split_off = 398;%specify here

%upper_index/lower_index is not in use any more but kept here because it
%provides good insight to understanding how pointer works!
%upper_index = upper_bound - (upper_bound - 1); %pointer to range_index
%lower_index = lower_bound - (upper_bound - 1); %pointer to range_index
warning_Info = { 'Files must be organized ONLY based on # of positions under the data directory, e.g. x=0.1, 0.2, 0.3 are the three positions, ';
                 newline;
                 'although at each position 1c, 2c, 3c, 1c1p, 2c1p five cases are plotted.'};

warning('%s%s%s', warning_Info{:});
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% User inputs %%%%%%%%%%%%%

%This "control" MUST be in consistent with the "ctrData" below. For
%example, in the case below we just want to illustrate CFD and DNS results,
%with PIV data turned off. We notice that

% 1. "Led_control" has excluded "H_Exp_0150"
% 2. "ctrData" has turned off Experimental data by giving "Exp"

%Why do we want to separate them in use? Because "Led_control" is for special use of
%having legends in the same color! Again this Leg_control is created just for turning
%ON legnends in the way we want. "ctrData" will ensure all curves are
%shown no matter whatever strings we put in "Led_control". The only
%possibility if we do not give proper strings in "Led_control" is that we 
%do NOT have our legends shown!

%Led_control = [{ 'A_wallshear_2c08'} {'A_wallshear_EV_1c10'} {'A_wallshear_orig_whole'}];


%Led_control = [{'A_CFDuiujMean_x003_1c_TuzzTS' } {'A_CFDuiujMean_x003_2c_TuzzTS'} {'A_CFDuiujMean_x003_3c_TuzzTS'}];%must be full name!

%************ User Inputs *********************************
%************ User Inputs *********************************
%Led_control = {'E_CDFkMean_x0014_CNN_DNS'};%for Repeat=on RANS plot
Led_control      = [{'B_DNS_x014'} {}];%for Repeat=on DNS plot
UQled_control    = [{'A_CFD_1c_x01_TuzzTS'} {} ]; %turn on the UQ legends
%Led_control = {'A_CFDkMean_x0028_TuzzTS'};%for Repeat=on RANS plot
%************ User Inputs *********************************
%************ User Inputs *********************************

%Control to turn OFF a set of data, e.g. a set of 8 velocity profiles. 
%The matched name must be unique to the set of data that will be commented

%ctrData = [{'\W*1c'} {'\W*3c'} {'\W*2c'} {'\W*1c1p'} {'\W*2c1p'} {'\W*DNS'}];%name portion is ok!
%ctrData = [{'\W*1c'} {'\W*3c'} {'\W*2c'} {'\W*1c1p'} {'\W*2c1p'} {'\W*CFD'}];%name portion is ok!


%************ User Inputs *********************************
%Turn on the following condition if the user wants to see everything
%ctrData = {'Show ALL'};
%ctrData = {'\W*DNS'};%For only RANS data are required to appear!
ctrData = {'\W*CFD'};%For only DNS data are required to appear!
%************ User Inputs *********************************
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%By Minghan Sep 15 2022 postdoc
T1 = regexpi('CFD', ctrData, 'match');

if strcmp(T1{1},'CFD')%CFD for turning off CFD
    RANS_fit = 'off';
    DNS_fit = 'on';
else
    RANS_fit = 'on';
    DNS_fit = 'off';
end 


%%%%%%%%%%%%%%%%%%%%To plot UQ bounds user needs to specify the
%%%%%%%%%%%%%%%%%%%%Baseline position in the array 
warningMsg_Matlab = 'off'; %controls the warning msg from Matlab library

UQbounds_visible = 'on';
UQled_visible    = 'on';

geo_LS           = '-';

geo_linewidth    = 1.5;%for geometry line width

geo_color        = [0 0 0]+0.8;%line color of geometry, larger +number weaker transparency

transparency     = 0.3; %larger number means darker

UQbounds_LS      = 'none'; %could also be 'none', '-', '--'

legTransparency  = 'none'; %w or none

%you need to adjust line transparency later....

% Ploting the UQ bounds
stable_color     = 'k';%for no-color-changing option


UQBoundC         = {'b','r','g','c','m',[0.4940 0.1840 0.5560],[0.6740 0.4660 0.1880],...
                    [0.3010 0.7450 0.9330],'b','g','r',[0 0.4470 0.7410],...
                    [0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250],[0.4660 0.6740 0.1880]...
                    [0.6350 0.0780 0.1840],'k'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%for geo excluded
% Lsize        = 45; %legend size
% Csize        = 55; %caption size
% TLsize       = 45; %label size
% Markersize   = 5;
% Linewidth    = 1.5;

%for geo included
Lsize      = 24; %legend size
Csize      = 28; %caption size
TLsize     = 28; %label size
Markersize = 2;
Linewidth  = 1.5;

DNS_marker   = '--';
CFD_marker   = '-o';
DNS_MarkerFC = 'w';%face color, i.e. interior color

fit_RANS_LS = 'o-';
fit_Ref_LS = 'o-';

% lns1	 = {'-k';'-.k';'--k';':k';'ko-';'ks-';'kx-';'kd-';'k^-'};
% lns2	 = {'-r';'-.r';'--r';':r';'ro-';'rs-';'rx-';'rd-';'r^-'};
% lns3	 = {'-g';'-.g';'--g';':g';'go-';'gs-';'gx-';'gd-';'g^-'};
% lns4	 = {'-b';'-.b';'--b';':b';'bo-';'bs-';'bx-';'bd-';'b^-'};

%Specify line style

%Should keep consistency with the single plot (only one type of marker for each set of data, i.e. x004, x006 or x01)
%subplot_Baseline_marker = '--'; 


linS = {'o-' , '-.' , '-' , '--' , '-', '-.k',...
        '-o', '-^' , '-o' , '-s' , '-d' , '-p',...
        '-x','--h','*','-s' , ':' , 'o' , '-d',...
        '-x','--h','*','-s' , ':' , 'o' , '-d',...
        '-o', '-^' , '-o' , '-s' , '-d' , '-p',...
        'o' , '-.' , '-' , '--' , '-', '-.k'};
    
linC = {'k','r', 'g','b',[0.9290 0.6940 0.1250],[0.4940 0.1840 0.5560],'m'...
[0 0.4470 0.7410], [0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250],[0 0.75 0.75],...
[0.6350 0.0780 0.1840], [0 0.5 0],[0.4660 0.6740 0.1880],[0.75 0.75, 0],...
[0.3010 0.7450 0.9330],[0.4940 0.1840 0.5560],[0.4660 0.6740 0.1880],[0.3010 0.7450 0.9330],...
'k','r','g','b','k','r','g','k','r','g','b','k','r','g'};


Hori_Multiplier  = 1.0; %incase curves become undistinguishable or too apart from each other
Verti_Multiplier = 1.0;


%**** Folowing settings are created for marker study (cause NO interuption to the original code) ****
%**** In order to deal with fitting curves properly, user needs to choose
%Manual_repeat = 'off' ****

RANS_fit_poly    = 'poly3';
RANS_fit_polyvar = 7;

Ref_fit_polyvar  = 7;
Ref_fit_poly     = 'poly4';




%**** Working with Marker Only - manipulating RANS fitted curves *****************
indicator            = 'off';
total_files          = length(fn_UQSD7003_Mean) - 1;
half_total_files     = 0.5*total_files; %usually the half total is equal to the number of RANS or DNS (#RANS = #DNS)
RANS_zoneOne_Index   = 2;
RANS_zoneTwo_Index   = 7;
RANS_zoneThree_Index = 19;

DNS_zoneOne_Index    = RANS_zoneOne_Index + half_total_files;
DNS_zoneTwo_Index    = RANS_zoneTwo_Index + half_total_files;
DNS_zoneThree_Index  = RANS_zoneThree_Index + half_total_files;

manual_onoff_fit_RANS_led = cell(1,length(fn_UQSD7003_Mean)); 
manual_onoff_fit_RANS_color = cell(1,length(fn_UQSD7003_Mean));
manual_onoff_fit_RANS_visible = cell(1,length(fn_UQSD7003_Mean));



for RANSl = 1:length(fn_UQSD7003_Mean)
    if RANSl <= RANS_zoneOne_Index
        manual_onoff_fit_RANS_led{RANSl}     = RANS_fit;%on if only RANS data in appearance
    elseif RANSl == RANS_zoneTwo_Index
        manual_onoff_fit_RANS_led{RANSl}     = RANS_fit;%on if only RANS data in appearance
    elseif RANSl == RANS_zoneThree_Index
        manual_onoff_fit_RANS_led{RANSl}     = RANS_fit;%on if only RANS data in appearance
    else
        manual_onoff_fit_RANS_led{RANSl}     = 'off';
    end


end 

%Only for shift to origin and no geometry
for RANSv = 1:length(fn_UQSD7003_Mean)
    if 2 <= RANSv && RANSv <= 18
        manual_onoff_fit_RANS_visible{RANSv}     = RANS_fit;%switch to 'on' if you want to see everything
    else
        manual_onoff_fit_RANS_visible{RANSv}     = RANS_fit;
    end


end

for RANSc = 1:length(fn_UQSD7003_Mean)
    if  RANSc >= RANS_zoneOne_Index && RANSc < RANS_zoneTwo_Index 
        manual_onoff_fit_RANS_color{RANSc}     = 'r';
    elseif RANSc >= RANS_zoneTwo_Index && RANSc < RANS_zoneThree_Index
        manual_onoff_fit_RANS_color{RANSc}     = 'g';
    else
        manual_onoff_fit_RANS_color{RANSc}     = 'b';
    end


end 

% for RANSc = 1:length(fn_UQSD7003_Mean)
%     if  RANSc >= 19 && RANSc < 23 
%         manual_onoff_fit_RANS_color{RANSc}     = 'b';
%     elseif RANSc >= RANS_zoneTwo_Index && RANSc < RANS_zoneThree_Index
%         manual_onoff_fit_RANS_color{RANSc}     = 'k';
%     else
%         manual_onoff_fit_RANS_color{RANSc}     = 'k';
%     end
% 
% 
% end 



%**** Working with Marker Only - manipulating DNS fitted curves *****************
manual_onoff_fit_DNS_led = cell(1,length(fn_UQSD7003_Mean)); 
manual_onoff_fit_DNS_visible = cell(1,length(fn_UQSD7003_Mean));
manual_onoff_fit_DNS_color = cell(1,length(fn_UQSD7003_Mean));

for DNSl = 1:length(fn_UQSD7003_Mean)
    if DNSl == DNS_zoneOne_Index 
        manual_onoff_fit_DNS_led{DNSl}     = DNS_fit;%on if only DNS data in appearance
    elseif DNSl == DNS_zoneTwo_Index
        manual_onoff_fit_DNS_led{DNSl}     = DNS_fit;%%on if only DNS data in appearance
    elseif DNSl == DNS_zoneThree_Index
        manual_onoff_fit_DNS_led{DNSl}     = DNS_fit;%%on if only DNS data in appearance
    else
        manual_onoff_fit_DNS_led{DNSl}     = 'off';
    end


end 

%Only for shift to origin and no geometry
for DNSv = 1:length(fn_UQSD7003_Mean)
    if 34 <= DNSv && DNSv <= 50
        manual_onoff_fit_DNS_visible{DNSv} = DNS_fit;%switch to 'on' if you want to see everything
        
    else
        manual_onoff_fit_DNS_visible{DNSv} = DNS_fit;%switch to 'on' if you want to see everything
    end


end 

for DNSc = 1:length(fn_UQSD7003_Mean)
    if  DNSc >= DNS_zoneOne_Index && DNSc < DNS_zoneTwo_Index 
        manual_onoff_fit_DNS_color{DNSc}     = 'r'; %'m'
    elseif DNSc >= DNS_zoneTwo_Index && DNSc < DNS_zoneThree_Index 
        manual_onoff_fit_DNS_color{DNSc}     = 'g'; %'c'
    else
        manual_onoff_fit_DNS_color{DNSc}     = 'b'; %[0.6350 0.0780 0.1840]
    end

end

%%%%%%%%%%%%%% for downstream zone analyzsis %%%%%%%%%%%%%%%%%%%%%
% for DNSc = 1:length(fn_UQSD7003_Mean)
%     if  DNSc >= 51 && DNSc < 56 
%         manual_onoff_fit_DNS_color{DNSc}     = 'b'; %'m'
%     elseif DNSc >= DNS_zoneTwo_Index && DNSc < DNS_zoneThree_Index 
%         manual_onoff_fit_DNS_color{DNSc}     = [0 0 0]+0.8; %'c'
%     else
%         manual_onoff_fit_DNS_color{DNSc}     = [0 0 0]+0.8; %[0.6350 0.0780 0.1840]
%     end
% 
% 
% end

%%
%The following XscaleFactor should be adjusted properly, e.g. set zero if
%no horizontal offsets are needed. Since always horizontal offsets are
%equal in magnitude, just one value needs to be specified. In contrast,
%YscaleFactor might require further attention because offsets in y
%directions more likely vary with different positions on a geometry, e.g.
%SD7003 airfoil. Again if no offsets are needed, set it be 0.
warning('on')%ensure warning is initially on

switch Manual_repeat
    case 'on'
        Info = ('******** You are selecting "Manual = on" *********');
        disp(Info);
        
        XscaleFactor            = XcaleFactor_manual_on_value; %horizontal shift
        YscaleFactor            = YscaleFactor_manual_on_value; %vertical shift
        Tick_start_correct      = 0;%zero on default you can tune this value for your need
        Baseline                = Baseline_manual_on;
        RefDNS                  = DNS_manual_on;
        first_element           = 1;
        

        hori_multiplier         = Hori_Multiplier;%incase curves become undistinguishable or too apart from each other
        verti_multiplier        = Verti_Multiplier;
        
        NumOfdataSets           = length(Baseline);%number of profiles per case, usually number of positions
        
        expressionUQboundsCtr   = Baseline_manual_on_PortionName;
        expressionDNSCtr        = DNS_manual_on_PortionName;
        DNS_counter             = 0;
        
        disp(newline);
       
        A1 = ['Number of baseline positions on the geometry: ', num2str(length(Baseline)), '; hori_multiplier: ', num2str(hori_multiplier),'; verti_multiplier: ', num2str(verti_multiplier)];
             
        disp(A1);        
        
        disp(newline);
        %************ Repeat = 'on' and Geometry is included ********************
            %Tick labeling
    if isempty(lowercase_geo_include)~=1 && strcmp('yes', lowercase_geo_include) ==1 
        warning('You are using limits for included Geometry!')
        xlimt = [0 0.75];
    %     ylimt = [0.004 0.024];
        %ylimt = [0.0 0.12];
        ylimt = [0.034 0.124];
        figure_size = [0, 0, 16, 6];

        xMinorTick = 'off';
        yMinorTick = 'on';
        %axis labeling
        y_Tick = 0.03;%0.005, 0.010,0.020
        x_Tick = 0.03;%always not in use, because user-customized xTicks are used!
        
        y_MinorTick = y_Tick/5 ;%0.001, 0.002,0.004
        x_MinorTick = x_Tick/5;

      

        ticklen = [0.01 0.04];
        %************ Repeat = 'on' and Geometry is NOT included ********************
    else
        %xlim and ylim
        warning('You are using limits for disabled Geometry!')
        
    
        
        %******** The following x and y limits are created for downstream
        %zone e - f
%         xlimt = [0.68 1.5];
% 
%         ylimt = [0 0.06];
%         figure_size = [0, 0, 16, 9];
%         xMinorTick = 'off';
%***********************************************

% %********* For RANS origin_shift_fit_all  ***********
        figure_size = [0, 0, 20, 20];

        xlimt = [-0.02 0.2];

        if strcmp(T1{1},'CFD')%CFD for turning off CFD

            ylimt = [0 0.12];
            y_Tick = 0.04;
            x_Tick = 0.055;
        elseif strcmp(T1{1},'DNS')%CFD for turning off CFD
            ylimt = [0 0.1];
            y_Tick = 0.02;
            x_Tick = 0.055;
        end 

            
        xMinorTick = 'on';
        yMinorTick = 'on';
 
        
        y_MinorTick = y_Tick/5;
        x_MinorTick = x_Tick/5;


        ticklen = [0.01 0.04];  
    end

    case 'off'
        Info = ('******** You are selecting "Manual = off" *********');
        disp(Info);
   
        
        prompt1 = 'For "Manual = off" you should have only 1 profile per case, and "NumOfdataSets = 1" is set automatically';
        disp(prompt1);
        disp(newline);
        
        NumOfdataSets_manual_off = 1; %"manual = off" means there is also no a "repeat" pattern and hence no manual manipulations 
        NumOfdataSets            = NumOfdataSets_manual_off;
        XscaleFactor             = 0; %For NumOfdataSets = 1 alway be 0
        YscaleFactor             = YscaleFactor_manual_off_value;
        Baseline                 = Baseline_manual_off;
        RefDNS                   = DNS_manual_off;
        first_element            = 1;
        
        expressionDNSCtr         = DNS_manual_off_PortionName;
        expressionUQboundsCtr    = Baseline_manual_off_PortionName;
        
        DNS_counter              = 0;
        
        %************ Repeat = 'off' and Geometry is included ********************
        %Tick labeling
    if isempty(lowercase_geo_include)~=1 && strcmp('yes', lowercase_geo_include) ==1 
        %xlim and ylim
        warning('You are using limits for airfoil included!')
        ylimt = [0.034 0.08];
        xlimt = [0 0.7];
        %Figure size
        figure_size = [0, 0, 20, 20];
        
        hori_multiplier         = Hori_Multiplier;%incase curves become undistinguishable or too apart from each other
        verti_multiplier        = Verti_Multiplier;
        
        xMinorTick = 'on';
        yMinorTick = 'on';

        %axis labeling
        y_Tick = 0.005;
        x_Tick = 0.1;
        
        y_MinorTick = y_Tick/5;
        x_MinorTick = x_Tick/5;

        

        ticklen = [0.01 0.04];
        %************ Repeat = 'off' and Geometry is NOT included ********************
    else
        %xlim and ylim
        warning('You are using limits for airfoil not included!')
        ylimt = [-0.02 0.1];%(0.15) [0.052 0.082] (0.50)[0.047 0.107]
        xlimt = [-0.02 0.12];%(0.15)[-0.03 0.09] (0.50)[-0.01 0.035]
        %Figure size
        figure_size = [0, 0, 20, 20];

        xMinorTick = 'on';
        yMinorTick = 'on';

        %axis labeling
        y_Tick = 0.02; %(0.15) 0.010 (0.1) 0.007 (0.5) 0.02
        x_Tick = 0.045; %(0.15) 0.04 (0.1) 0.0025 (0.5) 0.015
        
        
        y_MinorTick = y_Tick/5; %(0.15)0.002 (0.1) 0.0014
        x_MinorTick = x_Tick/5; %(0.15)0.008 (0.1) 0.0005

        

        ticklen = [0.01 0.04]; 
    end

end 

switch Split
    case 'yes'
        warning('"Split" is on!');
      
    case 'no'
        upper_bound = upper_bound_split_off;%specify here
        lower_bound = lower_bound_split_off;%specify here
        range_index = (upper_bound_split_off : lower_bound_split_off); %pointer to actual data
        
        warning('"Split" is off!');
end

%For only one profile each case usually we only vary the line style. If
%color changing is required as well, set 'yes' below.
if (NumOfdataSets == 1)
    prompt ='Do you want different colors for single-curve cases: type "Enter" for single-color curves" or "no" for multi-color curves: ';
    
    line_ChangingColor = input(prompt, 's');
    lowercase_line_ChangingColor = lower(line_ChangingColor);

    while isempty(lowercase_line_ChangingColor) ~= 1 &&  strcmp('no', lowercase_line_ChangingColor) ~=1
         prompt = 'Please type in a valid word: "Enter/no": ';
         line_ChangingColor = input(prompt, 's');
         lowercase_line_ChangingColor = lower(line_ChangingColor);
    end

    if isempty(lowercase_line_ChangingColor)
        lowercase_line_ChangingColor = 'default';
    end
end


%%%%%%%%%%%%%%%%%%every time you add more data files, the DIMENSION of the
%%%%%%%%%%%%%%%%%%following YscaleFactor matrix MUST be changed accordingly
    

%     yrange_exp = { (1:100) (25:100) (40:100) (25:100) (10:100) };
%     YscaleFactor_exp = [ 0.052 0.055 0.057 0.057 0.050 0.05 0.04];
%     
%     yrange_CFD = { (1:1000) (1:855) (1:900) (1:900) (1:900) (1:900) (1:900) };
   






    
%****** for fit_all both RANS and DNS **************  
if strcmp(location,'o')
    title('(a)', 'Position',[-0.012 0.094],'interpreter','latex');
elseif strcmp(location,'geo')
%****** for shift_to_origin_all_fit ******


%DNS

    title('(f)', 'Position',[0.03 0.11],'interpreter','latex');
end






hold on
%The following code, instead of taking the total number of postions taken
%for each case, bases the recounting number on the length of number of
%color samples stored, in this case we have 9 color samples, but we only
%have 8 sets of data for each case, therefore it is more suitable to
%base our recounting number on the number of sets of data we have.
%Nevertheless, the following code is still very useful, and maybe used for
%other calculations.
%-------------------------------------------------------------------------
% for i = 2: length(fn)
%
% if rem(i-1,length(linC))>0
% j = rem(i-1,length(linC));
% elseif rem(i-1,length(linC))==0
% j = length(linC);
% end
%-------------------------------------------------------------------------
%Define default values outside the for loop, e.g. LS =1
    LS = LS_default; %line style
    CS = CS_default; %color style
    counter = Counter_default; %number of profiles for each case, e.g. two cases Exp vs RANS
    
%Note file index corresponds to i-1 in fn_SD7003Vel, as the 1st file starts at i=2

%If you set "NumOfdataSets" wrong, you will get wrong plots for UQ bounds
%(big chuncks of UQ ranges). That problem is caused winthin the if
%statements below due to wrong counter number that will be used to control
%x shifts from the "reshape" functionality below, eg. XscaleFactor*counter.

 for i = 2: length(fn_UQSD7003_Mean)
        %disp(i)
        if rem(i-1,NumOfdataSets)>0

            counter = rem(i-1,NumOfdataSets);
            CS      = counter;
         
    
        elseif rem(i-1,NumOfdataSets)==0 && NumOfdataSets > 1 %last remainder is always 0, so user

            %must reassign the last postion

            
            counter = NumOfdataSets;
            CS      = counter;
         

        end
%The 'if section'ensures for each new set/case of data, line style changes.
%Note counter or j varies within the range of 1 - 4 (NumOfdataSets = 4).

            
            if (i-1)>length(NumOfdataSets) && rem(i-1,NumOfdataSets)==1
                 %disp(i);
                 %disp(rem(i-1,NumOfdataSets));
                LS= LS+rem(i-1,NumOfdataSets);
                %disp(LS);
                
                
            elseif rem(i-1,NumOfdataSets)==0 && NumOfdataSets==1
                LS = i - 1;
                counter = i - 1;
                %Info = ['counter= ', num2str(counter)];
                %disp(Info);
                switch lowercase_line_ChangingColor
                    case 'no'
                        CS = i -1;
                        
                    case 'default'
                        CS = CS_default;
                        %disp(CS)
                end 
               
            end
  
    
    
    switch fn_UQSD7003_Mean{i}
    
        case Led_control
            %In contrast to the other m files, anything under this bloc will show the
            %the legend
            %visible = 'off';
            %led = 'off';
        
            visible = 'on';
            led = 'on';
            %disp(visible)
            % disp(led)
            % disp(num2str(i))
        otherwise
            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            
                    CFDctr = cell(1,length(ctrData));
                for ctr= 1:length(ctrData)

                   
                        CFDctr{ctr} = regexpi(fn_UQSD7003_Mean{i}, ctrData{ctr}, 'match');
                        
                        
                         %-----debugging code----
                       %  TF = isempty(CFDctr{ctr});                       
                       %  info = ['i= ',num2str(i),'ctr = ',num2str(ctr),' CFDctr= ', CFDctr{ctr},'TF ', num2str(TF)];                  
                       %  disp(info);

%Note: 'break' terminates the exexution of a for or while loop. Not only terminates the if statements but the outer loop!                
                    if isempty(CFDctr{ctr})~=1
                        
%                         CFD_ctr =[]; uncomment if use with the following
%                                      block
                        visible = 'off';
                        led = 'off';  
                        break
                    elseif isempty(CFDctr{ctr})==1 && NumOfdataSets > 1
                       
%                         CFD_ctr = {'Required to appear'}; uncomment if
%                                           use with the following block

                        visible = 'on';
                        led = 'off';
                    elseif isempty(CFDctr{ctr})==1 && NumOfdataSets == 1
                        visible = 'on';
                        led = 'off';
                    end
                  
                end
%%%%%%%%%%%%%%%%%%%The above block of code was originally written in SD7003_velPlot_April2020%%%%%%  

            
%             visible = 'on';
%             led = 'off';

    end
    
    
    

%If additional types of data, e.g. DNS, are needed to be included
%for comparison, just add them after the following two lines
    CFD = regexpi(fn_UQSD7003_Mean{i}, expressionUQSD7003Mean{1,1}, 'match');
    %disp(CFD)
    exp = regexpi(fn_UQSD7003_Mean{i}, expressionUQSD7003Mean{1,3}, 'match');
    
    DNS = regexpi(fn_UQSD7003_Mean{i}, expressionUQSD7003Mean{1,2}, 'match');
%The following for loop ensures the proper use of regexpi
    for k = 1:length(expressionUQSD7003Mean)
        cases = regexpi(fn_UQSD7003_Mean{i}, expressionUQSD7003Mean{1,k}, 'match');
        %disp(cases)
        if isempty(cases)~=1
            CASE = cases;
            break
        elseif isempty(cases)==1
            CASE = {'continue'};

        end
        
    end
    
    switch CASE{1}

        case CFD
            %disp(CFD)
            
%               Info=['File # ',num2str(i-1),' File name:',fn_UQSD7003_Mean{i}];
%               disp (Info);
           
            
            switch Split
                case 'yes'
                  
                 
                  %********************************  Jul 10 2021 by Minghan Chu ***************************************   
                  %Note all data (DNS/Exp and RANS) are calulated in its original form,
                  %e.g. NO x or y shifts applied. These shifts are only
                  %applied when plotting. 
                  %On the other hand, you can manipulate and store the modified version of the original data for your special purposes, e.g. 
                  %marker study needs vertical shifts to have a zero
                  %origin, which are dealt with independent of the original
                  %data. The benefits of this is to avoid contamination of
                  %your original data! Keep in mind, you store any modified
                  %version of your original data here with the help of the
                  %loop (see how you did for storing the modified data for
                  %Marker), and plot the original data (in the standard
                  %form) here, any shfits will be applied when plotting.
                  
                  %RANS data in Original form
                  norm_x       = UQSD7003_Mean.(fn_UQSD7003_Mean{i}).(FieldNames{i-1}{RANS_x_index})./CFD_cordLength;
                  norm_y       = UQSD7003_Mean.(fn_UQSD7003_Mean{i}).(FieldNames{i-1}{RANS_y_index})./CFD_cordLength;
                  norm_Mean    = (UQSD7003_Mean.(fn_UQSD7003_Mean{i}).(FieldNames{i-1}{RANS_Mean_index}))./Ufree_UQSD7003^2;
                  
                 
                  
                  %plot(RANSData.(fn_UQSD7003_Mean{Baseline}).norm_y(range), RANSData.(fn_UQSD7003_Mean{Baseline}).y,'--');
                      
                 
             
                      
                      
                    
                    %************* May 4th 2021 by Minghan ***************
                    %****** create a struct to contain necessary parameters
                    %with "Split" functionality turned on
                    %split.(fn_UQSD7003_cfcp{i}) = struct('camber', 'idx_upper', 'idx_lower');
                    split.camber = poly(norm_x);
                    split.idx_upper = norm_y >= split.camber;
                    split.idx_lower = norm_y <= split.camber;
                    %*****************************************************
                    
                    
                    
                   
                     
        
                    if isempty(lowercase_geo_include)~=1 && strcmp('yes', lowercase_geo_include) ==1 
                        Info = ['File #: ', num2str(i-1), ';  File name: ',fn_UQSD7003_Mean{i}, ';   Minghan under CFD and split LS= ', num2str(LS), '; Geometry is included!'];
                        disp(Info);               
                        
                        titlepos.(fn_UQSD7003_Mean{i}).x = norm_x(first_element);
                  
                        
                        %********* Jun 12 2021 by Minghan Chu obsolete code
                        %but left for purpose of learning******************
                          %titlepos.(fn_UQSD7003_Mean{i}).x = UQSD7003_Mean.(fn_UQSD7003_Mean{i}).(FieldNames{i-1}{RANS_x_index})(first_element)*CFD_geo_factor * hori_multiplier;
                          
%                         Graph.(fn_UQSD7003_Mean{i}) = plot(norm_Mean(split.idx_upper)+UQSD7003_Mean.(fn_UQSD7003_Mean{i}).(FieldNames{i-1}{RANS_x_index})(first_element)*CFD_geo_factor * hori_multiplier, ...
%                         norm_y(split.idx_upper)*verti_multiplier,linS{LS});%note: it mustn't necessarily be first_element in the RANS_x_index column because x position is unchanged

%                         UQbounds.(fn_UQSD7003_Mean{i}).reshape_upper_x = reshape(norm_y(split.idx_upper)*verti_multiplier, 1, []);
%                         UQbounds.(fn_UQSD7003_Mean{i}).reshape_upper_y = reshape(norm_Mean(split.idx_upper)+UQSD7003_Mean.(fn_UQSD7003_Mean{i}).(FieldNames{i-1}{RANS_x_index})(1)*CFD_geo_factor * hori_multiplier, 1, []);
                        %****************************
                         
                        %Much easier than the obsolete version but
                        %functions the same
                        Graph.(fn_UQSD7003_Mean{i}) = plot(norm_Mean(split.idx_upper)+norm_x(split.idx_upper)*hori_multiplier, ...%real positions are used to locate each profile!
                        norm_y(split.idx_upper)*verti_multiplier,CFD_marker);
                    
                        UQbounds.(fn_UQSD7003_Mean{i}).reshape_upper_x = reshape(norm_y(split.idx_upper)*verti_multiplier, 1, []);
                        UQbounds.(fn_UQSD7003_Mean{i}).reshape_upper_y = reshape(norm_Mean(split.idx_upper)+norm_x(split.idx_upper)*hori_multiplier, 1, []);
                        
                        
%                   %***************************************************** 
                    
                    %Modified version of the original data and stored in
                    %struct                 

                        %********** Jun 27th 2021 Added by Minghan - curve
                        %fitting for marker***********************************
                        if strcmp(Marker,'yes')

                              %********* The following three lines of code stores plotting data ********** 
                              RANSData.(fn_UQSD7003_Mean{i}).suction_indices = find(norm_y > 0); %get the indices for suction side of the geometry from the original data                                                 
                              RANSData.(fn_UQSD7003_Mean{i}).y_c_wall        = min(norm_y(RANSData.(fn_UQSD7003_Mean{i}).suction_indices)); %from those indices get the corresponding min value which corresponds to the first cell above the wall                                          
                                                                    
                              
                              
                              
                                RANSData.(fn_UQSD7003_Mean{i}).norm_x        = norm_x;
                              if strcmp(lowercase_location,'geo')
                                RANSData.(fn_UQSD7003_Mean{i}).norm_y        = norm_y;
                              elseif strcmp(lowercase_location,'o')
                                RANSData.(fn_UQSD7003_Mean{i}).norm_y        = norm_y - RANSData.(fn_UQSD7003_Mean{i}).y_c_wall; %shift all profiles from the suction surface to the origin, i.e. y_c=0
                              end
                                RANSData.(fn_UQSD7003_Mean{i}).norm_Mean     = norm_Mean + norm_x;
                                

                              %************* Fitting is needed for marker study
                              %*********
                  
                              RANSData.(fn_UQSD7003_Mean{i}).RANS_fit_indx = sort(find(RANSData.(fn_UQSD7003_Mean{i}).norm_y > fit_ypls_shiftOrigin &...
                                                                                  RANSData.(fn_UQSD7003_Mean{i}).norm_y < fit_ypls_shiftOrigin_upper_limit),'ascend');
                          
                              RANSData.(fn_UQSD7003_Mean{i}).norm_x_fitIndx     = RANSData.(fn_UQSD7003_Mean{i}).norm_x(RANSData.(fn_UQSD7003_Mean{i}).RANS_fit_indx);
                              RANSData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx     = RANSData.(fn_UQSD7003_Mean{i}).norm_y(RANSData.(fn_UQSD7003_Mean{i}).RANS_fit_indx);
                              RANSData.(fn_UQSD7003_Mean{i}).norm_Mean_fitIndx  = RANSData.(fn_UQSD7003_Mean{i}).norm_Mean(RANSData.(fn_UQSD7003_Mean{i}).RANS_fit_indx);


                            %One way of fitting - polyfit
                            RANSData.(fn_UQSD7003_Mean{i}).p = polyfit(RANSData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx,...
                                                                       RANSData.(fn_UQSD7003_Mean{i}).norm_Mean_fitIndx, RANS_fit_polyvar);

                            RANSData.(fn_UQSD7003_Mean{i}).y = polyval(RANSData.(fn_UQSD7003_Mean{i}).p, RANSData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx);

                            %A second way of fitting - fit (probably to be used for my research)
                            RANSData.(fn_UQSD7003_Mean{i}).fitp = fit(RANSData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx,...
                                                                      RANSData.(fn_UQSD7003_Mean{i}).norm_Mean_fitIndx, RANS_fit_poly);


                                                                  
                                                                  


                            
                            fit_RANS_with_geo = plot(RANSData.(fn_UQSD7003_Mean{i}).y, RANSData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx,'--');
                            set (fit_RANS_with_geo,'color',manual_onoff_fit_RANS_color{i},'DisplayName',fn_UQSD7003_Mean{i},...
                                   'visible',visible,'HandleVisibility',manual_onoff_fit_RANS_led{i},'LineWidth',Linewidth,'MarkerSize',Markersize);

                        elseif strcmp(Marker,'no')
                            warning('Marker option is disabled!!!')
                        end
                        %*****************************************************
                    
                    else
                         Info = ['File #: ', num2str(i-1), ';  File name: ',fn_UQSD7003_Mean{i}, ';   Minghan under CFD and split LS= ', num2str(LS), '; Geometry is NOT included!'];
                         disp(Info);
%                     UQbounds.(fn_UQSD7003_cfcp{i}) = struct('x_upper', 'y_upper','x_lower','y_lower','reshape_upper_x', 'reshape_upper_y', ...
%                                                             'reshape_lower_x','reshape_lower_y');%create a new struct

                    Graph.(fn_UQSD7003_Mean{i}) = plot(norm_Mean(split.idx_upper)+XscaleFactor*counter, norm_y(split.idx_upper)-YscaleFactor(counter),linS{LS});
                    %Graph.(fn_UQSD7003_Mean{i}) = plot(norm_Mean(split.idx_upper)+XscaleFactor*counter, norm_y(split.idx_upper)-YscaleFactor(counter),'--');

                    UQbounds.(fn_UQSD7003_Mean{i}).reshape_upper_x = reshape(norm_y(split.idx_upper)-YscaleFactor(counter), 1, []);
                    UQbounds.(fn_UQSD7003_Mean{i}).reshape_upper_y = reshape(norm_Mean(split.idx_upper)+XscaleFactor*counter, 1, []);
                    
                    UQbounds.(fn_UQSD7003_Mean{i}).reshape_lower_x = reshape(norm_y(split.idx_lower)-YscaleFactor(counter), 1, []);%Under normal circumstances/normally you will never be interested in plotting 
                                                                                                              %U profiles in the pressure side. If someday you would like to see those profiles
                                                                                                              %defined a "YscaleFactor_lower" for it
                    UQbounds.(fn_UQSD7003_Mean{i}).reshape_lower_y = reshape(norm_Mean(split.idx_lower)+XscaleFactor*counter, 1, []);

                    %Modified version of the original data and stored in
                    %struct   
                    
                        %********** Jun 27th 2021 Added by Minghan - curve
                        %fitting for marker***********************************
                        if strcmp(Marker,'yes')
                        
                              RANSData.(fn_UQSD7003_Mean{i}).suction_indices = find(norm_y > 0); %get the indices for suction side of the geometry from the original data                                                 
                              RANSData.(fn_UQSD7003_Mean{i}).y_c_wall        = min(norm_y(RANSData.(fn_UQSD7003_Mean{i}).suction_indices)); %from those indices get the corresponding min value which corresponds to the first cell above the wall                                          
                              
                              
                              
                           
                            
                              %********* The following three lines of code stores plotting data ********** 
                                RANSData.(fn_UQSD7003_Mean{i}).norm_x        = norm_x;
                              if strcmp(lowercase_location,'geo')
                                RANSData.(fn_UQSD7003_Mean{i}).norm_y        = norm_y;
                              elseif strcmp(lowercase_location,'o')
                                RANSData.(fn_UQSD7003_Mean{i}).norm_y        = norm_y - RANSData.(fn_UQSD7003_Mean{i}).y_c_wall; %shift all profiles from the suction surface to the origin, i.e. y_c=0
                              end
                                RANSData.(fn_UQSD7003_Mean{i}).norm_Mean     = norm_Mean + XscaleFactor*counter;



                              %************* Fitting is needed for marker study
                              %*********
                              RANSData.(fn_UQSD7003_Mean{i}).RANS_fit_indx = find(RANSData.(fn_UQSD7003_Mean{i}).norm_y > fit_ypls_shiftOrigin & RANSData.(fn_UQSD7003_Mean{i}).norm_y < fit_ypls_shiftOrigin_upper_limit);

                              RANSData.(fn_UQSD7003_Mean{i}).norm_x_fitIndx     = RANSData.(fn_UQSD7003_Mean{i}).norm_x(RANSData.(fn_UQSD7003_Mean{i}).RANS_fit_indx);
                              RANSData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx     = RANSData.(fn_UQSD7003_Mean{i}).norm_y(RANSData.(fn_UQSD7003_Mean{i}).RANS_fit_indx);
                              RANSData.(fn_UQSD7003_Mean{i}).norm_Mean_fitIndx  = RANSData.(fn_UQSD7003_Mean{i}).norm_Mean(RANSData.(fn_UQSD7003_Mean{i}).RANS_fit_indx);

                            %One way of fitting - polyfit
                            RANSData.(fn_UQSD7003_Mean{i}).p = polyfit(RANSData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx,...
                                                                       RANSData.(fn_UQSD7003_Mean{i}).norm_Mean_fitIndx, RANS_fit_polyvar);

                            RANSData.(fn_UQSD7003_Mean{i}).y = polyval(RANSData.(fn_UQSD7003_Mean{i}).p, RANSData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx);

                            %A second way of fitting - fit (probably to be used for my research)
                            RANSData.(fn_UQSD7003_Mean{i}).fitp = fit(RANSData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx,...
                                                                      RANSData.(fn_UQSD7003_Mean{i}).norm_Mean_fitIndx, RANS_fit_poly);
                              

                        
                            %plot(RANSData.(fn_UQSD7003_Mean{i}).y, RANSData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx,'ro-');
                            fit_RANS_without_geo = plot(RANSData.(fn_UQSD7003_Mean{i}).y, RANSData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx,fit_RANS_LS);
                            set (fit_RANS_without_geo,'color',manual_onoff_fit_RANS_color{i},'DisplayName',fn_UQSD7003_Mean{i},...
                                 'visible',manual_onoff_fit_RANS_visible{i},'HandleVisibility',manual_onoff_fit_RANS_led{i},'LineWidth',Linewidth,'MarkerSize',Markersize);
                        
                        elseif strcmp(Marker,'no')
                            warning('Marker option is disabled!!!')
                        end
                        %*****************************************************
                 
                    end 
                    
             
                    
                    %store data on suction and pressure sides separately
                    UQbounds.(fn_UQSD7003_Mean{i}).upper_x = norm_Mean(split.idx_upper);
                    UQbounds.(fn_UQSD7003_Mean{i}).upper_y = norm_y(split.idx_upper);
                    
                    
                    UQbounds.(fn_UQSD7003_Mean{i}).lower_x = norm_Mean(split.idx_lower);
                    UQbounds.(fn_UQSD7003_Mean{i}).lower_y = norm_y(split.idx_lower);
                    %*****************************************************

                    
                case 'no'
                    
                    %using 'find' to get the values of upper_index and
                    %lower_index!
                    Info=['range_index = ', '(',num2str(range_index(find(range_index,1,'first'))), ...
                          ' , ', num2str(range_index(find(range_index,1,'last'))),')'];
                    disp (Info);
                    
                    %**** for debugging ****
                    %Info=(num2str(T3A_cfcp.(fn_T3A_cfcp{i}).wallShearStress0x3A1));
%                     %disp(Info);
%                     
%                     norm_Vel    = (T3A_cfcp.(fn_T3A_cfcp{i}).U0x3A0)/Ufree(1);
%                     norm_y      =  T3A_cfcp.(fn_T3A_cfcp{i}).Points0x3A1./cordLength;
%             
%                     Graph.(fn_T3A_cfcp{i}) = plot(norm_Vel(range_index)+XscaleFactor*counter, ...
%                     norm_y(range_index)-YscaleFactor(counter),linS{LS});
%                  
%                     %********* The following three lines of code re-formats***
%                     %the data (obtained right above) in the way 'fill' can
%                     %use
%             
%                     UQbounds.(fn_T3A_cfcp{i}) = struct('x','y','reshape_x', 'reshape_y');%create a new struct
%                     
%                     UQbounds.(fn_T3A_cfcp{i}).reshape_x = reshape(norm_Vel(range_index)+XscaleFactor*counter, 1, []);
%                     UQbounds.(fn_T3A_cfcp{i}).reshape_y = reshape(norm_y(range_index), 1, []);
%                     
%                     UQbounds.(fn_T3A_cfcp{i}).x = norm_Vel(range_index);
%                     UQbounds.(fn_T3A_cfcp{i}).y = norm_y(range_index);
                    %*****************************************************
                    
                    
                    
                           %**** for debugging ****
                    %Info=(num2str(T3A_cfcp.(fn_T3A_cfcp{i}).wallShearStress0x3A1));
                    %disp(Info);
                    
                 
                    norm_Mean    = (UQSD7003_Mean.(fn_UQSD7003_Mean{i}).(FieldNames{i-1}{RANS_Mean_index}))./Ufree_UQSD7003;
                    

                    norm_x = UQSD7003_Mean.(fn_UQSD7003_Mean{i}).(FieldNames{i-1}{RANS_x_index})./CFD_cordLength;
                    norm_y = UQSD7003_Mean.(fn_UQSD7003_Mean{i}).(FieldNames{i-1}{RANS_y_index})./CFD_cordLength;
            
        
                    
                    Graph.(fn_UQSD7003_Mean{i}) = plot(norm_Mean(range_index)+XscaleFactor*counter, ...
                    norm_y(range_index)-YscaleFactor(counter),linS{LS-1});
                
                 
                    %********* The following three lines of code re-formats***
                    %the data (obtained right above) in the way 'fill' can
                    %use
            
%                     UQbounds.(fn_UQSD7003_Mean{i}) = struct('x', 'y','reshape_x', 'reshape_y');%create a new struct
                    
                    UQbounds.(fn_UQSD7003_Mean{i}).reshape_x = reshape(norm_x(range_index), 1, []);
                    UQbounds.(fn_UQSD7003_Mean{i}).reshape_y = reshape(norm_Mean(range_index), 1, []);
                    
                    UQbounds.(fn_UQSD7003_Mean{i}).x = norm_Mean(range_index);
                    UQbounds.(fn_UQSD7003_Mean{i}).y = norm_x(range_index);
                    %*****************************************************
                    
                    
                    
           
                    
                    %Graph.(fn_T3A_cfcp{i}) = plot(x_cordLength(99:341)+XscaleFactor(counter), ...
                    %norm_cfcp(99:341)-YscaleFactor(counter),linS{LS});
                
                
                    %Graph.(fn_T3A_cfcp{i}) = plot(x_cordLength(1:81), ...
                    %norm_cfcp(1:81),linS{LS});
                    
        
            end 
        
        
%           PTV.rot_x{counter}.(namept)=PTV.(namept)(:,1);
%     PTV.rot_y{counter}.(namept)=PTV.(namept)(:,2);
%     PTV.rot_u{counter}.(namept)=PTV.(namept)(:,3)*cos(Angrad)-...
%     PTV.(namept)(:,4)*sin(Angrad);
% 
%     PTV.rot_v{counter}.(namept)=PTV.(namept)(:,3)*sin(Angrad)+...
%     PTV.(namept)(:,4)*cos(Angrad);
        
        
        
        case exp %exp is works the similar way as does the DNS later consider to combine them using these if statements below
            
            Info=['File #',num2str(i-1),' File name:',fn_UQSD7003_Mean{i}];
            disp (Info);
            
            norm_Vel = UQSD7003_Mean.(fn_UQSD7003_Mean{i}).exp_u;
            %The following code was made for airfoil placed at AoA=8
%             u_ue = SD7003vel.(fn_SD7003Vel{i}).exp_u*cos(AoArad)-SD7003vel.(fn_SD7003Vel{i}).exp_v*sin(AoArad);
            norm_y = UQSD7003_Mean.(fn_UQSD7003_Mean{i}).exp_y;
            
            Graph.(fn_UQSD7003_Mean{i}) = plot(norm_Vel+XscaleFactor*counter, ...
            norm_y,linS{6});
        
%             Graph.(fn_SD7003Vel{i}) = plot(u_ue(yrange_exp{j})+XscaleFactor*counter, ...
%             y_cordLength(yrange_exp{j})-YscaleFactor_exp(j),linS{6});
       
    
        case DNS
            if isempty(lowercase_DNS_include)~=1 && strcmp('yes', lowercase_DNS_include) ==1 %for turning on/off DNS data
                if isempty(lowercase_geo_include)~=1 && strcmp('yes', lowercase_geo_include) ==1 %for changing positions of DNS data accordingly to adapt to the airfoil geometry
                    
                    DNS_counter = DNS_counter + 1;
                   
                    if DNS_counter > length(expressionDNSCtr)
                        DNS_counter = length(expressionDNSCtr) - 1;
                    end
                     Info = ['File #: ', num2str(i-1), ';  File name: ',fn_UQSD7003_Mean{i}, '; position on Geometry= ',expressionDNSCtr{DNS_counter}, ';   Minghan under DNS and LS= ', DNS_marker];
                    %Info = ['File #: ', num2str(i-1), ';  File name: ',fn_UQSD7003_Mean{i}, '; position on Geometry= ',expressionDNSCtr{DNS_counter}, ';   Minghan under DNS and LS= ', DNS_marker];
                    disp(Info);
                    
                 
                    
                    %DNS data in Original form
                    norm_x    = UQSD7003_Mean.(fn_UQSD7003_Mean{i}).(FieldNames{i-1}{DNS_norm_x_index});
                    norm_y    = UQSD7003_Mean.(fn_UQSD7003_Mean{i}).(FieldNames{i-1}{DNS_norm_y_index});
                    norm_Mean = UQSD7003_Mean.(fn_UQSD7003_Mean{i}).(FieldNames{i-1}{DNS_norm_Mean_index});
                    
                    Graph.(fn_UQSD7003_Mean{i}) = plot(norm_Mean + norm_x, norm_y, DNS_marker, 'MarkerFaceColor', DNS_MarkerFC); %much easier code than the obsolete version
                    
                    
                    %Modified version of the original data and stored in
                    %struct
                    %********** Jun 27th 2021 Added by Minghan - curve fitting for marker***********************************
                    if strcmp(Marker,'yes')
                             
                        %********* Jul 7th 2021 by Minghan Chu - Stored the original Ref data with horizontal or vertical shifts (used for marker)  **********          
                          %suction_indices = find(norm_y > 0); %get the indices for suction side of the geometry from the original data                                                 
                          RefData.(fn_UQSD7003_Mean{i}).y_c_wall        = min(norm_y); %from those indices get the corresponding min value which corresponds to the first cell above the wall                                          



                            RefData.(fn_UQSD7003_Mean{i}).norm_x        = norm_x;
                          if strcmp(lowercase_location,'geo')
                            RefData.(fn_UQSD7003_Mean{i}).norm_y        = norm_y;
                          elseif strcmp(lowercase_location,'o')
                            RefData.(fn_UQSD7003_Mean{i}).norm_y        = norm_y - RefData.(fn_UQSD7003_Mean{i}).y_c_wall; %shift all profiles from the suction surface to the origin, i.e. y_c=0
                          end
                            RefData.(fn_UQSD7003_Mean{i}).norm_Mean     = norm_Mean + norm_x;
                        



                        RefData.(fn_UQSD7003_Mean{i}).Ref_fit_indx = find(RefData.(fn_UQSD7003_Mean{i}).norm_y > fit_ypls_shiftOrigin & RefData.(fn_UQSD7003_Mean{i}).norm_y< fit_ypls_shiftOrigin_upper_limit);


                        RefData.(fn_UQSD7003_Mean{i}).norm_x_fitIndx    = RefData.(fn_UQSD7003_Mean{i}).norm_x(RefData.(fn_UQSD7003_Mean{i}).Ref_fit_indx);
                        RefData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx    = RefData.(fn_UQSD7003_Mean{i}).norm_y(RefData.(fn_UQSD7003_Mean{i}).Ref_fit_indx);
                        RefData.(fn_UQSD7003_Mean{i}).norm_Mean_fitIndx = RefData.(fn_UQSD7003_Mean{i}).norm_Mean(RefData.(fn_UQSD7003_Mean{i}).Ref_fit_indx);
                        %********* ********* ********* ********* ********* ********* ********* ********* ********* ****************************
                        
                        %One way of fitting - polyfit
                        RefData.(fn_UQSD7003_Mean{i}).p = polyfit(RefData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx,...
                                                                  RefData.(fn_UQSD7003_Mean{i}).norm_Mean_fitIndx, Ref_fit_polyvar);

                        RefData.(fn_UQSD7003_Mean{i}).y = polyval(RefData.(fn_UQSD7003_Mean{i}).p, RefData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx);

                        %A second way of fitting - fit (probably to be used for my research)
                        RefData.(fn_UQSD7003_Mean{i}).fitp = fit(RefData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx,...
                                                                 RefData.(fn_UQSD7003_Mean{i}).norm_Mean_fitIndx, Ref_fit_poly);
                        

                        %plot(RefData.(fn_UQSD7003_Mean{i}).y, RefData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx,'go-');
                        
                        fit_Ref_with_geo = plot(RefData.(fn_UQSD7003_Mean{i}).y, RefData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx,'--');
                        set (fit_Ref_with_geo,'color',manual_onoff_fit_DNS_color{i},'DisplayName',fn_UQSD7003_Mean{i},...
                                 'visible',visible,'HandleVisibility',manual_onoff_fit_DNS_led{i},'LineWidth',Linewidth,'MarkerSize',Markersize);
                    elseif strcmp(Marker,'no')
                        warning('Marker option is disabled!!! No fitting is made!!!')
                    end
                 %*****************************************************
                

                    %********* Jun 12 2021 by Minghan Chu obsolete code
                    %but left for purpose of learning******************
                 
%                     Graph.(fn_UQSD7003_Mean{i}) = plot(norm_Mean+(str2double(expressionDNSCtr{DNS_counter})/100*Ref_geo_factor*hori_multiplier), ...
%                     norm_y*verti_multiplier,DNS_marker, 'MarkerFaceColor', DNS_MarkerFC); %divide by 100 is due to the file naming of DNS data, check expressionDNSCtr 
%                 
%                     RefData.(fn_UQSD7003_Mean{i}).norm_Mean = norm_Mean+(str2double(expressionDNSCtr{DNS_counter})/100*Ref_geo_factor*hori_multiplier);
%                     RefData.(fn_UQSD7003_Mean{i}).norm_y = norm_y+YscaleFactor(counter);
                    %**************************************************
                    
                 
                     
                    
                else %no airfoil geometry included
                    Info = ['Under else File #: ', num2str(i-1), ';  File name: ',fn_UQSD7003_Mean{i}, ';   Minghan under DNS and LS= ', num2str(LS), '; Geometry is NOT included! '];
                    disp(Info);
                    
                    
                    %DNS data in Original form
                    %********* Jul 7th 2021 by Minghan Chu - Original raw Ref data without horizontal or vertical shifts (used to plot) **********   
                    
                    norm_x    = UQSD7003_Mean.(fn_UQSD7003_Mean{i}).(FieldNames{i-1}{DNS_norm_x_index});%not being used for now
                    norm_y    = UQSD7003_Mean.(fn_UQSD7003_Mean{i}).(FieldNames{i-1}{DNS_norm_y_index});       
                    norm_Mean = UQSD7003_Mean.(fn_UQSD7003_Mean{i}).(FieldNames{i-1}{DNS_norm_Mean_index});  
                    

                    
                    Graph.(fn_UQSD7003_Mean{i}) = plot(norm_Mean+XscaleFactor*counter, norm_y-YscaleFactor(counter), DNS_marker,'MarkerFaceColor', DNS_MarkerFC);
                    
                    
                    %Modified version of the original data and stored in
                    %struct 
                    %********** Jun 27th 2021 Added by Minghan - curve fitting for marker***********************************
                    if strcmp(Marker,'yes')
                             
                        %********* Jul 7th 2021 by Minghan Chu - Stored the original Ref data with horizontal or vertical shifts (used for marker)  **********   
                        RefData.(fn_UQSD7003_Mean{i}).y_c_wall        = min(norm_y); %from those indices get the corresponding min value which corresponds to the first cell above the wall                                          



                        RefData.(fn_UQSD7003_Mean{i}).norm_x        = norm_x;
                      if strcmp(lowercase_location,'geo')
                        RefData.(fn_UQSD7003_Mean{i}).norm_y        = norm_y;
                      elseif strcmp(lowercase_location,'o')
                        RefData.(fn_UQSD7003_Mean{i}).norm_y        = norm_y - RefData.(fn_UQSD7003_Mean{i}).y_c_wall; %shift all profiles from the suction surface to the origin, i.e. y_c=0
                      end
                        RefData.(fn_UQSD7003_Mean{i}).norm_Mean     = norm_Mean + XscaleFactor*counter;
                    



                        RefData.(fn_UQSD7003_Mean{i}).Ref_fit_indx = find(RefData.(fn_UQSD7003_Mean{i}).norm_y > fit_ypls_shiftOrigin & RefData.(fn_UQSD7003_Mean{i}).norm_y< fit_ypls_shiftOrigin_upper_limit);


                        RefData.(fn_UQSD7003_Mean{i}).norm_x_fitIndx    = RefData.(fn_UQSD7003_Mean{i}).norm_x(RefData.(fn_UQSD7003_Mean{i}).Ref_fit_indx);
                        RefData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx    = RefData.(fn_UQSD7003_Mean{i}).norm_y(RefData.(fn_UQSD7003_Mean{i}).Ref_fit_indx);
                        RefData.(fn_UQSD7003_Mean{i}).norm_Mean_fitIndx = RefData.(fn_UQSD7003_Mean{i}).norm_Mean(RefData.(fn_UQSD7003_Mean{i}).Ref_fit_indx);
                        %********* ********* ********* ********* ********* ********* ********* ********* ********* ****************************
                        
                        
                        %One way of fitting - polyfit
                        RefData.(fn_UQSD7003_Mean{i}).p = polyfit(RefData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx,...
                                                                  RefData.(fn_UQSD7003_Mean{i}).norm_Mean_fitIndx, Ref_fit_polyvar);

                        RefData.(fn_UQSD7003_Mean{i}).y = polyval(RefData.(fn_UQSD7003_Mean{i}).p, RefData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx);

                        %A second way of fitting - fit (probably to be used for my research)
                        RefData.(fn_UQSD7003_Mean{i}).fitp = fit(RefData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx ,...
                                                                 RefData.(fn_UQSD7003_Mean{i}).norm_Mean_fitIndx, Ref_fit_poly);


                    %plot(RefData.(fn_UQSD7003_Mean{i}).y, RefData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx,'go-');
                    
                    fit_Ref_without_geo = plot(RefData.(fn_UQSD7003_Mean{i}).y, RefData.(fn_UQSD7003_Mean{i}).norm_y_fitIndx,fit_Ref_LS);
                    set (fit_Ref_without_geo,'color',manual_onoff_fit_DNS_color{i},'DisplayName',fn_UQSD7003_Mean{i},...
                         'visible',manual_onoff_fit_DNS_visible{i},'HandleVisibility',manual_onoff_fit_DNS_led{i},'LineWidth',Linewidth,'MarkerSize',Markersize);
                     
                    elseif strcmp(Marker,'no')
                        warning('Marker option is disabled!!! No fitting is made!!!')
                    end
                 %*****************************************************
                
                end

            else
                
                if DNS_counter == 0 %for showing the warning message only once
                    warning_Info = { 'Reference data, e.g. DNS, are disabled by the user, i.e. [] '};

                    warning('%s', warning_Info{:});
                end
                
                DNS_counter = DNS_counter +1;
                
                continue %ensure to skip the current DNS data without breaking
            end
        
            
        otherwise
            
            continue
    
    end
     
     Info = ['File #: ', num2str(i-1), '  File name: ',fn_UQSD7003_Mean{i}, '   Minghan outside the loop "switch CASE{1}" and  CS= ', num2str(CS)];
     %Info = ['linC{CS}', num2str(CS)];
     disp(Info);
     disp(newline)      
%if you want to fix color/changing color for manual_repeat = on, just manually choose the following settings correctly
%I do not want to make the code dynamic which will need much more time
%involving!

        if (strcmp(Manual_repeat,'on') || strcmp(Manual_repeat,'off')) && backgroud_plots
                 set ( Graph.(fn_UQSD7003_Mean{i}),'color',backgroud_coor_plotting,'DisplayName',fn_UQSD7003_Mean{i},...
                    'visible',visible,'HandleVisibility',led,'LineWidth',Linewidth,'MarkerSize',Markersize);
        elseif strcmp(Manual_repeat,'on') || strcmp(Manual_repeat,'off')
             set ( Graph.(fn_UQSD7003_Mean{i}),'color',linC{CS},'DisplayName',fn_UQSD7003_Mean{i},...
                    'visible',visible,'HandleVisibility',led,'LineWidth',Linewidth,'MarkerSize',Markersize);
        end
%Special ticklabels specified by the user
% xticks(2.5:0.1*counter+1:xlimt(1,2));

end

%Add geometry
if isempty(lowercase_geo_include)~=1 && strcmp('yes', lowercase_geo_include) ==1 
  warning('Airfoil geometry having its cordlength of UNITY is inlcuded!')
  Geo = plot(mat.x, mat.y,geo_LS);

  set ( Geo,'color',geo_color,'DisplayName','SD7003',...
                    'visible',geo_visible,'HandleVisibility',geo_led,'LineWidth',geo_linewidth ,'MarkerSize',Markersize);

else
     warning_Info = { 'Geometry is not included, and profiles do not sit on the airfoil!'};

     warning('%s', warning_Info{:});
end

switch indicator
    case 'on'
        %indicator
        indicator_x = xlimt(1):0.02:xlimt(2);
        indicator_y = ones(1,length(indicator_x));
        indicator_y = 0.006*indicator_y;

        indicator = plot(indicator_x,indicator_y,':');
        set ( indicator,'color','r','DisplayName','y/c = 0.006',...
              'visible','on','HandleVisibility','on','LineWidth',2,'MarkerSize',Markersize);

    case 'off'
        warning('Indicator line is disabled!!!')
end

switch show_UQ_ranges
    case 'on'
        UQ_ranges_counter = 0; %put here to 
        
switch Manual_repeat
    case 'off'
        for ii = 2: length(fn_UQSD7003_Mean)
            
            if strcmp(UQ_CFD_capture, regexpi(fn_UQSD7003_Mean{ii}, expressionUQSD7003Mean{1,1}, 'match'))%avoid any reference data, e.g. DNS
                 CFDcapture=regexpi(fn_UQSD7003_Mean{ii}, expressionUQSD7003Mean{1,1}, 'match');

                if ii == Baseline
                    Info = ['Baseline ', num2str(ii)];
                    disp(Info);

                    continue %ensure to skip the baseline case


                else

                    Info = ['Under "manual_repeat = off" and File #: ', num2str(ii-1), ' CFDcapture ', CFDcapture];
                    disp(Info);

                    UQ_ranges_counter = UQ_ranges_counter +1; 
    %              
                        switch lowercase_UQ_color_changing
                            case 'yes'

                                 UB = fill ([UQbounds.(fn_UQSD7003_Mean{ii}).reshape_upper_y fliplr(UQbounds.(fn_UQSD7003_Mean{Baseline}).reshape_upper_y)], ...
                                                             [UQbounds.(fn_UQSD7003_Mean{ii}).reshape_upper_x fliplr(UQbounds.(fn_UQSD7003_Mean{Baseline}).reshape_upper_x)], UQBoundC{ii-1});
                                    set (UB, 'facealpha',transparency, 'DisplayName',fn_UQSD7003_Mean{ii},...
                                        'visible',UQbounds_visible,'HandleVisibility',UQled_visible,'LineStyle',UQbounds_LS);
                            case 'no'

                                switch fn_UQSD7003_Mean{ii}
                                    case UQled_control
                                        UQled_visible = 'on';
                                    otherwise
                                        UQled_visible = 'off';
                                end

                               UB = fill ([UQbounds.(fn_UQSD7003_Mean{ii}).reshape_upper_y fliplr(UQbounds.(fn_UQSD7003_Mean{Baseline}).reshape_upper_y)], ...
                                         [UQbounds.(fn_UQSD7003_Mean{ii}).reshape_upper_x fliplr(UQbounds.(fn_UQSD7003_Mean{Baseline}).reshape_upper_x)], stable_color);

                                 set (UB, 'facealpha',transparency, 'DisplayName',fn_UQSD7003_Mean{ii},...
                                    'visible',UQbounds_visible,'HandleVisibility',UQled_visible,'LineStyle',UQbounds_LS);

                        end

    %                 UB = fill ([UQbounds.(fn_UQSD7003_Mean{ii}).reshape_x fliplr(UQbounds.(fn_UQSD7003_Mean{Baseline}).reshape_x)], ...
    %                           [UQbounds.(fn_UQSD7003_Mean{ii}).reshape_y fliplr(UQbounds.(fn_UQSD7003_Mean{Baseline}).reshape_y)], UQBoundC{ii-1});


     %                   end 
                end 

    %                  set (UB, 'facealpha',transparency, 'DisplayName',fn_UQSD7003_Mean{ii},...
    %                         'visible',UQbounds_visible,'HandleVisibility',UQled_visible,'LineStyle',UQbounds_LS);

            else
                continue
            end
        
       end
    
    case 'on'
      
    for jj = 1 : length(Baseline)%maybe change this to sth written of length(fn_UQSD7003_cfcp) later
        
       
        for ii = 2 : length(fn_UQSD7003_Mean)
            
         if strcmp(UQ_CFD_capture, regexpi(fn_UQSD7003_Mean{ii}, expressionUQSD7003Mean{1,1}, 'match'))%avoid any reference data, e.g. DNS
             CFDcapture=regexpi(fn_UQSD7003_Mean{ii}, expressionUQSD7003Mean{1,1}, 'match');

            
            UQbds = regexpi(fn_UQSD7003_Mean{ii}, expressionUQboundsCtr{1,jj}, 'match'); %important condition may or may not match
            %disp(UQbds)
            for kk = 1:length(expressionUQboundsCtr)
                types = regexpi(fn_UQSD7003_Mean{ii}, expressionUQboundsCtr{1,kk}, 'match');%will always match
                %disp(types)
                if isempty(types)~=1
                    TYPE = types;
                    %disp(TYPE)
                    break
                elseif isempty(types)==1
                    TYPE = {'continue'};

                end
            end
   
                 switch TYPE{1}
                     case UQbds

                        if ii == Baseline(jj)
                        %disp(ii)
                            continue %ensure to skip the baseline case
                        else
                            %Info = ['Minghan repeat at ', num2str(ii)];
                            %disp(Info)

                            UQ_ranges_counter = UQ_ranges_counter +1;

                            Info = ['Under "manual_repeat = on" and File #: ', num2str(ii-1), ' CFDcapture ', CFDcapture];
                            disp(Info);




                            switch lowercase_UQ_color_changing
                                case 'yes'
                                    UB = fill ([UQbounds.(fn_UQSD7003_Mean{ii}).reshape_upper_y fliplr(UQbounds.(fn_UQSD7003_Mean{Baseline(jj)}).reshape_upper_y)], ...
                                            [UQbounds.(fn_UQSD7003_Mean{ii}).reshape_upper_x fliplr(UQbounds.(fn_UQSD7003_Mean{Baseline(jj)}).reshape_upper_x)], UQBoundC{ii-1});

                                        set (UB, 'facealpha',transparency, 'DisplayName',fn_UQSD7003_Mean{ii},...
                                            'visible',UQbounds_visible,'HandleVisibility',UQled_visible,'LineStyle',UQbounds_LS);
                                case 'no'
                                    switch fn_UQSD7003_Mean{ii}
                                        case UQled_control
                                            UQled_visible = 'on';
                                        otherwise
                                            UQled_visible = 'off';
                                    end

                                   UB = fill ([UQbounds.(fn_UQSD7003_Mean{ii}).reshape_upper_y fliplr(UQbounds.(fn_UQSD7003_Mean{Baseline(jj)}).reshape_upper_y)], ...
                                            [UQbounds.(fn_UQSD7003_Mean{ii}).reshape_upper_x fliplr(UQbounds.(fn_UQSD7003_Mean{Baseline(jj)}).reshape_upper_x)], stable_color);



                                    set (UB, 'facealpha',transparency, 'DisplayName',fn_UQSD7003_Mean{ii},...
                                            'visible',UQbounds_visible,'HandleVisibility',UQled_visible,'LineStyle',UQbounds_LS);

                            end 


                        end

                     otherwise

                        continue

                end
                       
%          set (UB, 'facealpha',transparency, 'DisplayName',fn_UQSD7003_Mean{ii},...
%             'visible',UQbounds_visible,'HandleVisibility',UQled_visible,'LineStyle',UQbounds_LS);

          else
                continue
          end
            
        end
        
        
    end 
end 
    case 'off'
        disp(newline);
        warning('UQ ranges are turned off!');
end 
           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    

set(gcf, 'Units', 'Inches', 'Position',  figure_size)
hold off

warning('on');
warning('If you see big chuncks of UQ ranges instead of clear disdinct ranges on each profile, recheck your input for "NumOfDataSets" !');



PWC = gca; % current axes
box on;

%set(PWC, 'XColor', 'r')

  %  title('My title','position',[titlepos.(fn_UQSD7003_Mean{t}).x 0.02])

% if isempty(lowercase_geo_include)~=1 && strcmp('yes', lowercase_geo_include) ==1 
%     xlimt = [-0.5 5];
%     ylimt = [0 0.1];
% else
%     %xlim and ylim
%     disp('You are here')
%     ylimt = [0.05 0.08];
%     xlimt = [-0.03 0.09];
% end

PWC.YLim = ylimt;
PWC.XLim = xlimt;

%axis labeling
% y_MinorTick = 0.001;
% x_MinorTick = 0.004;
% 
% y_Tick = 0.005;
% x_Tick = 0.02;

%ticks on/off
PWC.XAxis.MinorTick = xMinorTick;
PWC.XAxis.MinorTickValues = xlimt(1):x_MinorTick:xlimt(2);
PWC.YAxis.MinorTick = yMinorTick;
PWC.YAxis.MinorTickValues = ylimt(1):y_MinorTick:ylimt(2);


%xscale e.g. linear or log
xscale ='linear';
PWC.XScale = xscale;

%specify the range and name of coordinates
PWC.FontSize = TLsize;
PWC.TickDir = 'in';



%add legend
warning(warningMsg_Matlab)
if strcmp(DNS_fit,'on')
    l=legend('$\mathrm{DNS}_{actual}$','Poly7','Poly7','Poly7','location','northeast','interpreter','latex','color',legTransparency);

elseif strcmp(RANS_fit,'on')
    l=legend('$\mathrm{RANS}_{actual}$','Poly7','Poly7','Poly7','location','northeast','interpreter','latex','color',legTransparency);
end 
l.FontSize = Lsize;
legend boxoff
%legend on
warning('on')

%ticks length
% ticklen = [0.01 0.04]; 
PWC.TickLength = ticklen;



%captions
if strcmp(lowercase_location,'o')
    xlabel('$k/U_{\infty}^2$', 'FontSize', Csize,'interpreter','latex');
    ylabel('$y/c|_{o}$', 'FontSize', Csize,'interpreter','latex');
elseif strcmp(lowercase_location,'geo')
    ylabel('$y/c$', 'FontSize', Csize,'interpreter','latex');
end




%******ticks spacing******
%This is the special ticks whose limit is not same as the specified xlimit
%to ensure proper tick positions
% xticks(2.8:1.62:11);
%******ticks spacing******
%This is the special ticks whose limit is not same as the specified xlimit
%to ensure proper tick positions, this tick specification is dynamic and
%the user can add a "if" statement to switch between this dynamic version
%to the static version

 switch Manual_repeat
    case 'on'
        if isempty(lowercase_geo_include)~=1 && strcmp('yes', lowercase_geo_include) ==1 
    %         Tick_start = XscaleFactor+Tick_start_correct;
    %         Tick_end = Tick_start+NumOfdataSets*XscaleFactor;
    %         Tick_interval = XscaleFactor+0.001; %0.001 is for purpose of correction
    % %         xticks(Tick_start:Tick_interval:Tick_end);
    %         
             yticks(ylimt(1,1):y_Tick:ylimt(1,2));
    %         
    %       



            %hide x ticks and labels (Minor ticks will not be turned off)
            %set(PWC,'xtick',[]);
            %hide y labels but show ticks
            %set(PWC,'yticklabel',[]);

            %title('x/c =', 'Position',[0.05 ylimt(1,2)+0.0010],'interpreter','latex','Color','k')



            %set(PWC, 'XColor','k', 'xtick',[0.1 0.15 0.2 0.3 0.4 0.5 0.6] )
            set(PWC, 'XColor','k', 'xtick',[0.14 0.17 0.192 0.30 0.32 0.60] )


            set(PWC, 'XTickLabel', {'a','b','c','d','e','f'});
            %set(PWC, 'XTickLabel', []);%if no labels are needed!
            
            xtickangle(0)
            PWC.XAxisLocation = 'top';
            PWC.YAxisLocation = 'left';
        else%no geometry included!
            Tick_start = XscaleFactor+Tick_start_correct;
            Tick_end = Tick_start+NumOfdataSets*XscaleFactor;
            Tick_interval = XscaleFactor+0.001; %0.001 is for purpose of correction
            xticks(Tick_start:Tick_interval:Tick_end);

            yticks(ylimt(1,1):y_Tick:ylimt(1,2));
            
            %hide x ticks and labels (Minor ticks will not be turned off)
            %set(PWC,'xtick',[]);
            %hide y labels but show ticks
            %set(PWC,'yticklabel',[]);
            
            %**** for downstream ef zone *****
%             set(PWC, 'XColor','k', 'xtick',[0.72 0.89 1.3] )
%             set(PWC,'XTickLabel', {'e','mid','f'});
%             xtickangle(0)
%             PWC.XAxisLocation = 'top';
%             PWC.YAxisLocation = 'left';
            %**********************************
            
            %axis labeling
            xticks(xlimt(1,1):x_Tick:xlimt(1,2));%only for shift_to_origin otherwise COMMENTTED OUT! And UNCOMMENT the block above for ef zone!
        end
        
     case 'off'
  
         
    %The following is the classic xticks, i.e. showing labels for ticks
        yticks(ylimt(1,1):y_Tick:ylimt(1,2));
        xticks(xlimt(1,1):x_Tick:xlimt(1,2));
        
        %hide x ticks and labels (Minor ticks will not be turned off)
        %set(PWC,'xtick',[]);
        %hide y labels but show ticks
        %set(PWC,'yticklabel',[]);
 end








%%

%****************** User Input Sep 16 2022 ******************
zone = 'cd';%'ab','cd','ef'
errorfun.n = 7; %errorfun.n = 6 for index starts at 2: x_c = 0.14 to 0.19 to avoid the negative value of k after fitting
%****************** User Input ******************



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Jul 14th 2021 by Minghan Chu average
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%Note there are three different types of fitted polynominals
%1. on 7th degree polynominal for fitted curves at each individual position
%in the main block of code (if you want to change this degree you must change the poly7 function accordingly, however 7th degree should be sufficient for my study!)
%2. on 5th degree polynominal for fitted curves for averaged RANS and DNS
%in the current block of code
%3. on th degree polynominal for the error data (averaged RANS - averaged
%DNS) in the current block of code which is the Final goal: the error function within a certain range


lns1	 = {'-k';'-.r';'--b';'go-';'ko-';'ks-';'kx-';'kd-';'k^-'};
% lns2	 = {'-r';'-.r';'--r';':r';'ro-';'rs-';'rx-';'rd-';'r^-'};
% lns3	 = {'-g';'-.g';'--g';':g';'go-';'gs-';'gx-';'gd-';'g^-'};
% lns4	 = {'-b';'-.b';'--b';':b';'bo-';'bs-';'bx-';'bd-';'b^-'};

switch zone
    case 'ab'
        RANSfit.fileIndx_start = 2;%7,19,2
        RANSfit.num_sets       = 5;%User needs to specify the number of sets for RANS data, i.e. 12,15,5
        Reffit.num_sets        = 5;%User needs to specify the number of sets for RANS data, i.e. 12,15,5
        fit_xlimt           = [0 0.05];%[0 0.05] [0 0.05]
        fit_ylimt           = [-0.05 0.15];%[-0.05 0.2] [-0.05 0.15]
        title('(a)', 'Position',[0.002 0.135],'interpreter','latex');

    case 'cd'
        RANSfit.fileIndx_start = 7;%7,19,2
        RANSfit.num_sets       = 12;%User needs to specify the number of sets for RANS data, i.e. 12,15,5
        Reffit.num_sets        = 12;%User needs to specify the number of sets for RANS data, i.e. 12,15,5
        fit_xlimt              = [0 0.05];%[0 0.05] [0 0.05]
        fit_ylimt              = [-0.05 0.2];%[-0.05 0.2] [-0.05 0.15]     
        title('(b)', 'Position',[0.002 0.185],'interpreter','latex');
    case 'ef'
        RANSfit.fileIndx_start = 19;%7,19,2
        RANSfit.num_sets       = 15;%User needs to specify the number of sets for RANS data, i.e. 12,15,5
        Reffit.num_sets        = 15;%User needs to specify the number of sets for RANS data, i.e. 12,15,5
        fit_xlimt              = [0 0.05];%[0 0.05] [0 0.05]
        fit_ylimt              = [-0.05 0.15];%[-0.05 0.2] [-0.05 0.15]
        title('(c)', 'Position',[0.002 0.135],'interpreter','latex');
end




RANSfit.fileIndx_end   = RANSfit.fileIndx_start + RANSfit.num_sets - 1;
%RANSfit.n              = 5;                                                                     
                                                                     
Reffit.fileIndx_start  = RANSfit.fileIndx_start + half_total_files;

Reffit.fileIndx_end    = Reffit.fileIndx_start + Reffit.num_sets - 1;


figureSize = [0, 0, 20, 20];



RANSfit.y_c = fit_ypls_shiftOrigin:0.001:fit_ypls_shiftOrigin_upper_limit;%re-specifying the range of y_c and substituting into each fitted function for 
                                                                          %different positions to produce same amount of data at those individual positions  

                                                                          
Reffit.y_c = RANSfit.y_c;%DNS and RANS have the same range in y_c and same points are used as well

RANSfit.y_c = sort(RANSfit.y_c,'descend');
Reffit.y_c  = RANSfit.y_c;

%plot
Lsize        = 45; %legend size
Csize        = 55; %caption size
TLsize       = 45; %label size


fit_LineWidth       = 2.0;                      ave_MarkerSize      = 20;
fit_MarkerSize      = 15;                       ave_LineWidth       = 2;



%Ref_Marker          = '--';                    
                                                DNS_color                     = [0 0 0] + 0.5;
                                                SSTLM_color                   = [0 0 0];
fit_visible         = 'on';                     ave_fit_visible               = 'on';
                                                ave_Ref_MarkerFaceColor       = 'r';%'r'
fit_xMinorTick      = 'on';                     ave_RANS_MarkerFaceColor      = 'g' ;%'g'
fit_yMinorTick      = 'on';                     ave_Ref_MarkerEdgeColor       = DNS_color;
                                                ave_RANS_MarkerEdgeColor      = SSTLM_color;
                                                
                                                
                                                SSTLM_LS                      = '--';
                                                DNS_LS                        = '-';
fit_x_Tick          = 0.01;
fit_x_MinorTick     = fit_x_Tick/5;

fit_y_Tick          = 0.05;
fit_y_MinorTick     = fit_y_Tick/5;




fit_led_visible = cell(1,RANSfit.num_sets);     ave_fit_led_visible = 'on';
for l = 1:RANSfit.num_sets 
    if l == 1
        fit_led_visible{l}     = 'on';
    
    else
        fit_led_visible{l}     = 'off';
    end
    
    
end




hold on
% f1 = figure;
% f2 = figure;


%poly7 is not an inherent function in Matlab but user-created to represent
%the fitted polynomial in degree 7
for i=RANSfit.fileIndx_start:RANSfit.fileIndx_end
    RANSfit.(fn_UQSD7003_Mean{i}).k_u2 = poly7(RANSfit.y_c', RANS_fit_polyvar, RANSData.(fn_UQSD7003_Mean{i}).p(1),...
                                                                               RANSData.(fn_UQSD7003_Mean{i}).p(2),...
                                                                               RANSData.(fn_UQSD7003_Mean{i}).p(3),...
                                                                               RANSData.(fn_UQSD7003_Mean{i}).p(4),...
                                                                               RANSData.(fn_UQSD7003_Mean{i}).p(5),...
                                                                               RANSData.(fn_UQSD7003_Mean{i}).p(6),...
                                                                               RANSData.(fn_UQSD7003_Mean{i}).p(7),...
                                                                               RANSData.(fn_UQSD7003_Mean{i}).p(8));

    if i == RANSfit.fileIndx_start
        disp(i)
        RANSfit.sum = RANSfit.(fn_UQSD7003_Mean{i}).k_u2;
    elseif i > RANSfit.fileIndx_start && i <= RANSfit.fileIndx_end
        disp(i)
        RANSfit.sum = RANSfit.sum + RANSfit.(fn_UQSD7003_Mean{i}).k_u2;
    end
    
    if i==RANSfit.fileIndx_end
        disp(i)
        RANSfit.ave = RANSfit.sum./(RANSfit.fileIndx_end-RANSfit.fileIndx_start+1);
    end
    
%     plot(RANSfit.(fn_UQSD7003_Mean{i}).k_u2,RANSfit.y_c','ko-')
     RANSpoly = plot(RANSfit.y_c', RANSfit.(fn_UQSD7003_Mean{i}).k_u2,SSTLM_LS);
     set ( RANSpoly,'visible',fit_visible,'HandleVisibility',fit_led_visible{i-RANSfit.fileIndx_start+1},...
         'color',SSTLM_color,'LineWidth',fit_LineWidth,'MarkerSize',fit_MarkerSize, 'DisplayName','RANS');
end


for i=Reffit.fileIndx_start:Reffit.fileIndx_end
    Reffit.(fn_UQSD7003_Mean{i}).k_u2 = poly7(Reffit.y_c', Ref_fit_polyvar,    RefData.(fn_UQSD7003_Mean{i}).p(1),...
                                                                               RefData.(fn_UQSD7003_Mean{i}).p(2),...
                                                                               RefData.(fn_UQSD7003_Mean{i}).p(3),...
                                                                               RefData.(fn_UQSD7003_Mean{i}).p(4),...
                                                                               RefData.(fn_UQSD7003_Mean{i}).p(5),...
                                                                               RefData.(fn_UQSD7003_Mean{i}).p(6),...
                                                                               RefData.(fn_UQSD7003_Mean{i}).p(7),...
                                                                               RefData.(fn_UQSD7003_Mean{i}).p(8));

    if i == Reffit.fileIndx_start
        disp(i)
        Reffit.sum = Reffit.(fn_UQSD7003_Mean{i}).k_u2;
    elseif i > Reffit.fileIndx_start && i <= Reffit.fileIndx_end
        disp(i)
        Reffit.sum = Reffit.sum + Reffit.(fn_UQSD7003_Mean{i}).k_u2;
    end
    
    if i==Reffit.fileIndx_end
        disp(i)
        Reffit.ave = Reffit.sum./(Reffit.fileIndx_end-Reffit.fileIndx_start+1);
    end
    
    %plot(Reffit.(fn_UQSD7003_Mean{i}).k_u2, Reffit.y_c','go-')
    Refpoly = plot(Reffit.y_c', Reffit.(fn_UQSD7003_Mean{i}).k_u2, DNS_LS);
    set ( Refpoly,'visible',fit_visible,'HandleVisibility',fit_led_visible{i-Reffit.fileIndx_start+1},...
        'color',DNS_color,'LineWidth',fit_LineWidth,'MarkerSize',fit_MarkerSize, 'DisplayName','DNS');
end



errorfun.data = Reffit.ave./RANSfit.ave;
errorfun.positive_data = abs(errorfun.data);%get rid of unphysical negative value of k
errorfun.y_c = RANSfit.y_c';

%**********************manually fix thosse outliers!!! Do not waste time on dynamic coding!!! 
%********************for 0.14 < x_c < 0.18 (y_boundary_upperlimit = 0.01), outliers are at indices: 33, 34, 43
switch zone
    case 'ab'
        errorfun.positive_data(15) = 0.2;
        errorfun.positive_data(24) = 0.9;

%********************for 0.19 < x_c < 0.3 (y_boundary_upperlimit = 0.012), outliers are at indices: 33, 34, 43
% 
    case 'cd'
        errorfun.positive_data(19) = 5;
        errorfun.positive_data(28) = 6;
        errorfun.positive_data(29) = 7;

%**********************manually change the outliers!!! Do not waste time on dynamic coding!!! 
%********************for 0.32 < x_c < 0.6 (y_boundary_upperlimit = 0.01 ), outliers are at indices: 33, 34, 43
% 
    case 'ef'

% 
        errorfun.positive_data(1) = 10;
        errorfun.positive_data(51)= 10;
end

%Polynomial fit
errorfun.p = polyfit(Reffit.y_c', errorfun.positive_data, errorfun.n);
errorfun.y = polyval(errorfun.p, Reffit.y_c');

%Fourier series fit
errorfun.FF = fit(Reffit.y_c', errorfun.positive_data,'fourier2');

%mathematical fitting may produce negative values of k, you need to make it
%physical by getting the absolute values

%errorfun.positive_y = abs(errorfun.y); %Never do this, because your fitted
%function is not changing! So just manipulate the polynominal order to get
%all positive values of k


ave_RANS = plot(RANSfit.y_c', RANSfit.ave,'s-');
ave_Ref = plot(Reffit.y_c', Reffit.ave, 'o-');



hold off
set(gcf, 'Units', 'Inches', 'Position',  figureSize)

box on;
errorfit = gca;

l = legend('interpreter','latex');
l.FontSize = Lsize;
legend boxoff
%specify the range and name of coordinates
errorfit.FontSize = TLsize;

errorfit.YLim = fit_ylimt ;
errorfit.XLim = fit_xlimt;

%Ticks on/off
yticks(fit_ylimt(1,1):fit_y_Tick:fit_ylimt(1,2));
xticks(fit_xlimt(1,1):fit_x_Tick:fit_xlimt(1,2));

%Minorticks on/off
errorfit.XAxis.MinorTick = fit_xMinorTick;
errorfit.XAxis.MinorTickValues = fit_xlimt(1,1):fit_x_MinorTick:fit_xlimt(1,2);
errorfit.YAxis.MinorTick = fit_yMinorTick;
errorfit.YAxis.MinorTickValues = fit_ylimt(1,1):fit_y_MinorTick:fit_ylimt(1,2);

%set ( fit_curve,'visible',fit_visible,'HandleVisibility',fit_led_visible,'LineWidth',Linewidth,'MarkerSize',fit_MarkerSize);
set (ave_RANS,'color',SSTLM_color,'visible',ave_fit_visible,'HandleVisibility',ave_fit_led_visible,'MarkerSize',ave_MarkerSize,...
    'MarkerFaceColor', ave_RANS_MarkerFaceColor,'MarkerEdgeColor',ave_RANS_MarkerEdgeColor,'LineWidth',ave_LineWidth, 'DisplayName','Averaged RANS');

set (ave_Ref,'color',DNS_color,'visible',ave_fit_visible,'HandleVisibility',ave_fit_led_visible,'MarkerSize',ave_MarkerSize,...
    'MarkerFaceColor', ave_Ref_MarkerFaceColor,'MarkerEdgeColor',ave_Ref_MarkerEdgeColor,'LineWidth',ave_LineWidth,'DisplayName','Averaged DNS');


xlabel('$y/c|_{o}$', 'FontSize', Csize,'interpreter','latex');
ylabel('$k/U^2_{\infty}$', 'FontSize', Csize,'interpreter','latex');
%%

CF_lsize              = 60;
error_LineWidth       = 2;                      
error_MarkerSize      = 20;  
ref_MarkerSize        = 50;
Ref_error_legend      = 'on';
Poly_error_legend     = 'on';

error_MarkerFaceColor = 'b';
error_color           = 'r-';

%Ref_Marker          = '--';
Ref_error_visible     = 'on';   
Poly_error_visible    = 'on'; 

                                               
error_xMinorTick      = 'on';                     
error_yMinorTick      = 'on';

error_x_Tick          = 0.01;%0.01
error_x_MinorTick     = error_x_Tick/5;



error_xlimt           = fit_xlimt;%[0 0.06],[0 0.05] [0 0.05]

switch zone
    case 'ab'
        error_ylimt           = [0 2.5];%[0 15] [0 8] [0 2.5]
        error_y_Tick          = 0.5;%0.5,2,5
        error_y_MinorTick     = error_y_Tick/5;
        title('(a)', 'Position',[0.002 2.35],'interpreter','latex');
    case 'cd'
        error_ylimt           = [0 8];%[0 15] [0 8] [0 2.5]
        error_y_Tick          = 2;%0.5,2,5
        error_y_MinorTick     = error_y_Tick/5;
        title('(b)', 'Position',[0.002 7.5],'interpreter','latex');
    case 'ef'
        error_ylimt           = [0 15];%[0 15] [0 8] [0 2.5]
        error_y_Tick          = 5;%0.5,2,5
        error_y_MinorTick     = error_y_Tick/5;
        title('(c)', 'Position',[0.002 14],'interpreter','latex');

end




%title('(a)', 'Position',[0.002 2.35],'interpreter','latex');
%title('(b)', 'Position',[0.002 7.5],'interpreter','latex');
%title('(c)', 'Position',[0.002 14],'interpreter','latex');

hold on

switch zone
    case 'ab'
        Ref_data = plot(errorfun.y_c, errorfun.positive_data, '.');
        deltaFun_poly = plot(errorfun.y_c, errorfun.y, error_color);
    case 'ef'
        Ref_data = plot(errorfun.y_c, errorfun.positive_data, '.');
        deltaFun_poly = plot(errorfun.y_c, errorfun.y, error_color);
    case 'cd'
        Ref_data_Fourier = plot(errorfun.y_c, errorfun.positive_data, '.',DisplayName',' discrepancy data','Color','b');
        deltaFun_fourier = plot(errorfun.FF, Reffit.y_c', errorfun.positive_data);
end

hold off

set(gcf, 'Units', 'Inches', 'Position',  figureSize)

box on;
ErrorFun = gca;

l = legend('interpreter','latex');
l.FontSize = CF_lsize;
legend boxoff
%specify the range and name of coordinates
ErrorFun.FontSize = TLsize;

ErrorFun.YLim = error_ylimt;
ErrorFun.XLim = error_xlimt;

%Ticks on/off
yticks(error_ylimt(1,1):error_y_Tick:error_ylimt(1,2));
xticks(error_xlimt(1,1):error_x_Tick:error_xlimt(1,2));

%Minorticks on/off
ErrorFun.XAxis.MinorTick = error_xMinorTick;
ErrorFun.XAxis.MinorTickValues = error_xlimt(1,1):error_x_MinorTick:error_xlimt(1,2);
ErrorFun.YAxis.MinorTick = error_yMinorTick;
ErrorFun.YAxis.MinorTickValues = error_ylimt(1,1):error_y_MinorTick:error_ylimt(1,2);

switch zone
    case 'ab'
        set (Ref_data,'visible',Ref_error_visible ,'HandleVisibility',Ref_error_legend,'MarkerSize',ref_MarkerSize,...
            'LineWidth',error_LineWidth,'DisplayName',' discrepancy data','Color','b');

        set (deltaFun_poly,'visible',Poly_error_visible ,'HandleVisibility',Poly_error_legend,'MarkerSize',error_MarkerSize ,...
            'MarkerFaceColor', error_MarkerFaceColor,'LineWidth',error_LineWidth,'DisplayName','marker function (Poly7)');
    case 'ef'
        set (Ref_data,'visible',Ref_error_visible ,'HandleVisibility',Ref_error_legend,'MarkerSize',ref_MarkerSize,...
            'LineWidth',error_LineWidth,'DisplayName',' discrepancy data','Color','b');

        set (deltaFun_poly,'visible',Poly_error_visible ,'HandleVisibility',Poly_error_legend,'MarkerSize',error_MarkerSize ,...
            'MarkerFaceColor', error_MarkerFaceColor,'LineWidth',error_LineWidth,'DisplayName','marker function (Poly7)');
    case 'cd'
        set (Ref_data_Fourier,'visible',Ref_error_visible ,'HandleVisibility',Ref_error_legend,'MarkerSize',ref_MarkerSize,...
            'LineWidth',error_LineWidth,'DisplayName',' discrepancy data','Color','b');

        set (deltaFun_fourier,'visible','on' ,'HandleVisibility','on','MarkerSize',error_MarkerSize ,...
            'MarkerFaceColor', 'b','LineWidth',error_LineWidth, 'MarkerEdgeColor','b', 'DisplayName','correction factor');
end

xlabel('$y/c|_{o}$', 'FontSize', Csize,'interpreter','latex');
ylabel('$CF_{k}$', 'FontSize', Csize,'interpreter','latex');

%%
% %%%%%%%%%%%%%%%%%%%%%%%% The following sections are all for marker study %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %*********************** Jul 5 2021 Interpolation for averaged RANS data *************************
% 
% lns1	 = {'-k';'-.r';'--b';':g';'ko-';'ks-';'kx-';'kd-';'k^-'};
% % lns2	 = {'-r';'-.r';'--r';':r';'ro-';'rs-';'rx-';'rd-';'r^-'};
% % lns3	 = {'-g';'-.g';'--g';':g';'go-';'gs-';'gx-';'gd-';'g^-'};
% % lns4	 = {'-b';'-.b';'--b';':b';'bo-';'bs-';'bx-';'bd-';'b^-'};
% 
% RANS_fileIndx_start = 7;
% num_RANSsets_forAve = 12;%User needs to specify the number of sets for RANS data
% RANS_fileIndx_end = RANS_fileIndx_start + num_RANSsets_forAve - 1;
% RANS_figure_size = [0, 0, 20, 20];
% 
%                   
%                         
% 
% RANS_fit_ptsNum = zeros(num_RANSsets_forAve,1);
% for interp = RANS_fileIndx_start:RANS_fileIndx_end %plus 1 because start at 2
%    
%     Interp_x_RANS.(fn_UQSD7003_Mean{interp})   = RANSData.(fn_UQSD7003_Mean{interp}).norm_y_fitIndx;
%     Interp_y_RANS.(fn_UQSD7003_Mean{interp})   = RANSData.(fn_UQSD7003_Mean{interp}).norm_Mean_fitIndx;
%     RANS_fit_ptsNum                            = structfun(@length,Interp_x_RANS);
%     %disp(Interp_x_RANS.(fn_UQSD7003_Mean{interp}))
% end
% 
% test = fit_ypls_shiftOrigin:0.0004:fit_ypls_shiftOrigin_upper_limit;             
% 
% 
% 
% lmax = max(RANS_fit_ptsNum);
% 
% 
% Interp_RANS_indx = find(RANS_fit_ptsNum == lmax,1,'first') + RANS_fileIndx_start - 1;%-1 because inerp start counting at 2
%  
% % %the following two lines of code will ensure same nontrivial length of data
% % %when plotting
% % Interp_Ref_firstIndx = find(Interp_y_Ref.(fn_UQSD7003_Mean{Interp_Ref_indx}),1,'first');%in this case first and last points are two extra data compared to the rest
% % Interp_Ref_lastIndx = find(Interp_y_Ref.(fn_UQSD7003_Mean{Interp_Ref_indx}),1,'last');
% % 
% % %Assign nan to it to keep consistent length with the rest
% % Interp_y_Ref.(fn_UQSD7003_Mean{Interp_Ref_indx})(Interp_Ref_firstIndx) = nan;
% % Interp_y_Ref.(fn_UQSD7003_Mean{Interp_Ref_indx})(Interp_Ref_lastIndx) = nan;
% 
% 
% 
% Interp_count = 0;
% for interp = RANS_fileIndx_start:RANS_fileIndx_end%plus 1 because start at 2
%    
%     if interp == Interp_RANS_indx
%         Info = ['Using interp == Interp_indx(',num2str(Interp_RANS_indx),') as the reference for interpolation; fn_UQSD7003_Mean{' ,num2str(interp),'} = ',fn_UQSD7003_Mean{interp}];
%         disp(Info)
%     end
%     
%     Interp_RANSnew_y.(fn_UQSD7003_Mean{interp}) = interp1(Interp_x_RANS.(fn_UQSD7003_Mean{interp}), Interp_y_RANS.(fn_UQSD7003_Mean{interp}), Interp_x_RANS.(fn_UQSD7003_Mean{Interp_RANS_indx}));
% 
%     %Interp_RANSnew_y.(fn_UQSD7003_Mean{interp}) = interp1(Interp_x_RANS.(fn_UQSD7003_Mean{interp}), Interp_y_RANS.(fn_UQSD7003_Mean{interp}), test);
% 
%     RANS_nan_index = find(isnan(Interp_RANSnew_y.(fn_UQSD7003_Mean{interp})));%get indices of nan 
%     
%     if Interp_count == 0
%         sum_y = Interp_RANSnew_y.(fn_UQSD7003_Mean{interp});
%       
%     elseif Interp_count > 0
%         sum_y = Interp_RANSnew_y.(fn_UQSD7003_Mean{interp}) + sum_y;
%     end
%   
%     
%     Interp_count = Interp_count +1;
%     
% end
% 
% for replace = 1:length(RANS_nan_index)%replace the corresponding indices of the Reference data (used to interpolate the rest) with nan
%    Interp_RANSnew_y.(fn_UQSD7003_Mean{Interp_RANS_indx})(RANS_nan_index(replace)) = nan; 
% end
% 
% ave_y_RANS = sum_y/num_RANSsets_forAve;
% 
% 
% fit_MarkerSize      = 10;
% %Ref_Marker          = '.';
% fit_visible         = 'on';
% fit_led_visible     = 'on';
% fit_xMinorTick      = 'on';
% fit_yMinorTick      = 'on';
% 
% fit_x_Tick          = 0.01;
% fit_x_MinorTick     = fit_x_Tick/5;
% 
% fit_y_Tick          = 0.04;
% fit_y_MinorTick     = fit_y_Tick/5;
% 
% fit_xlimt           = [0.055 0.15];
% fit_ylimt           = [-0.01 0.15];
% 
% 
% hold on
% avey_curve_RANS = plot(Interp_x_RANS.(fn_UQSD7003_Mean{Interp_RANS_indx}),ave_y_RANS,'gs-');
% %avey_curve_RANS = plot(test,ave_y_RANS,'gs-');
% 
% set (avey_curve_RANS,'visible',fit_visible,'HandleVisibility',fit_led_visible,'LineWidth',Linewidth,'MarkerSize',fit_MarkerSize,...
%     'DisplayName','Average data');
% 
% for interp = RANS_fileIndx_start:RANS_fileIndx_end
%     
%     Interp_curve_RANS = plot(Interp_x_RANS.(fn_UQSD7003_Mean{Interp_RANS_indx}), Interp_RANSnew_y.(fn_UQSD7003_Mean{interp}), lns1{interp-RANS_fileIndx_start+1});
%     %Interp_curve_RANS = plot(test, Interp_RANSnew_y.(fn_UQSD7003_Mean{interp}), lns1{interp-RANS_fileIndx_start+1});
%     set ( Interp_curve_RANS,'visible',fit_visible,'HandleVisibility',fit_led_visible,'LineWidth',Linewidth,'MarkerSize',fit_MarkerSize,...
%         'DisplayName',fn_UQSD7003_Mean{interp});
% end
% hold off
%     
% set(gcf, 'Units', 'Inches', 'Position',  RANS_figure_size)
% 
% box on;
% PWC = gca;
% 
% l = legend;
% l.FontSize = Lsize;
% legend boxoff
% 
% %specify the range and name of coordinates
% PWC.FontSize = TLsize;
% 
% PWC.YLim = fit_ylimt ;
% PWC.XLim = fit_xlimt;
% 
% %Ticks on/off
% yticks(fit_ylimt(1,1):fit_y_Tick:fit_ylimt(1,2));
% xticks(fit_xlimt(1,1):fit_x_Tick:fit_xlimt(1,2));
% 
% %Minorticks on/off
% PWC.XAxis.MinorTick = fit_xMinorTick;
% PWC.XAxis.MinorTickValues = fit_xlimt(1,1):fit_x_MinorTick:fit_xlimt(1,2);
% PWC.YAxis.MinorTick = fit_yMinorTick;
% PWC.YAxis.MinorTickValues = fit_ylimt(1,1):fit_y_MinorTick:fit_ylimt(1,2);
% 
% %captions
% xlabel('$y/c$', 'FontSize', Csize,'interpreter','latex');
% ylabel('$k/<U>^2$', 'FontSize', Csize,'interpreter','latex');
% 
% %
% %%
% %**************** After got the averaged RANS 
% hold on
% plot(ave_y_RANS+0.14, Interp_x_RANS.(fn_UQSD7003_Mean{Interp_RANS_indx})+0.05,'gs-');
% hold off
% %%
% %*********************** Jul 6 2021 Interpolation for averaged Ref data *************************
% 
% lns1	 = {'-k';'-.r';'--b';'go-';'ko-';'ks-';'kx-';'kd-';'k^-'};
% % lns2	 = {'-r';'-.r';'--r';':r';'ro-';'rs-';'rx-';'rd-';'r^-'};
% % lns3	 = {'-g';'-.g';'--g';':g';'go-';'gs-';'gx-';'gd-';'g^-'};
% % lns4	 = {'-b';'-.b';'--b';':b';'bo-';'bs-';'bx-';'bd-';'b^-'};
% Ref_fileIndx_start = 7;
% num_Refsets_forAve = 5;%User needs to specify the number of sets for RANS data
% Ref_fileIndx_end = Ref_fileIndx_start + num_Refsets_forAve - 1;
% Ref_figure_size = [0, 0, 20, 20];
% 
% Ref_fit_ptsNum = zeros(num_Refsets_forAve,1);
% for interp = Ref_fileIndx_start:Ref_fileIndx_end%plus 1 because start at 2
%    
%     Interp_x_Ref.(fn_UQSD7003_Mean{interp})   = RefData.(fn_UQSD7003_Mean{interp}).norm_y_fitIndx;
%     Interp_y_Ref.(fn_UQSD7003_Mean{interp})   = RefData.(fn_UQSD7003_Mean{interp}).norm_Mean_fitIndx;
%     Ref_fit_ptsNum = structfun(@length,Interp_x_Ref);
%     
% end
% 
% 
% %get the index of the set of data that has the most number of points
% Ref_lmax = max(Ref_fit_ptsNum);
% Interp_Ref_indx = find(Ref_fit_ptsNum == Ref_lmax,1,'first') + Ref_fileIndx_start - 1;%-1 because inerp start counting at 2
% 
% 
% 
% 
% 
% %Interp_Ref_indx = find(fit_ptsNum,1,'first') + fileIndx_start - 1;
% 
% Interp_count = 0;
% for interp = Ref_fileIndx_start:Ref_fileIndx_end%plus 1 because start at 2
%    
%     if interp == Interp_Ref_indx
%         Info = ['Using interp == Interp_indx(',num2str(Interp_Ref_indx),') as the reference for interpolation; fn_UQSD7003_Mean{' ,num2str(interp),'} = ',fn_UQSD7003_Mean{interp}];
%         disp(Info)
%     end
%     
%     %Interp_Refnew_y.(fn_UQSD7003_Mean{interp}) = interp1(Interp_x_Ref.(fn_UQSD7003_Mean{interp}), Interp_y_Ref.(fn_UQSD7003_Mean{interp}), Interp_x_Ref.(fn_UQSD7003_Mean{Interp_Ref_indx}));
%     Interp_Refnew_y.(fn_UQSD7003_Mean{interp}) = interp1(Interp_x_Ref.(fn_UQSD7003_Mean{interp}), Interp_y_Ref.(fn_UQSD7003_Mean{interp}), test);
%     Ref_nan_index = find(isnan(Interp_Refnew_y.(fn_UQSD7003_Mean{interp})));%get indices of nan 
%     
%     if Interp_count == 0
%         sum_y = Interp_Refnew_y.(fn_UQSD7003_Mean{interp});
%       
%     elseif Interp_count > 0
%         sum_y = Interp_Refnew_y.(fn_UQSD7003_Mean{interp}) + sum_y;
%     end
%   
%     
%     Interp_count = Interp_count +1;
%     
% end
% 
% 
% for replace = 1:length(Ref_nan_index)%replace the corresponding indices of the Reference data (used to interpolate the rest) with nan
%    Interp_Refnew_y.(fn_UQSD7003_Mean{Interp_Ref_indx})(Ref_nan_index(replace)) = nan; 
% end
% %the following two lines of code will ensure same nontrivial length of data
% %when plotting
% 
% % Interp_Ref_firstIndx = find(Interp_y_Ref.(fn_UQSD7003_Mean{Interp_Ref_indx}),1,'first');%in this case first and last points are two extra data compared to the rest
% % Interp_Ref_lastIndx = find(Interp_y_Ref.(fn_UQSD7003_Mean{Interp_Ref_indx}),1,'last');
% % 
% % %Assign nan to it to keep consistent length with the rest
% % Interp_y_Ref.(fn_UQSD7003_Mean{Interp_Ref_indx})(Interp_Ref_firstIndx) = nan;
% % Interp_y_Ref.(fn_UQSD7003_Mean{Interp_Ref_indx})(Interp_Ref_lastIndx) = nan;
% 
% 
% 
% ave_y_Ref = sum_y/num_Refsets_forAve;
% 
% 
% fit_MarkerSize      = 10;
% %Ref_Marker          = '.';
% fit_visible         = 'on';
% fit_led_visible     = 'on';
% fit_xMinorTick      = 'on';
% fit_yMinorTick      = 'on';
% 
% fit_x_Tick          = 0.01;
% fit_x_MinorTick     = fit_x_Tick/5;
% 
% fit_y_Tick          = 0.04;
% fit_y_MinorTick     = fit_y_Tick/5;
% 
% fit_xlimt           = [0 0.03];
% fit_ylimt           = [-0.01 0.11];
% 
% 
% hold on
% %avey_curve_Ref = plot(Interp_x_Ref.(fn_UQSD7003_Mean{Interp_Ref_indx}),ave_y_Ref,'gs-');
% avey_curve_Ref = plot(test,ave_y_Ref,'gs-');
% 
% set (avey_curve_Ref,'visible',fit_visible,'HandleVisibility',fit_led_visible,'LineWidth',Linewidth,'MarkerSize',fit_MarkerSize,...
%     'DisplayName','Average data');
% 
% for interp = Ref_fileIndx_start:Ref_fileIndx_end
% 
%     %Interp_curve_Ref = plot(Interp_x_Ref.(fn_UQSD7003_Mean{Interp_Ref_indx}), Interp_Refnew_y.(fn_UQSD7003_Mean{interp}), lns1{interp-Ref_fileIndx_start+1});
%     Interp_curve_Ref = plot(test, Interp_Refnew_y.(fn_UQSD7003_Mean{interp}), lns1{interp-Ref_fileIndx_start+1});
%     
%     set ( Interp_curve_Ref,'visible',fit_visible,'HandleVisibility',fit_led_visible,'LineWidth',Linewidth,'MarkerSize',fit_MarkerSize,...
%         'DisplayName',fn_UQSD7003_Mean{interp});
% end
% hold off
%     
% set(gcf, 'Units', 'Inches', 'Position',  Ref_figure_size)
% 
% box on;
% PWC = gca;
% 
% l = legend;
% l.FontSize = Lsize;
% legend boxoff
% 
% %specify the range and name of coordinates
% PWC.FontSize = TLsize;
% 
% PWC.YLim = fit_ylimt ;
% PWC.XLim = fit_xlimt;
% 
% %Ticks on/off
% yticks(fit_ylimt(1,1):fit_y_Tick:fit_ylimt(1,2));
% xticks(fit_xlimt(1,1):fit_x_Tick:fit_xlimt(1,2));
% 
% %Minorticks on/off
% PWC.XAxis.MinorTick = fit_xMinorTick;
% PWC.XAxis.MinorTickValues = fit_xlimt(1,1):fit_x_MinorTick:fit_xlimt(1,2);
% PWC.YAxis.MinorTick = fit_yMinorTick;
% PWC.YAxis.MinorTickValues = fit_ylimt(1,1):fit_y_MinorTick:fit_ylimt(1,2);
% 
% %captions
% xlabel('$y/c$', 'FontSize', Csize,'interpreter','latex');
% ylabel('$k/<U>^2$', 'FontSize', Csize,'interpreter','latex');
% 
% %%
% %*********************** Jul 4 2021 Plot of interpolated data, error function and RANS *************************
% 
% % lns1	 = {'-k';'-.k';'--k';':k';'ko-';'ks-';'kx-';'kd-';'k^-'};
% % lns2	 = {'-r';'-.r';'--r';':r';'ro-';'rs-';'rx-';'rd-';'r^-'};
% % lns3	 = {'-g';'-.g';'--g';':g';'go-';'gs-';'gx-';'gd-';'g^-'};
% % lns4	 = {'-b';'-.b';'--b';':b';'bo-';'bs-';'bx-';'bd-';'b^-'};
% 
% 
% % Interp_Ref_x    = Interp_x_Ref.(fn_UQSD7003_Mean{Interp_Ref_indx});
% Interp_Ref_x    = test;
% Interp_Ref_y    = ave_y_Ref;
% 
% Interp_RANS_x   = test;
% %Interp_RANS_x   = Interp_x_RANS.(fn_UQSD7003_Mean{Interp_RANS_indx});
% Interp_RANS_y   = ave_y_RANS;
% All_figure_size = [0, 0, 20, 20];
% 
% % if length(Ref_fit_indx) > length(RANS_fit_indx)
% %     Info = ['You are fitting based on "Ref_fit_indx" using ',num2str(length(Ref_fit_indx)),' points'];
% %     disp(Info)
% %     Interp_new_y = interp1(Interp_RANS_x, Interp_RANS_y, Interp_Ref_x);
% %    
% %  
% % %     Interp_new_y_nan_indx = find(isnan(Interp_new_y));
% % %     for N = 1:length(find(isnan(Interp_new_y)))
% % %         disp(Interp_new_y_nan_indx(N))
% % %         Interp_new_y(Interp_new_y_nan_indx(N)) = [];
% % %         Interp_RANS_y(Interp_new_y_nan_indx(N)) = [];
% % %         Interp_RANS_x(Interp_new_y_nan_indx(N)) = [];
% % %     end
% %     
% %     %delta_new_y = Interp_RANS_y - Interp_new_y;
% %     delta_new_y = Interp_Ref_y - Interp_new_y;
% %     
% %     %f = fit(Interp_Ref_x, delta_new_y, 'poly3');
% %   
% %     
% %     fit_curve = plot(Interp_Ref_x, Interp_Ref_y,'.b',Interp_Ref_x, Interp_new_y,'-.r',Interp_Ref_x, delta_new_y,'--g');
% %     
% % elseif length(Ref_fit_indx) < length(RANS_fit_indx)
% %     Info = ['You are fitting based on "RANS_fit_indx" using ',num2str(length(Ref_fit_indx)),' points'];
% %     disp(Info)
%     Interp_new_y = interp1(Interp_Ref_x, Interp_Ref_y, Interp_RANS_x);
%     
%     new_y_nan_index = find(isnan(Interp_new_y));    
%     
% for replace = 1:length(new_y_nan_index)%replace the corresponding indices of the Reference data (used to interpolate the rest) with nan
%     Interp_RANS_y(new_y_nan_index(replace)) = nan; 
% end
% 
% 
%     %Interp_new_y = interp1(Interp_RANS_x, Interp_RANS_y, Interp_Ref_x);
%     
% %     Interp_new_y_nan_indx = find(isnan(Interp_new_y));
% %     for N = 1:length(find(isnan(Interp_new_y)))
% %         Interp_new_y(Interp_new_y_nan_indx(N)) = [];
% %         Interp_Ref_y(Interp_new_y_nan_indx(N)) = [];
% %         Interp_Ref_x(Interp_new_y_nan_indx(N)) = [];
% %     end
%     
%     %delta_new_y = Interp_RANS_y - Interp_new_y;
%     %delta_new_y = Interp_new_y - Interp_RANS_y;
%     delta_new_y = Interp_new_y./Interp_RANS_y;
%     %A second way of fitting - fit (probably to be used for my research)
%     
%     %f = fit(Interp_RANS_x, delta_new_y, 'poly3');
%     
%     fit_curve = plot(Interp_RANS_x, Interp_new_y,'.b',Interp_RANS_x, Interp_RANS_y,'-.r',Interp_RANS_x, delta_new_y,'--g');
% 
% % end
% 
% fit_MarkerSize      = 30;
% %Ref_Marker          = '.';
% fit_visible         = 'on';
% fit_led_visible     = 'on';
% fit_xMinorTick      = 'on';
% fit_yMinorTick      = 'on';
% 
% fit_x_Tick          = 0.004;
% fit_x_MinorTick     = fit_x_Tick/5;
% 
% fit_y_Tick          = 0.04;
% fit_y_MinorTick     = fit_y_Tick/5;
% 
% 
% fit_xlimt           = [0 0.03];
% fit_ylimt           = [-0.05 0.11];
% 
% % hold on
% % 
% % %fit_curve = plot(Interp_RANS_x, Interp_new_y,'.b',Interp_RANS_x, Interp_RANS_y,'-.r',Interp_RANS_x, delta_new_y,'--g');
% %  
% % hold off
% set(gcf, 'Units', 'Inches', 'Position',  All_figure_size)
% 
% box on;
% PWC = gca;
% 
% l = legend('DNS','RANS','Error');
% l.FontSize = Lsize;
% legend boxoff
% %specify the range and name of coordinates
% PWC.FontSize = TLsize;
% 
% PWC.YLim = fit_ylimt ;
% PWC.XLim = fit_xlimt;
% 
% %Ticks on/off
% yticks(fit_ylimt(1,1):fit_y_Tick:fit_ylimt(1,2));
% xticks(fit_xlimt(1,1):fit_x_Tick:fit_xlimt(1,2));
% 
% %Minorticks on/off
% PWC.XAxis.MinorTick = fit_xMinorTick;
% PWC.XAxis.MinorTickValues = fit_xlimt(1,1):fit_x_MinorTick:fit_xlimt(1,2);
% PWC.YAxis.MinorTick = fit_yMinorTick;
% PWC.YAxis.MinorTickValues = fit_ylimt(1,1):fit_y_MinorTick:fit_ylimt(1,2);
% 
% set ( fit_curve,'visible',fit_visible,'HandleVisibility',fit_led_visible,'LineWidth',Linewidth,'MarkerSize',fit_MarkerSize);
% %captions
% xlabel('$y/c$', 'FontSize', Csize,'interpreter','latex');
% ylabel('$k/<U>^2$', 'FontSize', Csize,'interpreter','latex');
% 
% 
% %%
% %*********************** Jun 29 2021 Interpolated data for determining the error function from Reference and RANS *************************
%  %Interp_Ref_x    = Interp_x_Ref.(fn_UQSD7003_Mean{Interp_Ref_indx});
% 
% Interp_Ref_x = test;
% %Interp_Ref_y    = ave_y_Ref;
% 
% Interp_RANS_x = test;
% % Interp_RANS_x   = Interp_x_RANS.(fn_UQSD7003_Mean{Interp_RANS_indx});
% Interp_RANS_y   = ave_y_RANS;
% Error_figure_size = [0, 0, 20, 20];
% 
% fit_poly        = 'poly4';
% fit_polyvar     = 4;
% 
% 
% % Info = ['You are fitting based on "RANS_fit_indx" using ',num2str(length(Ref_fit_indx)),' points'];
% % disp(Info)
% 
% 
% Interp_new_y_fit = interp1(Interp_Ref_x, Interp_Ref_y, Interp_RANS_x);
% 
% 
% delta_new_y_fit = Interp_RANS_y./Interp_new_y_fit;
% %delta_new_y_fit = Interp_new_y_fit./Interp_RANS_y;
% new_y_fit_nan_index = find(isnan(delta_new_y_fit)); %this line must be put here to work!
% delta_new_y_fit = delta_new_y_fit(~isnan(delta_new_y_fit));
% 
% 
%    
%     
% for replace = 1:length(new_y_fit_nan_index)%replace the corresponding indices of the Reference data (used to interpolate the rest) with nan
%     Interp_RANS_x(new_y_fit_nan_index(replace)) = nan;%we need replace nan correspondingly so that we can delete these extra rows of Interp_RANS_x to be in consistent with delta_new_y_fit
% end
% 
% Interp_RANS_x = Interp_RANS_x(~isnan(Interp_RANS_x));
% 
% %B = arrayfun(@(x) [], delta_new_y, 'UniformOutput', false);
% 
% % 
% % for test = 1:length(delta_new_y_fit)
% %     if isnan(delta_new_y_fit(test))
% %         delta_new_y_fit(test) = 0;%avoid Nan
% %         
% %     end
% % 
% % end
% %plot(Interp_RANS_x,delta_new_y_fit)
% %One way of fitting
% Error_fun.p = polyfit(Interp_RANS_x, delta_new_y_fit, fit_polyvar);
% Error_fun.y = polyval(Error_fun.p, Interp_RANS_x); 
% 
% %A second way of fitting - fit (probably to be used for my research)
% %f = fit(Interp_RANS_x, delta_new_y_fit, fit_poly);
% 
%   
%   
% 
% 
% 
% 
% fit_MarkerSize      = 10;
% %Ref_Marker          = '--';
% fit_visible         = 'on';
% fit_led_visible     = 'on';
% fit_xMinorTick      = 'on';
% fit_yMinorTick      = 'on';
% 
% fit_x_Tick          = 0.007;
% fit_x_MinorTick     = fit_x_Tick/5;
% 
% fit_y_Tick          = 0.5;
% fit_y_MinorTick     = fit_y_Tick/5;
% 
% 
% fit_xlimt           = [0 0.030];
% fit_ylimt           = [-0.5 5];
% 
% 
% hold on
% 
% %fit_curve     = plot(f, Interp_RANS_x, delta_new_y, Ref_Marker);
% 
% %fit_curve = plot(f, Interp_Ref_x, delta_new_y_fit, Ref_Marker);%one fit line + data being fitted
% 
% error_curve    = plot(Interp_RANS_x, delta_new_y_fit,'ks--');
% polyfit_curve  = plot(Interp_RANS_x, Error_fun.y,'r--');
% 
% 
%  
% hold off
% set(gcf, 'Units', 'Inches', 'Position',  Error_figure_size)
% 
% box on;
% PWC = gca;
% 
% l = legend('error','fitted curve');
% l.FontSize = Lsize;
% legend boxoff
% %specify the range and name of coordinates
% PWC.FontSize = TLsize;
% 
% PWC.YLim = fit_ylimt ;
% PWC.XLim = fit_xlimt;
% 
% %Ticks on/off
% yticks(fit_ylimt(1,1):fit_y_Tick:fit_ylimt(1,2));
% xticks(fit_xlimt(1,1):fit_x_Tick:fit_xlimt(1,2));
% 
% %Minorticks on/off
% PWC.XAxis.MinorTick = fit_xMinorTick;
% PWC.XAxis.MinorTickValues = fit_xlimt(1,1):fit_x_MinorTick:fit_xlimt(1,2);
% PWC.YAxis.MinorTick = fit_yMinorTick;
% PWC.YAxis.MinorTickValues = fit_ylimt(1,1):fit_y_MinorTick:fit_ylimt(1,2);
% 
% %set ( fit_curve,'visible',fit_visible,'HandleVisibility',fit_led_visible,'LineWidth',Linewidth,'MarkerSize',fit_MarkerSize);
% set ( polyfit_curve,'visible',fit_visible,'HandleVisibility',fit_led_visible,'LineWidth',Linewidth,'MarkerSize',fit_MarkerSize);
% set ( error_curve,'visible',fit_visible,'HandleVisibility',fit_led_visible,'LineWidth',Linewidth,'MarkerSize',fit_MarkerSize);
% %captions
% xlabel('$y/c$', 'FontSize', Csize,'interpreter','latex');
% ylabel('$k_{DNS}/k_{RANS}$', 'FontSize', Csize,'interpreter','latex');






%%
     function y=poly(x)
           y=-0.1091*(x).^4+0.2456*(x).^3-0.2196*(x).^2+...
               0.07873*(x)+0.004519;
%the following line reshapes the output in column vector form
           y=y(:);
     end 


     function k_u2 = poly7(y_c, n, varargin)
        %disp(varargin{1})
              k_u2 = varargin{1}.*(y_c).^(n) +...
                     varargin{2}.*(y_c).^(n-1) +...
                     varargin{3}.*(y_c).^(n-2) +...
                     varargin{4}.*(y_c).^(n-3) +...
                     varargin{5}.*(y_c).^(n-4) +...
                     varargin{6}.*(y_c).^(n-5) +...
                     varargin{7}.*(y_c).^(n-6) +...
                     varargin{8};
     end






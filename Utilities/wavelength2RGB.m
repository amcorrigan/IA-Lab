function rgb = wavelength2RGB(lambda)

% Convert the wavelength into an RGB colour
%
% The actual code for this comes from Academo.org
% https://academo.org/demos/wavelength-to-colour-relationship/
% 
% However, we may end up just assigning the colours that look best on the
% display for the commonly used channels
% 365
% 405
% 488
% 561
% 640



gammaval = 0.80;
if((lambda >= 330) && (lambda<440))
    red = -(lambda - 440) / (440 - 330);
    green = 0.0;
    blue = 1.0;
elseif((lambda >= 440) && (lambda<490))
    red = 0.0;
    green = (lambda - 440) / (490 - 440);
    blue = 1.0;
elseif((lambda >= 490) && (lambda<510))
    red = 0.0;
    green = 1.0;
    blue = -(lambda - 510) / (510 - 490);
elseif((lambda >= 510) && (lambda<580))
    red = (lambda - 510) / (580 - 510);
    green = 1.0;
    blue = 0.0;
elseif((lambda >= 580) && (lambda<645))
    red = 1.0;
    green = -(lambda - 645) / (645 - 580);
    blue = 0.0;
elseif((lambda >= 645) && (lambda<840))
    red = 1.0;
    green = 0.0;
    blue = 0.0;
else
    red = 0.0;
    green = 0.0;
    blue = 0.0;
end

% Let the intensity fall off near the vision limits
if((lambda >= 380) && (lambda<420))
    factor = 0.7 + 0.3*(lambda - 330) / (420 - 330);
% elseif((lambda >= 420) && (lambda<701))
%     factor = 1.0;
elseif((lambda >= 701) && (lambda<840))
    factor = 0.7 + 0.3*(840 - lambda) / (840 - 700);
else
    factor = 1.0;
end


rgb =  [(factor*red).^gammaval,(factor*green).^gammaval,(factor*blue).^gammaval];





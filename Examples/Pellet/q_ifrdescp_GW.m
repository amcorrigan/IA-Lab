function s = q_ifrdescp_GW(z, nd)

    np = length(z);
    % Check inputs.
    if nargin == 1 | nd > np 
       nd = np; 
    end

    % Create an alternating sequence of 1s and -1s for use in centering
    % the transform.
    x = 0:(np - 1);
    m = ((-1) .^ x)';

    % Use only nd descriptors in the inverse.  Since the 
    % descriptors are centered, (np - nd)/2 terms from each end of 
    % the sequence are set to 0.  
    d = round((np - nd)/2); % Round in case nd is odd.
    z(1:d) = 0;
    z(np - d + 1:np) = 0;
    % Compute the inverse and convert back to coordinates.
    zz = ifft(z);
    s(:, 1) = real(zz);
    s(:, 2) = imag(zz);
    % Multiply by alternating 1 and -1s to undo the earlier 
    % centering.
    s(:, 1) = m.*s(:, 1);
    s(:, 2) = m.*s(:, 2);

function B = q_bound2im_GW(b, M, N, x0, y0)


    [np, nc] = size(b);
    if np < nc
       b = b'; % To convert to size np-by-2.
       [np, nc] = size(b);
    end

    % Make sure the coordinates are integers.
    x = round(b(:, 1)); 
    y = round(b(:, 2));

    % Set up the default size parameters. 
    x = x - min(x) + 1;
    y = y - min(y) + 1;
    B = false(max(x), max(y));
    C = max(x) - min(x) + 1;
    D = max(y) - min(y) + 1;

    if nargin == 1  
       % Use the preceding default values.
    elseif nargin == 3
       if C > M | D > N
          error('The boundary is outside the M-by-N region.')
       end
       % The image size will be M-by-N. Set up the parameters for this.
       B = false(M, N);
       % Distribute extra rows approx. even between top and bottom.
       NR = round((M - C)/2); 
       NC = round((N - D)/2); % The same for columns.
       x = x + NR; % Offset the boundary to new position.
       y = y + NC;  
    elseif nargin == 5
       if x0 < 0 | y0 < 0
          error('x0 and y0 must be positive integers.')
       end
       x = x + round(x0) - 1;
       y = y + round(y0) - 1;
       C = C + x0 - 1;
       D = D + y0 - 1;
       if C > M | D > N
          error('The shifted boundary is outside the M-by-N region.')
       end
       B = false(M, N);
    else
       error('Incorrect number of inputs.') 
    end

    B(sub2ind(size(B), x, y)) = true;

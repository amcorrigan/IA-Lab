function C = amcCat(dim,padval,varargin)

% like cat but allows the arrays to be different sizes
% when they are different sizes they are padded with the value specified

% in the case of more than two arrays, call recursively?

% in order to be concatenated, the arrays must be the same size in all
% dimensions except that being concatenated along.

usedim = dim;

siz = cell(numel(varargin),1);
for ii = 1:numel(varargin)
    siz{ii} = size(varargin{ii});
    usedim = max(usedim,numel(siz{ii}));
end

fsiz = ones(numel(varargin),usedim);
for ii = 1:numel(varargin)
    fsiz(ii,1:numel(siz{ii})) = siz{ii};
end
maxsiz = max(fsiz,[],1);


psiz = zeros(numel(varargin),usedim);
for ii = 1:numel(varargin)
    psiz(ii,:) = maxsiz - fsiz(ii,:);
end
psiz(:,dim) = 0;

useR = cell(numel(varargin),1);
for ii = 1:numel(varargin)
    if ~isempty(varargin{ii}) % cat already handles empty arrays
        if ~isstruct(padval)
            useR{ii} = padarray(varargin{ii},psiz(ii,:),padval,'post');
        else
            % have to do it manually for struct arrays
            insiz = ones(1,size(psiz,2));
            temp = size(varargin{ii});
            
            insiz(1:numel(temp)) = temp;
            permord = circshift(1:size(psiz,2),-1,2);
            
            useR{ii} = varargin{ii};
            for jj = 1:size(psiz,2)
                useR{jj}(insiz(jj)+(1:psiz(jj)),:) = padval;
                useR{jj} = permute(useR{jj},permord);
            end
            
        end
    else
        useR{ii} = varargin{ii};
    end
end

C = cat(dim,useR{:});


% FAT_CONTOUR draw a easily visible contour
function [h1 h2] = fat_contour(phi,dashed,c1)
%Coded by: Shawn Lankton
%Function:  Display a contour
  c2 = 'k';
  if(~exist('c1','var')) c1 = 'r'; end
  if(~exist('dashed','var')) dashed = false; end
  
  t1 = 4;
  t2 = 2;

  hold on;
  if(dashed)
    h1 = contour(phi,[0 0],c1,'linewidth',t1,'linestyle','--');  
    h2 = contour(phi,[0 0],c2,'linewidth',t2,'linestyle','--');
  else
    h1 = contour(phi,[0 0],c1,'linewidth',t1);  
    h2 = contour(phi,[0 0],c2,'linewidth',t2);
  end
  hold off;
end


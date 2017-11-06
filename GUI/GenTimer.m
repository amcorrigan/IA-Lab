classdef GenTimer < handle
    % General timer, which will take a AmcProgBar (or same interface)
    % object
    properties (Hidden)
        tich = [];
    end
    properties
        progObj % object for representing progress
        
        prog = 0;
        timedata
        avframes = 10;
        numFrames = NaN;
        framesLeft = NaN;
        timerem = NaN;
        
        showbar = true
        
        msg
    end
    methods
        function TB = GenTimer(msg,nframes,hide,progobj)
            % need to have a way of initializing without starting running
            if nargin<3 || isempty(hide)
                hide = 0;
            end
            if nargin<1 || isempty(msg)
                msg = '';
            end
            
            TB.showbar = hide==0;
            
            TB.msg = msg;
            
            if nargin>3 && isa(progobj,'AmcProgBar')
                TB.progObj = progobj;
            end
            
            % if we've supplied the number of frames then start running
            if nargin>1 && ~isempty(nframes)
                TB.start(nframes)
            end
        end
        function start(TB,nframes)
            % start the first timer running
            if nargin>1
                TB.numFrames = nframes;
                TB.framesLeft = nframes;
                TB.timerem = NaN;
                TB.prog = 0;
            end
            TB.tich = tic;
            
            % change the waitbar message to show it's running.
            
            TB.update_()
            
            
            
        end
        function update_(TB)
            fullmsg = timeremmsg(TB.timerem);
            if ~isempty(TB.msg)
                fullmsg = [TB.msg,': ',fullmsg];
            end
                
            if TB.showbar
                if ~isa(TB.progObj,'AmcProgBar')
                    TB.progObj = AmcProgMsgBar(fullmsg,TB.prog);
                else
                    TB.progObj.updateMsg(fullmsg);
                    TB.progObj.updateProg(TB.prog);
                end
            else
                if isa(TB.progObj,'AmcProgBar')
                    TB.progObj.hide();
                end
            end
            drawnow(); % will this slow this down unnecessarily?
        end
        function setav(TB,avframes)
            TB.avframes = avframes;
        end
        function updatemsg(TB,msg)
            if nargin>1 && ~isempty(msg)
                TB.msg = msg;
            end
            
            TB.update_()
            
        end
        function increment(TB,step,nframes)
            % update the timerbar by step units
            
            % allow the total number of frames to be specified now at the
            % latest
            if nargin>2 && ~isempty(nframes)
                % allow a change in nframes to be reflected in the time
                % remaining
                prevframes = TB.numFrames;
                
                TB.numFrames = nframes;
                
                if isnan(prevframes)
                    TB.framesLeft = nframes;
                else
                    % change framesleft by the same amount as nframes has
                    % changed
                    TB.framesLeft = TB.framesLeft + (nframes-prevframes);
                end
            end
            if isnan(TB.numFrames)
                % don't render anything on the bar till we know..
                return
            end
            
            if nargin<2 || isempty(step)
                step = 1;
            end
            
            TB.framesLeft = TB.framesLeft - step;
            
            if TB.framesLeft>0
                if ~isempty(TB.tich)
                    tempt = toc(TB.tich);
                    TB.tich = tic;

                    TB.timedata = [TB.timedata, ones(1,step)*tempt/step];
                    TB.timedata = TB.timedata(max(1,end-TB.avframes+1):end);

                    spf = median(TB.timedata);
                    TB.timerem = TB.framesLeft*spf;
                else
                    TB.tich = tic;
                    TB.timerem = NaN;
                end
                TB.prog = 1 - TB.framesLeft/TB.numFrames;
                
                
                TB.update_()
            else
                TB.prog = 1;
                TB.timerem = 0;
                
                TB.update_()
            end
            
        end
        
        function finish(TB)
            if ~isempty(TB.progObj)
                finish(TB.progObj)
            end
        end
        
        function progObj = getProgObj(this)
            progObj = this.progObj;
        end
        
        % need to decide how best to implement these
        % either hide the figure and keep updating it, or delete the figure
        % and then recreate it when necessary - this is the best option,
        % since the hidden part is likely to never be displayed
        
        function hidebar(TB)
            TB.showbar = false;
            
            if ishandle(TB.progObj)
                hide(TB.progObj);
            end
        end
        
        function unhidebar(TB)
            TB.showbar = true;
            if ishandle(TB.progObj)
                unhide(TB.progObj);
            end
            TB.update_()
        end
    end
    
end

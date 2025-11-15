function tank_wall_editor
    % Visual Wall Editor for Tank Game
    % Click and drag to draw walls, then copy the MATLAB code
    
    fig = uifigure('Name','Tank Game Wall Editor','Position',[200 100 900 700], ...
        'Color',[0.08 0.09 0.12]);
    
    gridSize = 20;
    walls = [];  % Store walls as [x1 y1 x2 y2]
    
    % Drawing state
    isDrawing = false;
    currentWall = [];
    tempLine = [];
    
    % UI Components
    ax = uiaxes(fig,'Position',[50 150 600 500]);
    axis(ax,[0.5 gridSize+0.5 0.5 gridSize+0.5]);
    axis(ax,'square');
    grid(ax,'on');
    set(ax,'XTick',1:gridSize,'YTick',1:gridSize);
    ax.BackgroundColor = [0.1 0.1 0.1];
    ax.GridColor = [0.3 0.3 0.3];
    ax.GridAlpha = 0.3;
    hold(ax,'on');
    title(ax,'Click and drag to draw walls','FontSize',14,'Color',[1 1 1]);
    
    % Wall plots storage
    wallLines = [];
    
    % Instructions
    uilabel(fig,'Text','WALL EDITOR','FontSize',24,'FontWeight','bold', ...
        'FontColor',[0.95 0.95 0.95],'Position',[670 620 200 40], ...
        'HorizontalAlignment','center');
    
    uilabel(fig,'Text','Instructions:','FontSize',14,'FontWeight','bold', ...
        'FontColor',[0.8 0.8 0.8],'Position',[670 560 200 30]);
    
    instructions = {
        '1. Click and drag to draw walls'
        '2. Click "Copy Code" button'
        '3. Paste into your tank game'
        ''
        'Tips:'
        '• Snap to grid enabled'
        '• Use Clear All to start over'
        '• Use Undo to remove last wall'
    };
    
    uilabel(fig,'Text',strjoin(instructions,newline),'FontSize',11, ...
        'FontColor',[0.7 0.7 0.7],'Position',[670 380 210 180], ...
        'VerticalAlignment','top');
    
    % Buttons
    copyBtn = uibutton(fig,'Text','Copy Code','FontSize',14,'FontWeight','bold', ...
        'BackgroundColor',[0.2 0.7 0.3],'FontColor',[1 1 1], ...
        'Position',[670 320 200 45],'ButtonPushedFcn',@copyCode);
    
    clearBtn = uibutton(fig,'Text','Clear All','FontSize',14,'FontWeight','bold', ...
        'BackgroundColor',[0.8 0.3 0.2],'FontColor',[1 1 1], ...
        'Position',[670 260 200 45],'ButtonPushedFcn',@clearAll);
    
    undoBtn = uibutton(fig,'Text','Undo Last','FontSize',14,'FontWeight','bold', ...
        'BackgroundColor',[0.5 0.5 0.5],'FontColor',[1 1 1], ...
        'Position',[670 200 200 45],'ButtonPushedFcn',@undoLast);
    
    % Wall count label
    countLabel = uilabel(fig,'Text','Walls: 0','FontSize',12,'FontWeight','bold', ...
        'FontColor',[0.9 0.9 0.9],'Position',[670 150 200 30], ...
        'HorizontalAlignment','center');
    
    % Output text area
    uilabel(fig,'Text','Generated Code:','FontSize',12,'FontWeight','bold', ...
        'FontColor',[0.8 0.8 0.8],'Position',[50 90 200 30]);
    
    outputText = uitextarea(fig,'Position',[50 20 820 65], ...
        'BackgroundColor',[0.15 0.15 0.15],'FontColor',[0.3 1 0.3], ...
        'FontName','Courier New','FontSize',10,'Editable','off');
    
    % Mouse callbacks
    ax.ButtonDownFcn = @startDrawing;
    fig.WindowButtonMotionFcn = @onMouseMove;
    fig.WindowButtonUpFcn = @stopDrawing;
    
    updateOutput();
    
    function startDrawing(~, event)
        if ~strcmp(event.Button, 'normal')
            return;
        end
        
        pt = event.IntersectionPoint;
        x = round(pt(1));
        y = round(pt(2));
        
        % Clamp to grid
        x = max(1, min(gridSize, x));
        y = max(1, min(gridSize, y));
        
        isDrawing = true;
        currentWall = [x y x y];
        
        % Create temporary line
        tempLine = line(ax,[x x],[y y],'LineWidth',8,'Color',[1 1 0], ...
            'LineStyle','--');
    end
    
    function onMouseMove(~, ~)
        if ~isDrawing || isempty(tempLine) || ~isvalid(tempLine)
            return;
        end
        
        % Get mouse position relative to axes
        pt = get(ax, 'CurrentPoint');
        x = round(pt(1,1));
        y = round(pt(1,2));
        
        % Clamp to grid
        x = max(1, min(gridSize, x));
        y = max(1, min(gridSize, y));
        
        % Update temporary line
        currentWall(3:4) = [x y];
        set(tempLine,'XData',[currentWall(1) currentWall(3)], ...
            'YData',[currentWall(2) currentWall(4)]);
    end
    
    function stopDrawing(~, ~)
        if ~isDrawing
            return;
        end
        
        isDrawing = false;
        
        % Only add wall if it has length
        if norm(currentWall(1:2) - currentWall(3:4)) > 0.5
            walls(end+1,:) = currentWall;
            
            % Replace temp line with permanent wall
            if isvalid(tempLine)
                delete(tempLine);
            end
            
            wallLines(end+1) = line(ax,[currentWall(1) currentWall(3)], ...
                [currentWall(2) currentWall(4)],'LineWidth',8,'Color',[0.4 0.4 0.4]);
            
            updateOutput();
        else
            % Remove temp line if wall too short
            if isvalid(tempLine)
                delete(tempLine);
            end
        end
        
        tempLine = [];
        currentWall = [];
    end
    
    function clearAll(~, ~)
        walls = [];
        
        % Delete all wall lines
        for i = 1:length(wallLines)
            if isvalid(wallLines(i))
                delete(wallLines(i));
            end
        end
        wallLines = [];
        
        % Delete temp line if exists
        if ~isempty(tempLine) && isvalid(tempLine)
            delete(tempLine);
        end
        
        isDrawing = false;
        currentWall = [];
        tempLine = [];
        
        updateOutput();
    end
    
    function undoLast(~, ~)
        if isempty(walls)
            return;
        end
        
        % Remove last wall
        walls(end,:) = [];
        
        % Delete last wall line
        if ~isempty(wallLines) && isvalid(wallLines(end))
            delete(wallLines(end));
        end
        wallLines(end) = [];
        
        updateOutput();
    end
    
    function copyCode(~, ~)
        if isempty(walls)
            uialert(fig,'No walls to copy! Draw some walls first.','No Walls','Icon','warning');
            return;
        end
        
        % Copy to clipboard
        clipboard('copy', outputText.Value);
        
        % Visual feedback
        originalColor = copyBtn.BackgroundColor;
        copyBtn.Text = 'Copied!';
        copyBtn.BackgroundColor = [0.1 0.9 0.2];
        pause(0.5);
        copyBtn.Text = 'Copy Code';
        copyBtn.BackgroundColor = originalColor;
    end
    
    function updateOutput()
        countLabel.Text = sprintf('Walls: %d', size(walls,1));
        
        if isempty(walls)
            outputText.Value = 'walls = [];  % No walls defined yet';
            return;
        end
        
        % Generate MATLAB code
        code = 'walls = [';
        for i = 1:size(walls,1)
            if i > 1
                code = [code sprintf('\n    ')];
            else
                code = [code newline '    '];
            end
            code = [code sprintf('%d %d %d %d;', walls(i,1), walls(i,2), walls(i,3), walls(i,4))];
        end
        code = [code newline '];'];
        
        outputText.Value = code;
    end
end
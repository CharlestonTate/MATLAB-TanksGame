function main_menu
    fig = uifigure('Name','Tank Game','Position',[500 300 600 400],'Color',[0.08 0.09 0.12]);

    uilabel(fig,'Text','TANK GAME','FontSize',28,'FontWeight','bold','FontColor',[0.95 0.95 0.95], ...
        'HorizontalAlignment','center','Position',[0 280 600 80]);

    uilabel(fig,'Text','MAIN MENU','FontSize',16,'FontColor',[0.7 0.7 0.7], ...
        'HorizontalAlignment','center','Position',[0 245 600 40]);

    baseColor  = [0.20 0.45 0.80];
    hoverColor = [0.35 0.70 1.00];

    startBtn = uibutton(fig,'Text','START','FontSize',18,'FontWeight','bold','BackgroundColor',baseColor, ...
        'FontColor',[1 1 1],'Position',[220 190 160 55],'ButtonPushedFcn',@(btn,event) startGame(fig));

    quitBtn = uibutton(fig,'Text','QUIT','FontSize',18,'FontWeight','bold','BackgroundColor',baseColor, ...
        'FontColor',[1 1 1],'Position',[220 110 160 55],'ButtonPushedFcn',@(btn,event) close(fig));

    data.buttons    = [startBtn, quitBtn];
    data.baseColor  = baseColor;
    data.hoverColor = hoverColor;
    fig.UserData    = data;

    for k = 1:2
        t = timer('ExecutionMode','fixedRate','Period',0.015,'TasksToExecute',12, ...
            'TimerFcn',@(src,ev) animateButton(src,k,fig));
        data = fig.UserData;
        data.timers(k) = t;
        fig.UserData = data;
    end

    data = fig.UserData;
    data.targetColor = [baseColor; baseColor];
    fig.UserData = data;

    fig.WindowButtonMotionFcn = @onMouseMove;
end

function startGame(fig)
    data = fig.UserData;
    if isfield(data,'timers')
        for k = 1:numel(data.timers)
            try
                stop(data.timers(k));
                delete(data.timers(k));
            end
        end
    end
    fig.WindowButtonMotionFcn = [];
    delete(fig.Children);
    tank_game_smooth(fig);
end

function onMouseMove(fig, ~)
    data = fig.UserData;
    btns = data.buttons;
    mousePos = fig.CurrentPoint;

    for k = 1:numel(btns)
        pos = btns(k).Position;

        inside = mousePos(1) >= pos(1) && mousePos(1) <= pos(1)+pos(3) && ...
                 mousePos(2) >= pos(2) && mousePos(2) <= pos(2)+pos(4);

        if inside
            data.targetColor(k,:) = data.hoverColor;
        else
            data.targetColor(k,:) = data.baseColor;
        end

        try
            stop(data.timers(k));
            start(data.timers(k));
        end
    end

    fig.UserData = data;
end

function animateButton(~, index, fig)
    data = fig.UserData;
    btn = data.buttons(index);
    current = btn.BackgroundColor;
    target  = data.targetColor(index,:);
    newColor = current + 0.20 * (target - current);
    btn.BackgroundColor = newColor;
end

function tank_game_smooth(fig)
    gridSize = 20;
    tankPos = [10 10];
    tankDir = [1 0];
    tankVel = [0 0];
    tankAccel = 0.040;
    tankMaxSpeed = 1.50;
    tankFriction = 0.85;

    bulletActive = false;
    bulletPos = [0 0];
    bulletDir = [0 0];
    bulletSpeed = 0.25;
    bulletBounces = 0;
    maxBounces = 1;

    targets = [5 5; 15 15; 5 15; 15 5];
    score = 0;

    keys.up = false;
    keys.down = false;
    keys.left = false;
    keys.right = false;
    keys.shoot = false;

    ax = uiaxes(fig,'Position',[50 40 500 320]);
    axis(ax,[0.5 gridSize+0.5 0.5 gridSize+0.5]);
    axis(ax,'square');
    set(ax,'XTick',[],'YTick',[]);
    ax.BackgroundColor = [0.1 0.1 0.1];
    hold(ax,'on');

    if ~isempty(targets)
        targetsPlot = plot(ax,targets(:,1),targets(:,2),'ks','MarkerFaceColor','k','MarkerSize',14);
    else
        targetsPlot = plot(ax,nan,nan,'ks','MarkerFaceColor','k','MarkerSize',14);
    end

    tankBody = rectangle(ax,'Position',[tankPos(1)-0.4,tankPos(2)-0.4,0.8,0.8], ...
        'FaceColor','g','EdgeColor','k');
    tankBarrel = line(ax,[tankPos(1), tankPos(1)+0.7*tankDir(1)], ...
        [tankPos(2), tankPos(2)+0.7*tankDir(2)],'LineWidth',3,'Color','k');
    bulletPlot = plot(ax,nan,nan,'ro','MarkerFaceColor','r','MarkerSize',8);

    fig.KeyPressFcn = @onKeyDown;
    fig.KeyReleaseFcn = @onKeyUp;
    fig.Name = 'MATLAB Tanks Smooth';

    while isvalid(fig)
        moveDir = [0 0];
        if keys.up,    moveDir(2) = moveDir(2) + 1; end
        if keys.down,  moveDir(2) = moveDir(2) - 1; end
        if keys.right, moveDir(1) = moveDir(1) + 1; end
        if keys.left,  moveDir(1) = moveDir(1) - 1; end

        if any(moveDir)
            n = norm(moveDir);
            moveDir = moveDir / n;
            tankVel = tankVel + tankAccel * moveDir;
            tankDir = moveDir;
        end

        tankVel = tankVel * tankFriction;

        speed = norm(tankVel);
        if speed > tankMaxSpeed
            tankVel = tankVel * (tankMaxSpeed / speed);
        end

        tankPos = tankPos + tankVel;
        tankPos(1) = min(max(tankPos(1),1),gridSize);
        tankPos(2) = min(max(tankPos(2),1),gridSize);

        if keys.shoot && ~bulletActive
            bulletActive = true;
            bulletPos = tankPos;
            bulletDir = tankDir;
            bulletBounces = 0;
        end

        if bulletActive
            newBulletPos = bulletPos + bulletSpeed * bulletDir;
            bounced = false;

            if newBulletPos(1) < 0.5 || newBulletPos(1) > gridSize+0.5
                bulletDir(1) = -bulletDir(1);
                newBulletPos(1) = max(0.5, min(gridSize+0.5, newBulletPos(1)));
                bounced = true;
            end

            if newBulletPos(2) < 0.5 || newBulletPos(2) > gridSize+0.5
                bulletDir(2) = -bulletDir(2);
                newBulletPos(2) = max(0.5, min(gridSize+0.5, newBulletPos(2)));
                bounced = true;
            end

            if bounced
                bulletBounces = bulletBounces + 1;
                if bulletBounces > maxBounces
                    bulletActive = false;
                end
            end

            bulletPos = newBulletPos;

            if ~isempty(targets)
                hitIndex = 0;
                for i = 1:size(targets,1)
                    dist = norm(bulletPos - targets(i,:));
                    if dist < 0.6
                        hitIndex = i;
                        break;
                    end
                end
                if hitIndex > 0
                    targets(hitIndex,:) = [];
                    bulletActive = false;
                    score = score + 1;
                    if isempty(targets)
                        set(targetsPlot,'XData',nan,'YData',nan);
                    else
                        set(targetsPlot,'XData',targets(:,1),'YData',targets(:,2));
                    end
                end
            end
        end

        tankBody.Position = [tankPos(1)-0.4,tankPos(2)-0.4,0.8,0.8];
        tankBarrel.XData = [tankPos(1), tankPos(1)+0.7*tankDir(1)];
        tankBarrel.YData = [tankPos(2), tankPos(2)+0.7*tankDir(2)];

        if bulletActive
            set(bulletPlot,'XData',bulletPos(1),'YData',bulletPos(2));
        else
            set(bulletPlot,'XData',nan,'YData',nan);
        end

        title(ax,sprintf('Score: %d | Bounces: %d/%d', score, bulletBounces, maxBounces+1));
        drawnow limitrate
        pause(0.02);
    end

    function onKeyDown(~,event)
        switch event.Key
            case 'uparrow'
                keys.up = true;
            case 'downarrow'
                keys.down = false;
                keys.down = true;
            case 'leftarrow'
                keys.left = true;
            case 'rightarrow'
                keys.right = true;
            case 'space'
                keys.shoot = true;
        end
    end

    function onKeyUp(~,event)
        switch event.Key
            case 'uparrow'
                keys.up = false;
            case 'downarrow'
                keys.down = false;
            case 'leftarrow'
                keys.left = false;
            case 'rightarrow'
                keys.right = false;
            case 'space'
                keys.shoot = false;
        end
    end
end

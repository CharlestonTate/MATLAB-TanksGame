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
    tankHealth = 100;

    bulletActive = false;
    bulletPos = [0 0];
    bulletDir = [0 0];
    bulletSpeed = 0.25;
    bulletBounces = 0;
    maxBounces = 1;

    % Enemy AI
    numEnemies = 1;
    enemies = struct('pos',{},'dir',{},'vel',{},'health',{},'shootTimer',{},'body',{},'barrel',{});
    for i = 1:numEnemies
        enemies(i).pos = [rand()*gridSize, rand()*gridSize];
        enemies(i).dir = [rand()-0.5, rand()-0.5];
        enemies(i).dir = enemies(i).dir / norm(enemies(i).dir);
        enemies(i).vel = [0 0];
        enemies(i).health = 10;
        enemies(i).shootTimer = rand()*100;
    end
    
    enemyBullets = struct('pos',{},'dir',{},'active',{});

    targets = [5 5; 15 15; 5 15; 15 5];
    score = 0;

    keys.up = false;
    keys.down = false;
    keys.left = false;
    keys.right = false;
    keys.shoot = false;

    % HUD panels
    hudPanel = uipanel(fig,'Position',[50 360 500 30],'BackgroundColor',[0.15 0.15 0.15]);
    healthLabel = uilabel(hudPanel,'Text',sprintf('HP: %d', tankHealth),'Position',[10 5 100 20],...
        'FontSize',12,'FontWeight','bold','FontColor',[0.2 1.0 0.2]);
    scoreLabel = uilabel(hudPanel,'Text',sprintf('Score: %d', score),'Position',[200 5 100 20],...
        'FontSize',12,'FontWeight','bold','FontColor',[1.0 0.8 0.2]);
    enemyLabel = uilabel(hudPanel,'Text',sprintf('Enemies: %d', numEnemies),'Position',[380 5 100 20],...
        'FontSize',12,'FontWeight','bold','FontColor',[1.0 0.3 0.3]);

    ax = uiaxes(fig,'Position',[50 40 500 310]);
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

    % Create enemy graphics
    for i = 1:numEnemies
        enemies(i).body = rectangle(ax,'Position',[enemies(i).pos(1)-0.4,enemies(i).pos(2)-0.4,0.8,0.8], ...
            'FaceColor','r','EdgeColor','k');
        enemies(i).barrel = line(ax,[enemies(i).pos(1), enemies(i).pos(1)+0.7*enemies(i).dir(1)], ...
            [enemies(i).pos(2), enemies(i).pos(2)+0.7*enemies(i).dir(2)],'LineWidth',3,'Color','k');
    end
    
    enemyBulletPlot = plot(ax,nan,nan,'mo','MarkerFaceColor','m','MarkerSize',6);

    fig.KeyPressFcn = @onKeyDown;
    fig.KeyReleaseFcn = @onKeyUp;
    fig.Name = 'MATLAB Tanks with AI';

    gameOver = false;
    
    while isvalid(fig) && ~gameOver
        % Player movement (unchanged)
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

        % Player shooting
        if keys.shoot && ~bulletActive
            bulletActive = true;
            bulletPos = tankPos;
            bulletDir = tankDir;
            bulletBounces = 0;
        end

        % Player bullet update
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

            % Check hits on targets
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
            
            % Check hits on enemies
            for i = numel(enemies):-1:1
                dist = norm(bulletPos - enemies(i).pos);
                if dist < 0.6
                    enemies(i).health = enemies(i).health - 25;
                    bulletActive = false;
                    if enemies(i).health <= 0
                        delete(enemies(i).body);
                        delete(enemies(i).barrel);
                        enemies(i) = [];
                        score = score + 10;
                    end
                    break;
                end
            end
        end

        % Enemy AI
        for i = 1:numel(enemies)
            toPlayer = tankPos - enemies(i).pos;
            dist = norm(toPlayer);
            
            % Tactical AI behavior
            optimalDist = 6 + rand()*2; % Maintain distance
            
            if dist < 3
                % Too close - retreat while aiming
                enemies(i).dir = -toPlayer / dist;
                moveSpeed = 0.03;
            elseif dist > optimalDist
                % Too far - advance while aiming
                enemies(i).dir = toPlayer / dist;
                moveSpeed = 0.025;
            else
                % Optimal range - strafe
                perpDir = [-toPlayer(2), toPlayer(1)] / dist;
                if mod(floor(enemies(i).shootTimer/50), 2) == 0
                    perpDir = -perpDir;
                end
                enemies(i).dir = perpDir * 0.7 + toPlayer/dist * 0.3;
                enemies(i).dir = enemies(i).dir / norm(enemies(i).dir);
                moveSpeed = 0.02;
            end
            
            % Avoid walls
            wallAvoid = [0 0];
            if enemies(i).pos(1) < 3, wallAvoid(1) = 0.05; end
            if enemies(i).pos(1) > gridSize-3, wallAvoid(1) = -0.05; end
            if enemies(i).pos(2) < 3, wallAvoid(2) = 0.05; end
            if enemies(i).pos(2) > gridSize-3, wallAvoid(2) = -0.05; end
            
            % Avoid other enemies
            for j = 1:numel(enemies)
                if i ~= j
                    toEnemy = enemies(i).pos - enemies(j).pos;
                    enemyDist = norm(toEnemy);
                    if enemyDist < 2.5
                        wallAvoid = wallAvoid + toEnemy/enemyDist * 0.04;
                    end
                end
            end
            
            % Apply movement
            moveDir = enemies(i).dir + wallAvoid;
            if norm(moveDir) > 0.01
                moveDir = moveDir / norm(moveDir);
            end
            
            enemies(i).vel = enemies(i).vel * 0.88 + moveDir * moveSpeed;
            enemies(i).pos = enemies(i).pos + enemies(i).vel;
            enemies(i).pos(1) = min(max(enemies(i).pos(1),1),gridSize);
            enemies(i).pos(2) = min(max(enemies(i).pos(2),1),gridSize);
            
            % Aim barrel at player
            aimDir = toPlayer / dist;
            enemies(i).dir = aimDir;
            
            % Smart shooting - lead the target
            predictedPos = tankPos + tankVel * 8;
            leadDir = predictedPos - enemies(i).pos;
            leadDir = leadDir / norm(leadDir);
            
            enemies(i).shootTimer = enemies(i).shootTimer + 1;
            if enemies(i).shootTimer > 80 && dist < 12 && dist > 2.5
                enemies(i).shootTimer = rand()*20; % Random offset
                newBullet.pos = enemies(i).pos;
                newBullet.dir = leadDir;
                newBullet.active = true;
                enemyBullets(end+1) = newBullet;
            end
            
            % Update graphics
            enemies(i).body.Position = [enemies(i).pos(1)-0.4,enemies(i).pos(2)-0.4,0.8,0.8];
            enemies(i).barrel.XData = [enemies(i).pos(1), enemies(i).pos(1)+0.7*enemies(i).dir(1)];
            enemies(i).barrel.YData = [enemies(i).pos(2), enemies(i).pos(2)+0.7*enemies(i).dir(2)];
        end
        
        % Update enemy bullets
        for i = numel(enemyBullets):-1:1
            if enemyBullets(i).active
                enemyBullets(i).pos = enemyBullets(i).pos + 0.15 * enemyBullets(i).dir;
                
                % Check bounds
                if enemyBullets(i).pos(1) < 0.5 || enemyBullets(i).pos(1) > gridSize+0.5 || ...
                   enemyBullets(i).pos(2) < 0.5 || enemyBullets(i).pos(2) > gridSize+0.5
                    enemyBullets(i) = [];
                    continue;
                end
                
                % Check hit on player
                if norm(enemyBullets(i).pos - tankPos) < 0.6
                    tankHealth = tankHealth - 10;
                    enemyBullets(i) = [];
                    if tankHealth <= 0
                        gameOver = true;
                    end
                end
            end
        end

        % Update graphics
        tankBody.Position = [tankPos(1)-0.4,tankPos(2)-0.4,0.8,0.8];
        tankBarrel.XData = [tankPos(1), tankPos(1)+0.7*tankDir(1)];
        tankBarrel.YData = [tankPos(2), tankPos(2)+0.7*tankDir(2)];

        if bulletActive
            set(bulletPlot,'XData',bulletPos(1),'YData',bulletPos(2));
        else
            set(bulletPlot,'XData',nan,'YData',nan);
        end
        
        % Update enemy bullets plot
        if ~isempty(enemyBullets)
            ebx = arrayfun(@(b) b.pos(1), enemyBullets);
            eby = arrayfun(@(b) b.pos(2), enemyBullets);
            set(enemyBulletPlot,'XData',ebx,'YData',eby);
        else
            set(enemyBulletPlot,'XData',nan,'YData',nan);
        end
        
        % Update HUD
        healthLabel.Text = sprintf('HP: %d', tankHealth);
        if tankHealth < 30
            healthLabel.FontColor = [1.0 0.2 0.2];
        end
        scoreLabel.Text = sprintf('Score: %d', score);
        enemyLabel.Text = sprintf('Enemies: %d', numel(enemies));

        drawnow limitrate
        pause(0.02);
    end
    
    if gameOver
        text(ax, gridSize/2, gridSize/2, 'GAME OVER', 'FontSize', 24, 'Color', 'r', ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        pause(3);
    end

    function onKeyDown(~,event)
        switch event.Key
            case 'uparrow'
                keys.up = true;
            case 'downarrow'
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
